// s-spec: A minimal Lisp interpreter
// Lexer, Parser, and Interpreter in one file

import { readFileSync, realpathSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join, resolve } from "path";

// Unique Symbol to tag AST nodes and distinguish them from user objects
const AST_NODE = Symbol("ast-node");

// Synthetic position for runtime-generated AST nodes (not from source code)
const SYNTHETIC_POS: Position = { line: 0, col: 0 };

type Token = {
  type: string;
  value: string | number | boolean | null;
  line: number;
  col: number;
};

// Source position for error reporting
type Position = { line: number; col: number };

// AST nodes tagged with Symbol to prevent user object conflicts
type NumberNode = {
  [AST_NODE]: true;
  type: "number";
  value: number;
  pos: Position;
};
type StringNode = {
  [AST_NODE]: true;
  type: "string";
  value: string;
  pos: Position;
};
type BooleanNode = {
  [AST_NODE]: true;
  type: "boolean";
  value: boolean;
  pos: Position;
};
type NullNode = { [AST_NODE]: true; type: "null"; pos: Position };
type SymbolNode = {
  [AST_NODE]: true;
  type: "symbol";
  sym: string;
  pos: Position;
};
type KeywordNode = {
  [AST_NODE]: true;
  type: "keyword";
  kw: string;
  pos: Position;
};
type ConsNode = {
  [AST_NODE]: true;
  type: "cons";
  car: Value;
  cdr: Value | null;
  pos: Position;
};
type ArrayNode = {
  [AST_NODE]: true;
  type: "array";
  arr: Expr[];
  pos: Position;
};
type ObjectNode = {
  [AST_NODE]: true;
  type: "object";
  obj: Array<[Expr, Expr]>;
  pos: Position;
};
type CallNode = {
  [AST_NODE]: true;
  type: "call";
  op: Expr;
  args: Expr[];
  pos: Position;
};

type Expr =
  | NumberNode
  | StringNode
  | BooleanNode
  | NullNode
  | SymbolNode
  | KeywordNode
  | ConsNode
  | ArrayNode
  | ObjectNode
  | CallNode;

// Runtime-valid expressions (excludes CallNode and SymbolNode)
type DataExpr =
  | NumberNode
  | StringNode
  | BooleanNode
  | NullNode
  | KeywordNode
  | ConsNode
  | ArrayNode
  | ObjectNode;

// Callable interface for uniform function invocation
interface Callable {
  call(args: Value[], env: Environment): Value;
}

// Wrapper for builtin (native) functions
class BuiltinFunction implements Callable {
  private fn: (args: Value[], env: Environment) => Value;

  constructor(fn: (args: Value[], env: Environment) => Value) {
    this.fn = fn;
  }

  call(args: Value[], env: Environment): Value {
    return this.fn(args, env);
  }
}

type Params = {
  required: string[];
  rest: string | null;
};

// ObjectValue interface allows circular reference to Value
interface ObjectValue {
  [key: string]: Value;
}

// Permissive to support macros manipulating unevaluated AST; runtime validation in builtins
type Value =
  | number
  | string
  | boolean
  | null
  | undefined
  | BuiltinFunction
  | UserFunction
  | Macro
  | Expr // Includes all AST nodes for macro expansion
  | ObjectValue;

// Marker for unquote-splicing results
type SplicingMarker = { __splice: true; items: Expr[] };

class SSpecError extends Error {
  line?: number;
  col?: number;

  constructor(msg: string, pos?: Position) {
    super(pos !== undefined ? `${msg} at ${pos.line}:${pos.col}` : msg);
    this.line = pos?.line;
    this.col = pos?.col;
  }
}

// RecursionTracker is shared across all environments to properly track depth
interface RecursionTracker {
  depth: number;
  maxDepth: number;
}

// GensymTracker is shared across all environments to generate unique symbols
interface GensymTracker {
  counter: number;
}

class Environment {
  private bindings = new Map<string, Value>();
  private parent?: Environment;
  public currentFile: string | null = null;
  public loadedFiles: Set<string> = new Set();

  // Recursion depth tracking - shared object reference across all environments
  private recursionTracker: RecursionTracker;

  // Gensym counter - shared object reference across all environments
  private gensymTracker: GensymTracker;

  constructor(parent?: Environment) {
    this.parent = parent;
    if (parent) {
      this.currentFile = parent.currentFile;
      this.loadedFiles = parent.loadedFiles;
      this.recursionTracker = parent.recursionTracker;
      this.gensymTracker = parent.gensymTracker;
    } else {
      this.recursionTracker = { depth: 0, maxDepth: 1000 };
      this.gensymTracker = { counter: 0 };
    }
  }

  setMaxRecursionDepth(limit: number): void {
    if (limit < 1) {
      throw new SSpecError("Maximum recursion depth must be at least 1");
    }
    this.recursionTracker.maxDepth = limit;
  }

  enterRecursion(pos?: Position): void {
    this.recursionTracker.depth++;
    if (this.recursionTracker.depth > this.recursionTracker.maxDepth) {
      throw new SSpecError(
        `Maximum recursion depth (${this.recursionTracker.maxDepth}) exceeded. ` +
          `This may indicate infinite recursion or very deep nesting.`,
        pos
      );
    }
  }

  exitRecursion(): void {
    this.recursionTracker.depth--;
  }

  get(name: string, pos?: Position): Value {
    if (this.bindings.has(name)) {
      return this.bindings.get(name)!;
    }
    if (this.parent) {
      return this.parent.get(name, pos);
    }
    throw new SSpecError(`Undefined variable: ${name}`, pos);
  }

  has(name: string): boolean {
    return this.bindings.has(name) || (this.parent?.has(name) ?? false);
  }

  set(name: string, value: Value): void {
    this.bindings.set(name, value);
  }

  gensym(prefix?: string): SymbolNode {
    const defaultPrefix = "G__";
    const actualPrefix = prefix || defaultPrefix;
    const id = this.gensymTracker.counter++;
    return ast.symbol(`${actualPrefix}${id}`, SYNTHETIC_POS);
  }

  // Get the root environment (for global operations like load)
  root(): Environment {
    let current: Environment = this;
    while (current.parent) {
      current = current.parent;
    }
    return current;
  }
}

class UserFunction {
  params: Params;
  body: Expr;
  closure: Environment;

  constructor(params: Params, body: Expr, closure: Environment) {
    this.params = params;
    this.body = body;
    this.closure = closure;
  }

  call(args: Value[], env: Environment): Value {
    const minArgs = this.params.required.length;

    if (this.params.rest === null) {
      // Fixed arity: must match exactly
      if (args.length !== minArgs) {
        throw new SSpecError(
          `Expected ${minArgs} args, got ${args.length}`,
          this.body.pos
        );
      }
    } else {
      // Variadic: must have at least required args
      if (args.length < minArgs) {
        throw new SSpecError(
          `Expected at least ${minArgs} args, got ${args.length}`,
          this.body.pos
        );
      }
    }

    const funcEnv = new Environment(this.closure);

    for (let i = 0; i < this.params.required.length; i++) {
      funcEnv.set(this.params.required[i], args[i]);
    }

    if (this.params.rest !== null) {
      const restArgs = args.slice(this.params.required.length);
      const listExpr = arrayToConsList(restArgs);
      funcEnv.set(this.params.rest, listExpr);
    }

    // Track recursion depth for function calls
    funcEnv.enterRecursion(this.body.pos);
    try {
      return evalExpr(this.body, funcEnv);
    } finally {
      funcEnv.exitRecursion();
    }
  }
}

class Macro {
  params: Params;
  body: Expr;
  closure: Environment;

  constructor(params: Params, body: Expr, closure: Environment) {
    this.params = params;
    this.body = body;
    this.closure = closure;
  }

  expand(args: Expr[], env: Environment): Expr {
    const minArgs = this.params.required.length;

    if (this.params.rest === null) {
      // Fixed arity: must match exactly
      if (args.length !== minArgs) {
        throw new SSpecError(
          `Macro expected ${minArgs} args, got ${args.length}`,
          this.body.pos
        );
      }
    } else {
      // Variadic: must have at least required args
      if (args.length < minArgs) {
        throw new SSpecError(
          `Macro expected at least ${minArgs} args, got ${args.length}`,
          this.body.pos
        );
      }
    }

    // Create macro environment - bind UNEVALUATED args to parameters
    const macroEnv = new Environment(this.closure);

    for (let i = 0; i < this.params.required.length; i++) {
      // Store AST node directly as a value (Expr is part of Value type)
      const arg: Value = args[i];
      macroEnv.set(this.params.required[i], arg);
    }

    // Bind rest parameter if present (unevaluated AST nodes)
    if (this.params.rest !== null) {
      const restArgs = args.slice(this.params.required.length);
      // Convert rest args to a cons cell list of AST nodes
      const listExpr = arrayToConsList(restArgs);
      macroEnv.set(this.params.rest, listExpr);
    }

    // Track recursion depth for macro expansion
    macroEnv.enterRecursion(this.body.pos);
    try {
      const result = evalExpr(this.body, macroEnv);
      // Convert primitive return values back to AST nodes
      return valueToExpr(result);
    } finally {
      macroEnv.exitRecursion();
    }
  }
}

// Helper: Convert runtime values back to AST nodes (for macro returns)
function valueToExpr(value: Value): Expr {
  if (isNumber(value)) {
    return ast.number(value, SYNTHETIC_POS);
  }
  if (isString(value)) {
    return ast.string(value, SYNTHETIC_POS);
  }
  if (isBoolean(value)) {
    return ast.boolean(value, SYNTHETIC_POS);
  }
  if (isNil(value)) {
    return ast.null(SYNTHETIC_POS);
  }
  // Already an Expr node or complex value - return as-is
  return value as Expr;
}

// LEXER
function lex(input: string): Token[] {
  const tokens: Token[] = [];
  let i = 0,
    line = 1,
    col = 1;

  const advance = () => {
    if (input[i] === "\n") {
      line++;
      col = 1;
    } else {
      col++;
    }
    i++;
  };

  while (i < input.length) {
    if (/\s/.test(input[i])) {
      advance();
      continue;
    }

    if (input[i] === ",") {
      advance();
      continue;
    }

    if (input[i] === ";") {
      while (i < input.length && input[i] !== "\n") advance();
      continue;
    }

    const start = { line, col };

    if (input[i] === "(") {
      tokens.push({ type: "(", value: "(", ...start });
      advance();
      continue;
    }
    if (input[i] === ")") {
      tokens.push({ type: ")", value: ")", ...start });
      advance();
      continue;
    }
    if (input[i] === "[") {
      tokens.push({ type: "[", value: "[", ...start });
      advance();
      continue;
    }
    if (input[i] === "]") {
      tokens.push({ type: "]", value: "]", ...start });
      advance();
      continue;
    }
    if (input[i] === "{") {
      tokens.push({ type: "{", value: "{", ...start });
      advance();
      continue;
    }
    if (input[i] === "}") {
      tokens.push({ type: "}", value: "}", ...start });
      advance();
      continue;
    }

    if (input[i] === '"') {
      advance();
      let str = "";
      while (i < input.length && input[i] !== '"') {
        if (input[i] === "\\") {
          advance();
          str += input[i] || "";
        } else str += input[i];
        advance();
      }
      if (input[i] !== '"') throw new SSpecError("Unterminated string", start);
      advance();
      tokens.push({ type: "str", value: str, ...start });
      continue;
    }

    if (
      /[\d-]/.test(input[i]) &&
      (input[i] !== "-" || /\d/.test(input[i + 1]))
    ) {
      let num = "";
      if (input[i] === "-") {
        num += input[i];
        advance();
      }
      while (i < input.length && /[\d.]/.test(input[i])) {
        num += input[i];
        advance();
      }
      tokens.push({ type: "num", value: parseFloat(num), ...start });
      continue;
    }

    if (input[i] === ":") {
      advance();
      let kw = "";
      if (i < input.length && input[i] === '"') {
        advance();
        while (i < input.length && input[i] !== '"') {
          if (input[i] === "\\") {
            advance();
            kw += input[i] || "";
          } else kw += input[i];
          advance();
        }
        if (input[i] !== '"')
          throw new SSpecError("Unterminated keyword string", start);
        advance();
      } else if (/[a-zA-Z+\-*/<>=!?_]/.test(input[i])) {
        while (i < input.length && /[a-zA-Z0-9+\-*/<>=!?_]/.test(input[i])) {
          kw += input[i];
          advance();
        }
      } else {
        throw new SSpecError("Invalid keyword syntax", start);
      }
      tokens.push({ type: "keyword", value: kw, ...start });
      continue;
    }

    if (/[a-zA-Z+\-*/<>=!?_&]/.test(input[i])) {
      let sym = "";
      while (i < input.length && /[a-zA-Z0-9+\-*/<>=!?_&]/.test(input[i])) {
        sym += input[i];
        advance();
      }
      if (sym === "true") {
        tokens.push({ type: "bool", value: true, ...start });
        continue;
      }
      if (sym === "false") {
        tokens.push({ type: "bool", value: false, ...start });
        continue;
      }
      if (sym === "null") {
        tokens.push({ type: "null", value: null, ...start });
        continue;
      }
      tokens.push({ type: "sym", value: sym, ...start });
      continue;
    }

    throw new SSpecError(`Unexpected char: ${input[i]}`, { line, col });
  }

  return tokens;
}

// PARSER
function parse(tokens: Token[]): Expr[] {
  let i = 0;

  const parseExpr = (): Expr => {
    const t = tokens[i++];
    if (!t) throw new SSpecError("Unexpected end");
    const pos: Position = { line: t.line, col: t.col };

    if (t.type === "num") return ast.number(t.value as number, pos);
    if (t.type === "str") return ast.string(t.value as string, pos);
    if (t.type === "bool") return ast.boolean(t.value as boolean, pos);
    if (t.type === "null") return ast.null(pos);
    if (t.type === "keyword") return ast.keyword(t.value as string, pos);
    if (t.type === "sym") return ast.symbol(t.value as string, pos);
    if (t.type === ")")
      throw new SSpecError("Unexpected )", { line: t.line, col: t.col });
    if (t.type === "]")
      throw new SSpecError("Unexpected ]", { line: t.line, col: t.col });
    if (t.type === "}")
      throw new SSpecError("Unexpected }", { line: t.line, col: t.col });

    if (t.type === "[") {
      const elements: Expr[] = [];
      while (tokens[i] && tokens[i].type !== "]") {
        elements.push(parseExpr());
      }
      if (!tokens[i] || tokens[i].type !== "]") {
        throw new SSpecError("Expected ]", { line: t.line, col: t.col });
      }
      i++;
      return ast.array(elements, pos);
    }

    if (t.type === "(") {
      if (!tokens[i] || tokens[i].type === ")")
        throw new SSpecError("Empty expr", { line: t.line, col: t.col });
      const op = parseExpr();
      const args: Expr[] = [];
      while (tokens[i] && tokens[i].type !== ")") args.push(parseExpr());
      if (!tokens[i] || tokens[i].type !== ")")
        throw new SSpecError("Expected )", { line: t.line, col: t.col });
      i++;
      return ast.call(op, args, pos);
    }

    if (t.type === "{") {
      const pairs: Array<[Expr, Expr]> = [];
      while (tokens[i] && tokens[i].type !== "}") {
        const key = parseExpr();
        if (!tokens[i] || tokens[i].type === "}") {
          throw new SSpecError(
            "Object literal requires even number of elements",
            { line: t.line, col: t.col }
          );
        }
        const value = parseExpr();
        pairs.push([key, value]);
      }
      if (!tokens[i] || tokens[i].type !== "}")
        throw new SSpecError("Expected }", { line: t.line, col: t.col });
      i++;
      return ast.object(pairs, pos);
    }

    throw new SSpecError(`Unknown token: ${t.type}`, {
      line: t.line,
      col: t.col,
    });
  };

  const exprs: Expr[] = [];
  while (i < tokens.length) exprs.push(parseExpr());
  return exprs;
}

// INTERPRETER

// ============================================================================
// TYPE GUARDS
// Centralized type guards for all Value types
// ============================================================================

// Primitive type guards
const isNumber = (v: Value): v is number => typeof v === "number";
const isString = (v: Value): v is string => typeof v === "string";
const isBoolean = (v: Value): v is boolean => typeof v === "boolean";
const isNull = (v: Value): v is null => v === null;
const isNil = (v: Value): v is null => v === null || v === undefined;

// Function/callable type guards
const isBuiltinFunction = (v: Value): v is BuiltinFunction =>
  v instanceof BuiltinFunction;
const isUserFunction = (v: Value): v is UserFunction =>
  v instanceof UserFunction;
const isMacro = (v: Value): v is Macro => v instanceof Macro;
const isCallable = (v: Value): v is BuiltinFunction | UserFunction =>
  isBuiltinFunction(v) || isUserFunction(v);
const isFunction = (v: Value): v is BuiltinFunction | UserFunction =>
  isCallable(v);

// AST node type guards (Expr types)
// Use Symbol-based tagging to definitively identify AST nodes
const isExpr = (v: Value): v is Expr =>
  typeof v === "object" && v !== null && AST_NODE in v;

const isNumberNode = (v: Value): v is NumberNode =>
  isExpr(v) && v.type === "number";
const isStringNode = (v: Value): v is StringNode =>
  isExpr(v) && v.type === "string";
const isBooleanNode = (v: Value): v is BooleanNode =>
  isExpr(v) && v.type === "boolean";
const isNullNode = (v: Value): v is NullNode => isExpr(v) && v.type === "null";
const isSymbol = (v: Value): v is SymbolNode =>
  isExpr(v) && v.type === "symbol";
const isKeyword = (v: Value): v is KeywordNode =>
  isExpr(v) && v.type === "keyword";
const isCons = (v: Value): v is ConsNode => isExpr(v) && v.type === "cons";
const isArray = (v: Value): v is ArrayNode => isExpr(v) && v.type === "array";
const isObjectNode = (v: Value): v is ObjectNode =>
  isExpr(v) && v.type === "object";
const isCallNode = (v: Value): v is CallNode => isExpr(v) && v.type === "call";

// Plain object (evaluated object literal, not AST node or function)
const isPlainObject = (v: Value): v is ObjectValue => {
  // Must be a non-null object
  if (v === null || typeof v !== "object") return false;
  // Exclude function instances
  if (
    v instanceof BuiltinFunction ||
    v instanceof UserFunction ||
    v instanceof Macro
  )
    return false;
  // Exclude AST nodes - they are tagged with the AST_NODE Symbol
  // This is definitive - user objects can never have this Symbol
  if (AST_NODE in v) return false;
  // It's a plain object (evaluated map literal)
  // User can have :type, :pos, or any other keys without conflict
  return true;
};

// Utility type guards
const isTruthy = (v: Value): boolean =>
  v !== null && v !== undefined && v !== false;

// Helper: Get human-readable type name for error messages
function getValueTypeName(v: Value): string {
  if (isNumber(v)) return "number";
  if (isString(v)) return "string";
  if (isBoolean(v)) return "boolean";
  if (isNil(v)) return "null";
  if (isNumberNode(v)) return "number-node";
  if (isStringNode(v)) return "string-node";
  if (isBooleanNode(v)) return "boolean-node";
  if (isNullNode(v)) return "null-node";
  if (isKeyword(v)) return "keyword";
  if (isSymbol(v)) return "symbol";
  if (isCons(v)) return "cons";
  if (isArray(v)) return "array";
  if (isObjectNode(v)) return "object-node";
  if (isCallNode(v)) return "call-node";
  if (isUserFunction(v)) return "user-function";
  if (isMacro(v)) return "macro";
  if (isBuiltinFunction(v)) return "builtin-function";
  if (isPlainObject(v)) return "object";
  return typeof v;
}

// AST node factory with consistent Symbol tagging
const ast = {
  number: (value: number, pos: Position): NumberNode => ({
    [AST_NODE]: true,
    type: "number",
    value,
    pos,
  }),

  string: (value: string, pos: Position): StringNode => ({
    [AST_NODE]: true,
    type: "string",
    value,
    pos,
  }),

  boolean: (value: boolean, pos: Position): BooleanNode => ({
    [AST_NODE]: true,
    type: "boolean",
    value,
    pos,
  }),

  null: (pos: Position): NullNode => ({ [AST_NODE]: true, type: "null", pos }),

  symbol: (sym: string, pos: Position): SymbolNode => ({
    [AST_NODE]: true,
    type: "symbol",
    sym,
    pos,
  }),

  keyword: (kw: string, pos: Position): KeywordNode => ({
    [AST_NODE]: true,
    type: "keyword",
    kw,
    pos,
  }),

  cons: (car: Value, cdr: Value | null, pos: Position): ConsNode => ({
    [AST_NODE]: true,
    type: "cons",
    car,
    cdr,
    pos,
  }),

  array: (arr: Expr[], pos: Position): ArrayNode => ({
    [AST_NODE]: true,
    type: "array",
    arr,
    pos,
  }),

  object: (obj: Array<[Expr, Expr]>, pos: Position): ObjectNode => ({
    [AST_NODE]: true,
    type: "object",
    obj,
    pos,
  }),

  call: (op: Expr, args: Expr[], pos: Position): CallNode => ({
    [AST_NODE]: true,
    type: "call",
    op,
    args,
    pos,
  }),
};

const arrayToConsList = (arr: Value[]): ConsNode | null => {
  let result: ConsNode | null = null;
  for (let i = arr.length - 1; i >= 0; i--) {
    result = ast.cons(arr[i], result, SYNTHETIC_POS);
  }
  return result;
};

const consListToArray = (list: Value): Value[] => {
  const result: Value[] = [];
  let current: Value | null = list;
  while (isCons(current)) {
    result.push(current.car);
    current = current.cdr;
  }
  if (current !== null) {
    throw new SSpecError("Improper list");
  }
  return result;
};

function toSExpr(expr: Expr | Value): string {
  if (expr == null) {
    return "null";
  }

  // Handle primitives (for backward compatibility with runtime values)
  if (typeof expr === "number") {
    return String(expr);
  }
  if (typeof expr === "string") {
    const escaped = expr.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
    return `"${escaped}"`;
  }
  if (typeof expr === "boolean") {
    return expr ? "true" : "false";
  }

  // Handle typed AST nodes
  if (typeof expr === "object" && "type" in expr) {
    switch (expr.type) {
      case "number":
        return String(expr.value);
      case "string":
        const escaped = expr.value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
        return `"${escaped}"`;
      case "boolean":
        return expr.value ? "true" : "false";
      case "null":
        return "null";
      case "symbol":
        return expr.sym;
      case "keyword":
        const kw = expr.kw;
        if (/^[a-zA-Z][a-zA-Z0-9\-]*$/.test(kw)) {
          return `:${kw}`;
        } else {
          const escapedKw = kw.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
          return `:"${escapedKw}"`;
        }
      case "cons":
        // Check if it's a proper list (terminates in null)
        let current: Expr | null = expr;
        const elements: string[] = [];
        while (isCons(current)) {
          elements.push(toSExpr(current.car));
          current = current.cdr as Expr | null;
        }
        if (current == null) {
          return `(${elements.join(" ")})`;
        } else {
          return `(${elements.join(" ")} . ${toSExpr(current)})`;
        }
      case "array":
        const arrElements = expr.arr.map((e) => toSExpr(e));
        return `[${arrElements.join(" ")}]`;
      case "object":
        const pairs = expr.obj.map(([key, value]) => {
          return `${toSExpr(key)} ${toSExpr(value)}`;
        });
        return `{${pairs.join(" ")}}`;
      case "call":
        const op = toSExpr(expr.op);
        const args = expr.args.map((a) => toSExpr(a));
        return `(${op}${args.length > 0 ? " " + args.join(" ") : ""})`;
    }
  }

  // Handle plain objects (evaluated ObjectValue) - runtime values
  if (typeof expr === "object" && !("type" in expr)) {
    const pairs: string[] = [];
    for (const [key, value] of Object.entries(expr)) {
      pairs.push(`:${key} ${toSExpr(value)}`);
    }
    return `{${pairs.join(" ")}}`;
  }

  // Fallback for unknown types
  return String(expr);
}

const arrayToParams = (arr: ArrayNode): Params => {
  const required: string[] = [];
  let rest: string | null = null;
  let sawRest = false;

  for (let i = 0; i < arr.arr.length; i++) {
    const elem = arr.arr[i];
    if (!isSymbol(elem)) {
      throw new SSpecError("Parameter must be a symbol", elem.pos);
    }

    if (elem.sym === "&rest") {
      if (sawRest) {
        throw new SSpecError("Only one &rest allowed in parameter list", elem.pos);
      }
      sawRest = true;
      i++;

      if (i >= arr.arr.length) {
        throw new SSpecError("Expected parameter name after &rest", elem.pos);
      }
      const restParam = arr.arr[i];
      if (!isSymbol(restParam)) {
        throw new SSpecError(
          "Expected parameter name after &rest",
          restParam.pos
        );
      }
      if (restParam.sym === "&rest") {
        throw new SSpecError(
          "&rest cannot be used as parameter name",
          restParam.pos
        );
      }
      rest = restParam.sym;

      if (i + 1 < arr.arr.length) {
        throw new SSpecError(
          "No parameters allowed after &rest parameter",
          restParam.pos
        );
      }
    } else {
      if (sawRest) {
        throw new SSpecError(
          "No parameters allowed after &rest parameter",
          elem.pos
        );
      }
      required.push(elem.sym);
    }
  }

  return { required, rest };
};

// Helper: Binary numeric operation with validation
function binaryNumericOp<T>(
  name: string,
  args: Value[],
  operation: (a: number, b: number) => T
): T {
  if (args.length !== 2) {
    throw new SSpecError(`${name} requires exactly 2 arguments`);
  }
  if (!isNumber(args[0])) {
    throw new SSpecError(
      `${name} requires number for argument 1, got ${getValueTypeName(args[0])}`
    );
  }
  if (!isNumber(args[1])) {
    throw new SSpecError(
      `${name} requires number for argument 2, got ${getValueTypeName(args[1])}`
    );
  }
  return operation(args[0], args[1]);
}

const builtins: Record<string, BuiltinFunction> = {
  add: new BuiltinFunction((args, env) =>
    binaryNumericOp("add", args, (a, b) => a + b)
  ),
  sub: new BuiltinFunction((args, env) =>
    binaryNumericOp("sub", args, (a, b) => a - b)
  ),
  mul: new BuiltinFunction((args, env) =>
    binaryNumericOp("mul", args, (a, b) => a * b)
  ),
  div: new BuiltinFunction((args, env) =>
    binaryNumericOp("div", args, (a, b) => {
      if (b === 0) throw new SSpecError("Division by zero");
      return a / b;
    })
  ),
  and: new BuiltinFunction((args, env) => {
    for (const arg of args) {
      if (!isTruthy(arg)) return arg;
    }
    return args[args.length - 1] ?? true;
  }),
  or: new BuiltinFunction((args, env) => {
    for (const arg of args) {
      if (isTruthy(arg)) return arg;
    }
    return args[args.length - 1] ?? null;
  }),
  gt: new BuiltinFunction((args, env) =>
    binaryNumericOp("gt", args, (a, b) => a > b)
  ),
  lt: new BuiltinFunction((args, env) =>
    binaryNumericOp("lt", args, (a, b) => a < b)
  ),
  gte: new BuiltinFunction((args, env) =>
    binaryNumericOp("gte", args, (a, b) => a >= b)
  ),
  lte: new BuiltinFunction((args, env) =>
    binaryNumericOp("lte", args, (a, b) => a <= b)
  ),
  log: new BuiltinFunction((args, env) => {
    console.log(...args);
    return null;
  }),
  str: new BuiltinFunction((args, env) => {
    // String concatenation: (str "hello" " " "world") => "hello world"
    return args
      .map((arg) => {
        if (isString(arg)) return arg;
        if (isNumber(arg)) return String(arg);
        if (isBoolean(arg)) return String(arg);
        if (isNull(arg)) return "null";
        if (isKeyword(arg)) return `:${arg.kw}`;
        if (isSymbol(arg)) return arg.sym;
        return String(arg);
      })
      .join("");
  }),
  list: new BuiltinFunction((args, env) => arrayToConsList(args)),
  cons: new BuiltinFunction((args, env) => {
    if (args.length !== 2) throw new SSpecError("cons requires 2 arguments");
    return ast.cons(args[0], args[1], SYNTHETIC_POS);
  }),
  car: new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("car requires 1 argument");
    const cell = args[0];
    if (cell === null || cell === undefined) return null;
    if (isCons(cell)) {
      return cell.car;
    }
    throw new SSpecError("car requires a cons cell");
  }),
  cdr: new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("cdr requires 1 argument");
    const cell = args[0];
    if (cell === null || cell === undefined) return null;
    if (isCons(cell)) {
      return cell.cdr;
    }
    throw new SSpecError("cdr requires a cons cell");
  }),
  // Array operations
  array: new BuiltinFunction((args, env) => {
    return ast.array(
      args.map((v) => valueToExpr(v)),
      SYNTHETIC_POS
    );
  }),
  "array?": new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("array? requires 1 argument");
    const val = args[0];
    return isArray(val);
  }),
  "symbol?": new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("symbol? requires 1 argument");
    const val = args[0];
    return isSymbol(val);
  }),
  "null?": new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("null? requires 1 argument");
    return isNil(args[0]);
  }),
  "number?": new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("number? requires 1 argument");
    return isNumber(args[0]);
  }),
  "string?": new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("string? requires 1 argument");
    return isString(args[0]);
  }),
  "boolean?": new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("boolean? requires 1 argument");
    return isBoolean(args[0]);
  }),
  "keyword?": new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("keyword? requires 1 argument");
    return isKeyword(args[0]);
  }),
  "object?": new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("object? requires 1 argument");
    return isPlainObject(args[0]);
  }),
  nth: new BuiltinFunction((args, env) => {
    if (args.length !== 2) throw new SSpecError("nth requires 2 arguments");
    const arr = args[0];
    const index = args[1];
    if (!isArray(arr)) {
      throw new SSpecError("nth requires an array as first argument");
    }
    if (!isNumber(index)) {
      throw new SSpecError(
        `nth requires number for argument 2, got ${getValueTypeName(index)}`
      );
    }
    if (index < 0 || index >= arr.arr.length) {
      return null; // Return null for out of bounds (like Clojure)
    }
    const element = arr.arr[index];
    // If element is a literal Expr node, extract its value
    if (isNumberNode(element)) return element.value;
    if (isStringNode(element)) return element.value;
    if (isBooleanNode(element)) return element.value;
    if (isNullNode(element)) return null;
    return element;
  }),
  length: new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("length requires 1 argument");
    const val = args[0];
    if (val === null || val === undefined) return 0;
    if (isArray(val)) {
      return val.arr.length;
    }
    // Length works on cons cell lists too
    if (isCons(val)) {
      let count = 0;
      let current: ConsNode | null = val;
      while (isCons(current)) {
        count++;
        current = current.cdr as ConsNode | null;
      }
      return count;
    }
    throw new SSpecError("length requires an array or list");
  }),
  push: new BuiltinFunction((args, env) => {
    if (args.length !== 2) throw new SSpecError("push requires 2 arguments");
    const arr = args[0];
    const item = args[1];
    if (!isArray(arr)) {
      throw new SSpecError("push requires an array as first argument");
    }
    // Convert item to Expr if it's a primitive value
    const itemExpr = valueToExpr(item);
    return ast.array([...arr.arr, itemExpr], SYNTHETIC_POS);
  }),
  // Object operations
  keys: new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("keys requires 1 argument");
    const obj = args[0];
    if (!isPlainObject(obj)) {
      throw new SSpecError("keys requires an object");
    }
    const keyStrings = Object.keys(obj);
    return arrayToConsList(keyStrings);
  }),
  get: new BuiltinFunction((args, env) => {
    if (args.length < 2 || args.length > 3) {
      throw new SSpecError("get requires 2 or 3 arguments");
    }
    const obj = args[0];
    const key = args[1];
    const defaultValue = args.length === 3 ? args[2] : null;

    if (!isPlainObject(obj)) {
      throw new SSpecError("get requires an object as first argument");
    }

    let keyStr: string;
    if (isString(key)) {
      keyStr = key;
    } else if (isKeyword(key)) {
      keyStr = key.kw;
    } else {
      throw new SSpecError("get key must be a string or keyword");
    }

    // Type guard ensures obj is ObjectValue here
    const objValue: ObjectValue = obj;
    const result = objValue[keyStr];
    return result !== undefined ? result : defaultValue;
  }),
  // Regex operations (i-regexp - RFC 9485 portable regex subset)
  re: new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("re requires 1 argument");
    const pattern = args[0];
    if (!isString(pattern)) {
      throw new SSpecError(
        `re requires string for argument 1, got ${getValueTypeName(pattern)}`
      );
    }
    try {
      // Note: JavaScript RegExp is a superset of i-regexp
      // Users should restrict themselves to i-regexp subset for portability
      const regex = new RegExp(pattern);
      // Return a function that tests strings against the regex
      return new BuiltinFunction((testArgs: Value[], testEnv: Environment) => {
        if (testArgs.length !== 1)
          throw new SSpecError("regex matcher requires 1 argument");
        const value = testArgs[0];
        if (!isString(value)) {
          return false; // Non-strings never match
        }
        return regex.test(value);
      });
    } catch (e) {
      throw new SSpecError(`Invalid regex pattern: ${pattern}`);
    }
  }),
  // Primitive equality - compares primitives using host language ===
  "primitive-eq": new BuiltinFunction((args, env) => {
    if (args.length !== 2) throw new SSpecError("primitive-eq requires 2 arguments");
    const a = args[0];
    const b = args[1];

    // Numbers, strings, booleans - direct comparison
    if (isNumber(a) && isNumber(b)) return a === b;
    if (isString(a) && isString(b)) return a === b;
    if (isBoolean(a) && isBoolean(b)) return a === b;

    // Keywords - compare wrapped values
    if (isKeyword(a) && isKeyword(b)) return a.kw === b.kw;

    // Symbols - compare wrapped values
    if (isSymbol(a) && isSymbol(b)) return a.sym === b.sym;

    // Different types or non-primitives
    return false;
  }),
  gensym: new BuiltinFunction((args, env) => {
    if (args.length > 1) {
      throw new SSpecError("gensym requires 0 or 1 arguments");
    }

    let prefix: string | undefined;
    if (args.length === 1) {
      if (!isString(args[0])) {
        throw new SSpecError("gensym requires a string");
      }
      prefix = args[0];
    }

    return env.gensym(prefix);
  }),
  load: new BuiltinFunction((args, env) => {
    if (args.length !== 1) throw new SSpecError("load requires 1 argument");
    if (!isString(args[0])) throw new SSpecError("load requires a string");

    // Use root environment for loading (makes loaded definitions globally available)
    const rootEnv = env.root();
    const filepath = args[0];
    const baseDir = rootEnv.currentFile ? dirname(rootEnv.currentFile) : process.cwd();
    const resolvedPath = resolve(baseDir, filepath);

    if (rootEnv.loadedFiles.has(resolvedPath)) return null;
    rootEnv.loadedFiles.add(resolvedPath);

    const code = readFileSync(resolvedPath, "utf-8");
    const exprs = parse(lex(code));

    const prevFile = rootEnv.currentFile;
    rootEnv.currentFile = resolvedPath;
    for (const expr of exprs) {
      const expanded = macroExpand(expr, rootEnv);
      evalExpr(expanded, rootEnv);
    }
    rootEnv.currentFile = prevFile;

    return null;
  }),
};

function isSplicingMarker(val: unknown): val is SplicingMarker {
  return (
    typeof val === "object" &&
    val !== null &&
    "__splice" in val &&
    (val as SplicingMarker).__splice === true
  );
}

function evalQuasiquote(expr: Expr, env: Environment): Expr | SplicingMarker {
  // Literals - return as-is
  if (typeof expr === "object" && expr !== null && "type" in expr) {
    switch (expr.type) {
      case "number":
      case "string":
      case "boolean":
      case "null":
      case "symbol":
      case "keyword":
        return expr;

      case "call":
        const op = expr.op;

        // Check for unquote
        if (isSymbol(op) && op.sym === "unquote") {
          if (expr.args.length !== 1) {
            throw new SSpecError("unquote requires 1 argument", expr.pos);
          }
          return evalExpr(expr.args[0], env) as Expr;
        }

        // Check for unquote-splicing
        if (isSymbol(op) && op.sym === "unquote-splicing") {
          if (expr.args.length !== 1) {
            throw new SSpecError(
              "unquote-splicing requires 1 argument",
              expr.pos
            );
          }
          // Evaluate to get a list, return as splicing marker
          const result = evalExpr(expr.args[0], env);
          // Result can be:
          // 1. A cons cell list (runtime list from 'list' function)
          // 2. An AST call expression (from 'quote')
          // 3. null (empty list)
          if (result === null) {
            return { __splice: true, items: [] };
          }
          if (isCons(result)) {
            // Convert cons list to array of Exprs
            const items = consListToArray(result).map((v) => valueToExpr(v));
            return { __splice: true, items };
          }
          // Handle quoted s-expressions (call expressions from AST)
          if (isCallNode(result)) {
            // Already have Expr array - just use it directly
            return { __splice: true, items: [result.op, ...result.args] };
          }
          if (process.env.DEBUG) {
            console.log("unquote-splicing result type:", typeof result, result);
          }
          throw new SSpecError("unquote-splicing requires a list", expr.pos);
        }

        const newOp = evalQuasiquote(op, env);
        if (isSplicingMarker(newOp)) {
          throw new SSpecError("Cannot splice in operator position", expr.pos);
        }

        const newArgs: Expr[] = [];
        for (const arg of expr.args) {
          const processed = evalQuasiquote(arg, env);
          if (isSplicingMarker(processed)) {
            newArgs.push(...processed.items);
          } else {
            newArgs.push(processed as Expr);
          }
        }

        return ast.call(newOp as Expr, newArgs, expr.pos);

      default:
        return expr;
    }
  }

  return expr;
}

// Note: Recursion depth is tracked in UserFunction.call() and Macro.expand()
// We don't track it here because we want to limit call stack depth,
// not the number of expressions evaluated (which would be too granular)
function evalExpr(expr: Expr, env: Environment): Value {
  // Use discriminated union to handle all node types
  switch (expr.type) {
    case "number":
      return expr.value;
    case "string":
      return expr.value;
    case "boolean":
      return expr.value;
    case "null":
      return null;

    case "keyword":
      return expr;

    case "symbol":
      return env.get(expr.sym, expr.pos);

    case "cons":
      return expr;

    case "array":
      const evaluatedElements = expr.arr.map((elem) => evalExpr(elem, env));
      return ast.array(
        evaluatedElements.map((v) => valueToExpr(v)),
        SYNTHETIC_POS
      );

    case "object":
      const obj: ObjectValue = {};
      for (const [keyExpr, valueExpr] of expr.obj) {
        const key = evalExpr(keyExpr, env);
        const value = evalExpr(valueExpr, env);
        let keyStr: string;
        if (isKeyword(key)) {
          keyStr = key.kw;
        } else if (typeof key === "string") {
          keyStr = key;
        } else {
          throw new SSpecError(
            "Object keys must be keywords or strings",
            expr.pos
          );
        }
        obj[keyStr] = value;
      }
      return obj;

    case "call":
      // Call expressions - handle special forms and function calls
      return evalCallExpr(expr, env);
  }
}

function evalCallExpr(expr: CallNode, env: Environment): Value {
  const pos = expr.pos;
  const opExpr = expr.op;

  if (isSymbol(opExpr)) {
    const opSym = opExpr.sym;

    if (opSym === "def") {
      if (expr.args.length !== 2) {
        throw new SSpecError("def requires 2 arguments", pos);
      }
      const arg0 = expr.args[0];
      if (!isSymbol(arg0)) {
        throw new SSpecError("def first argument must be a symbol", arg0.pos);
      }
      const name = arg0.sym;
      const value = evalExpr(expr.args[1], env);
      env.set(name, value);
      return value;
    }

    if (opSym === "fn") {
      if (expr.args.length !== 2) {
        throw new SSpecError("fn requires 2 arguments", pos);
      }
      const paramsExpr = expr.args[0];
      if (!isArray(paramsExpr)) {
        throw new SSpecError(
          "fn first argument must be an array",
          paramsExpr.pos
        );
      }
      const params = arrayToParams(paramsExpr);
      const body = expr.args[1];
      return new UserFunction(params, body, env);
    }

    if (opSym === "defmacro") {
      if (expr.args.length !== 3) {
        throw new SSpecError("defmacro requires 3 arguments", pos);
      }
      const arg0 = expr.args[0];
      if (!isSymbol(arg0)) {
        throw new SSpecError(
          "defmacro first argument must be a symbol",
          arg0.pos
        );
      }
      const name = arg0.sym;
      const paramsExpr = expr.args[1];
      if (!isArray(paramsExpr)) {
        throw new SSpecError(
          "defmacro second argument must be an array",
          paramsExpr.pos
        );
      }
      const params = arrayToParams(paramsExpr);
      const body = expr.args[2];
      const macro = new Macro(params, body, env);
      env.set(name, macro);
      return macro;
    }

    if (opSym === "let") {
      if (expr.args.length !== 2) {
        throw new SSpecError(
          "let requires 2 arguments: bindings and body",
          pos
        );
      }
      const bindingsExpr = expr.args[0];
      if (!isArray(bindingsExpr)) {
        throw new SSpecError("let bindings must be an array", bindingsExpr.pos);
      }
      const bindings = bindingsExpr.arr;
      if (bindings.length % 2 !== 0) {
        throw new SSpecError(
          "let bindings must have even number of elements",
          bindingsExpr.pos
        );
      }

      const letEnv = new Environment(env);
      for (let i = 0; i < bindings.length; i += 2) {
        const nameExpr = bindings[i];
        if (!isSymbol(nameExpr)) {
          throw new SSpecError(
            "let binding name must be a symbol",
            nameExpr.pos
          );
        }
        const value = evalExpr(bindings[i + 1], letEnv);
        letEnv.set(nameExpr.sym, value);
      }

      return evalExpr(expr.args[1], letEnv);
    }

    if (opSym === "if") {
      if (expr.args.length < 2 || expr.args.length > 3) {
        throw new SSpecError("if requires 2 or 3 arguments", pos);
      }
      const condition = evalExpr(expr.args[0], env);
      if (isTruthy(condition)) {
        return evalExpr(expr.args[1], env);
      } else {
        return expr.args.length === 3 ? evalExpr(expr.args[2], env) : null;
      }
    }

    if (opSym === "do") {
      if (expr.args.length === 0) {
        return null;
      }
      let result: Value = null;
      for (const arg of expr.args) {
        result = evalExpr(arg, env);
      }
      return result;
    }

    if (opSym === "quote") {
      if (expr.args.length !== 1) {
        throw new SSpecError("quote requires 1 argument", pos);
      }
      const arg = expr.args[0];
      if (isNumberNode(arg)) return arg.value;
      if (isStringNode(arg)) return arg.value;
      if (isBooleanNode(arg)) return arg.value;
      if (isNullNode(arg)) return null;
      return arg;
    }

    if (opSym === "quasiquote") {
      if (expr.args.length !== 1) {
        throw new SSpecError("quasiquote requires 1 argument", pos);
      }
      const result = evalQuasiquote(expr.args[0], env);
      return result as Expr;
    }

    if (opSym === "unquote") {
      throw new SSpecError("unquote outside quasiquote", pos);
    }
    if (opSym === "unquote-splicing") {
      throw new SSpecError("unquote-splicing outside quasiquote", pos);
    }

    if (opSym === "expand") {
      if (expr.args.length !== 1) {
        throw new SSpecError("expand requires 1 argument", pos);
      }
      const form = evalExpr(expr.args[0], env);
      if (!isExpr(form)) {
        throw new SSpecError("expand expects an expression (use quote)", pos);
      }
      if (process.env.DEBUG_EXPAND) {
        console.log("expand received form:", toSExpr(form));
      }
      if (!isCallNode(form)) {
        return form;
      }
      const formOp = form.op;
      if (isSymbol(formOp) && env.has(formOp.sym)) {
        const val = env.get(formOp.sym);
        if (val instanceof Macro) {
          const result = val.expand(form.args, env);
          if (process.env.DEBUG_EXPAND) {
            console.log("expand returned:", toSExpr(result));
          }
          return result;
        }
      }
      return form;
    }

    if (opSym === "expand-all") {
      if (expr.args.length !== 1) {
        throw new SSpecError("expand-all requires 1 argument", pos);
      }
      const form = evalExpr(expr.args[0], env);
      if (!isExpr(form)) {
        throw new SSpecError(
          "expand-all expects an expression (use quote)",
          pos
        );
      }
      return macroExpand(form, env);
    }

    if (opSym === "to-sexpr") {
      if (expr.args.length !== 1) {
        throw new SSpecError("to-sexpr requires 1 argument", pos);
      }
      const val = evalExpr(expr.args[0], env);
      return toSExpr(val);
    }

    // Builtin or variable lookup
    let op: Value;
    if (builtins[opSym]) {
      op = builtins[opSym];
    } else if (env.has(opSym)) {
      op = env.get(opSym, pos);
    } else {
      throw new SSpecError(`Unknown function or variable: ${opSym}`, pos);
    }

    if (isCallable(op)) {
      // Callable (builtin or user function) - unified invocation
      const args = expr.args.map((arg) => evalExpr(arg, env));
      return op.call(args, env);
    } else if (op instanceof Macro) {
      // Macro - expand and evaluate
      const expanded = op.expand(expr.args, env);
      return evalExpr(macroExpand(expanded, env), env);
    } else if (isKeyword(op)) {
      // Keyword-as-function: (k map) where k is bound to a keyword
      if (expr.args.length < 1 || expr.args.length > 2) {
        throw new SSpecError(
          "Keyword as function requires 1 or 2 arguments",
          pos
        );
      }
      const evaluatedArgs = expr.args.map((arg) => evalExpr(arg, env));
      const obj = evaluatedArgs[0];

      if (!isPlainObject(obj)) {
        throw new SSpecError(
          "Keyword lookup requires an object as first argument",
          pos
        );
      }

      const keyStr = op.kw;
      const result = (obj as any)[keyStr];

      if (result === undefined) {
        return expr.args.length === 2 ? evaluatedArgs[1] : null;
      }

      return result;
    } else {
      throw new SSpecError("Operator must be a function", pos);
    }
  }

  const op = evalExpr(opExpr, env);

  // Handle keyword-as-function: (:key map) or (:key map default)
  if (isKeyword(op)) {
    if (expr.args.length < 1 || expr.args.length > 2) {
      throw new SSpecError(
        "Keyword as function requires 1 or 2 arguments",
        pos
      );
    }
    const evaluatedArgs = expr.args.map((arg) => evalExpr(arg, env));
    const obj = evaluatedArgs[0];

    if (!isPlainObject(obj)) {
      throw new SSpecError(
        "Keyword lookup requires an object as first argument",
        pos
      );
    }

    const keyStr = op.kw;
    const result = (obj as any)[keyStr];

    if (result === undefined) {
      return expr.args.length === 2 ? evaluatedArgs[1] : null;
    }

    return result;
  }

  if (isCallable(op)) {
    const args = expr.args.map((arg) => evalExpr(arg, env));
    return op.call(args, env);
  } else {
    throw new SSpecError("Operator must be a function", pos);
  }
}

function createEnv(): Environment {
  const env = new Environment();

  for (const [name, fn] of Object.entries(builtins)) {
    env.set(name, fn);
  }

  // Load standard library
  try {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = dirname(__filename);
    const stdlibPath = join(__dirname, "stdlib.lisp");
    const stdlibAbsolutePath = realpathSync(stdlibPath);
    const stdlibCode = readFileSync(stdlibAbsolutePath, "utf-8");

    // Set current file context and mark as loaded
    env.currentFile = stdlibAbsolutePath;
    env.loadedFiles.add(stdlibAbsolutePath);

    const exprs = parse(lex(stdlibCode));
    for (const expr of exprs) {
      const expanded = macroExpand(expr, env);
      evalExpr(expanded, env);
    }

    env.currentFile = null;
  } catch (err) {
    console.warn("Warning: Could not load stdlib.lisp");
    if (process.env.DEBUG) {
      console.error("Stdlib load error:", err);
    }
  }

  return env;
}

const globalEnv = createEnv();

function macroExpand(expr: Expr, env: Environment): Expr {
  if (!isCallNode(expr)) {
    return expr;
  }

  const op = expr.op;

  // Check for special forms that don't expand their arguments
  if (isSymbol(op)) {
    // quote and quasiquote: don't expand any arguments
    if (op.sym === "quote" || op.sym === "quasiquote") {
      return expr;
    }

    // fn and defmacro: don't expand params (first arg), but do expand body
    if (op.sym === "fn" || op.sym === "defmacro") {
      if (expr.args.length < 2) {
        return expr; // Malformed, let evaluation handle the error
      }
      // Keep params unexpanded, expand rest of args (body)
      const params = expr.args[0];
      const body = expr.args.slice(1).map((arg) => macroExpand(arg, env));
      return ast.call(op, [params, ...body], expr.pos);
    }

    // let: don't expand binding names, but do expand binding values and body
    if (op.sym === "let") {
      if (expr.args.length !== 2) return expr;
      const bindingsExpr = expr.args[0];
      if (!isArray(bindingsExpr)) return expr;

      // Expand only values in bindings, not names
      const expandedBindings: Expr[] = [];
      for (let i = 0; i < bindingsExpr.arr.length; i += 2) {
        expandedBindings.push(bindingsExpr.arr[i]);
        if (i + 1 < bindingsExpr.arr.length) {
          expandedBindings.push(macroExpand(bindingsExpr.arr[i + 1], env));
        }
      }

      const expandedBody = macroExpand(expr.args[1], env);
      return ast.call(
        op,
        [ast.array(expandedBindings, bindingsExpr.pos), expandedBody],
        expr.pos
      );
    }

    if (env.has(op.sym)) {
      const val = env.get(op.sym);
      if (val instanceof Macro) {
        // Expand the macro with unevaluated arguments
        const expanded = val.expand(expr.args, env);
        // Recursively expand the result
        return macroExpand(expanded, env);
      }
    }
  }

  // Not a macro call - recursively expand subexpressions
  return ast.call(
    macroExpand(op, env),
    expr.args.map((arg) => macroExpand(arg, env)),
    expr.pos
  );
}

function evaluateWithEnv(input: string, env: Environment): Value {
  const exprs = parse(lex(input));
  let result: Value = null;
  for (const expr of exprs) {
    const expanded = macroExpand(expr, env);
    result = evalExpr(expanded, env);
  }
  return result;
}

export function evaluate(input: string): Value {
  return evaluateWithEnv(input, globalEnv);
}

// Debug API - includes introspection tools
export const debug = {
  evaluate: (input: string) => evaluateWithEnv(input, globalEnv),
  macroExpand,
  parse,
  lex,
  toSExpr,
  Environment,
  globalEnv,
};

export {
  SSpecError,
  toSExpr,
  lex,
  parse,
  Environment,
  evalExpr,
  macroExpand,
  createEnv,
  UserFunction,
  BuiltinFunction,
  isCallable,
  builtins,
};

// CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  const input = process.argv[2];
  if (!input) {
    console.error('Usage: node index.js "<expr>"');
    process.exit(1);
  }
  try {
    const result = evaluate(input);
    if (result !== null) {
      if (isCallable(result)) {
        console.log("<function>");
      } else {
        console.log(result);
      }
    }
  } catch (e) {
    console.error((e as Error).message);
    process.exit(1);
  }
}
