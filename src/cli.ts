import * as readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { inspect } from "node:util";
import {
  lex,
  parse,
  macroExpand,
  evalExpr,
  createEnv,
  toSExpr,
  Environment,
  SSpecError,
  isCallable,
  evaluate,
  BuiltinFunction,
  isExpr,
  isPlainObject,
} from "./index.ts";

const VERSION = "0.0.1";

/**
 * Check if an expression has balanced parentheses/brackets/braces
 */
function isBalanced(input: string): boolean {
  const stack: string[] = [];
  let inString = false;
  let escaped = false;

  for (let i = 0; i < input.length; i++) {
    const char = input[i];

    if (escaped) {
      escaped = false;
      continue;
    }

    if (char === "\\") {
      escaped = true;
      continue;
    }

    if (char === '"') {
      inString = !inString;
      continue;
    }

    if (inString) continue;

    if (char === "(" || char === "[" || char === "{") {
      stack.push(char);
    } else if (char === ")") {
      if (stack.length === 0 || stack[stack.length - 1] !== "(") return false;
      stack.pop();
    } else if (char === "]") {
      if (stack.length === 0 || stack[stack.length - 1] !== "[") return false;
      stack.pop();
    } else if (char === "}") {
      if (stack.length === 0 || stack[stack.length - 1] !== "{") return false;
      stack.pop();
    }
  }

  return stack.length === 0 && !inString;
}

/**
 * Recursively format a value for display, handling s-spec types
 */
function formatValueRecursive(value: any): string {
  // null/undefined
  if (value === null) return "null";
  if (value === undefined) return "undefined";

  // Functions
  if (isCallable(value)) {
    return "<function>";
  }

  // Primitives
  if (typeof value === "string") {
    return `"${value}"`;
  }
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  // Arrays
  if (Array.isArray(value)) {
    const elements = value.map(formatValueRecursive);
    return `[${elements.join(", ")}]`;
  }

  // Plain objects (user data, not AST nodes)
  if (isPlainObject(value)) {
    const entries = Object.entries(value).map(
      ([key, val]) => `"${key}": ${formatValueRecursive(val)}`
    );
    return `{${entries.join(", ")}}`;
  }

  // AST nodes (keywords, symbols, cons cells, etc.)
  if (isExpr(value)) {
    if (value.type === "keyword") {
      return `:${value.kw}`;
    }
    if (value.type === "symbol") {
      return value.sym;
    }
    // For other AST nodes (cons cells, etc), use toSExpr
    return toSExpr(value);
  }

  return String(value);
}

/**
 * Format a value for display in the REPL
 */
function formatValue(value: any): string {
  if (value === null || value === undefined) {
    return ""; // Don't print null
  }

  return formatValueRecursive(value);
}

/**
 * Create REPL-only builtin functions
 */
function createReplBuiltins(): Record<string, BuiltinFunction> {
  return {
    slurp: new BuiltinFunction((args, env) => {
      if (args.length !== 1) {
        throw new SSpecError("slurp requires 1 argument (path or URL)");
      }

      const pathOrUrl = args[0];
      if (typeof pathOrUrl !== "string") {
        throw new SSpecError("slurp requires a string argument");
      }

      let content: string;

      if (pathOrUrl.startsWith("http://") || pathOrUrl.startsWith("https://")) {
        throw new SSpecError("slurp with URLs not yet supported in synchronous context - use await in async version");
      } else {
        const resolvedPath = resolve(pathOrUrl);
        if (!existsSync(resolvedPath)) {
          throw new SSpecError(`File not found: ${resolvedPath}`);
        }
        content = readFileSync(resolvedPath, "utf-8");
      }

      const data = JSON.parse(content);

      const convertToSSpec = (value: any): any => {
        if (value === null || value === undefined) {
          return null;
        }
        if (typeof value === "object" && !Array.isArray(value)) {
          const obj: Record<string, any> = {};
          for (const [k, v] of Object.entries(value)) {
            obj[k] = convertToSSpec(v);
          }
          return obj;
        }
        if (Array.isArray(value)) {
          return value.map(convertToSSpec);
        }
        return value;
      };

      return convertToSSpec(data);
    }),

    inspect: new BuiltinFunction((args, env) => {
      if (args.length !== 1) {
        throw new SSpecError("inspect requires 1 argument");
      }
      console.log(inspect(args[0], { depth: null, colors: true }));
      return null;
    }),
  };
}

/**
 * Handle REPL commands (lines starting with .)
 */
async function handleCommand(
  command: string,
  env: Environment,
): Promise<{ newEnv?: Environment; exit?: boolean }> {
  const trimmed = command.trim();

  if (trimmed === ".exit" || trimmed === ".quit") {
    return { exit: true };
  }

  if (trimmed === ".help") {
    console.log(`
s-spec REPL Commands:
  .help              Show this help message
  .exit, .quit       Exit the REPL (or press Ctrl+D)
  .reset             Reset environment to initial state
  .expand <expr>     Show macro expansion of <expr>
  .inspect <expr>    Inspect value with full depth and colors
  .load <path>       Load and evaluate s-spec code from file
  .slurp <path|url> [symbol]   Load JSON from file or HTTP(S) URL into symbol (default: it)

REPL-only functions:
  (slurp path)       Load JSON from local file and return parsed data
  (inspect value)    Display value with full depth and colors

Standard functions:
  (load path)        Load and evaluate s-spec code from file

To evaluate an expression, just type it and press Enter.
Multi-line expressions are supported - the REPL will wait for balanced parentheses.
`);
    return {};
  }

  if (trimmed === ".reset") {
    console.log("Environment reset.");
    const newEnv = createEnv();
    // Re-add REPL-only builtins
    const replBuiltins = createReplBuiltins();
    for (const [name, fn] of Object.entries(replBuiltins)) {
      newEnv.set(name, fn);
    }
    return { newEnv };
  }

  if (trimmed.startsWith(".expand ")) {
    const expr = trimmed.slice(8).trim();
    try {
      const tokens = lex(expr);
      const exprs = parse(tokens);
      if (exprs.length === 0) {
        console.log("No expression to expand");
        return {};
      }
      const expanded = macroExpand(exprs[0], env);
      console.log(toSExpr(expanded));
    } catch (e) {
      console.error(`Error: ${(e as Error).message}`);
    }
    return {};
  }

  if (trimmed.startsWith(".inspect ")) {
    const expr = trimmed.slice(9).trim();
    try {
      const tokens = lex(expr);
      const exprs = parse(tokens);
      if (exprs.length === 0) {
        console.log("No expression to inspect");
        return {};
      }
      const expanded = macroExpand(exprs[0], env);
      const result = evalExpr(expanded, env);

      // Call the inspect builtin function
      const inspectFn = env.get("inspect");
      if (isCallable(inspectFn)) {
        inspectFn.call([result], env);
      }
    } catch (e) {
      console.error(`Error: ${(e as Error).message}`);
    }
    return {};
  }

  if (trimmed.startsWith(".load ")) {
    const rest = trimmed.slice(6).trim();
    try {
      let filePath: string;

      // Parse file path (quoted or unquoted)
      if (rest.startsWith('"')) {
        // Quoted path
        let i = 1;
        let path = "";
        let escaped = false;
        while (i < rest.length) {
          if (escaped) {
            path += rest[i];
            escaped = false;
          } else if (rest[i] === "\\") {
            escaped = true;
          } else if (rest[i] === '"') {
            filePath = path;
            break;
          } else {
            path += rest[i];
          }
          i++;
        }
        if (!filePath!) {
          throw new Error("Unterminated string in .load path");
        }
      } else {
        // Unquoted path
        filePath = rest.split(/\s+/)[0];
      }

      // Force reload: remove from loadedFiles set before calling load
      const rootEnv = env.root();
      const baseDir = rootEnv.currentFile ? dirname(rootEnv.currentFile) : process.cwd();
      const resolvedPath = resolve(baseDir, filePath);
      rootEnv.loadedFiles.delete(resolvedPath);

      // Call the load builtin function
      const loadFn = env.get("load");
      if (isCallable(loadFn)) {
        loadFn.call([filePath], env);
        console.log(`Loaded '${filePath}'`);
      }
    } catch (e) {
      console.error(`Error: ${(e as Error).message}`);
    }
    return {};
  }

  if (trimmed.startsWith(".slurp ")) {
    const rest = trimmed.slice(7).trim();
    try {
      // Parse first argument (path)
      const firstQuote = rest.indexOf('"');
      let pathOrUrl: string;
      let symbolName = "it";

      if (firstQuote === 0) {
        // Quoted path
        let i = 1;
        let path = "";
        let escaped = false;
        while (i < rest.length) {
          if (escaped) {
            path += rest[i];
            escaped = false;
          } else if (rest[i] === "\\") {
            escaped = true;
          } else if (rest[i] === '"') {
            pathOrUrl = path;
            // Check for symbol name after path
            const remaining = rest.slice(i + 1).trim();
            if (remaining) {
              const symbolMatch = remaining.match(/^(\S+)/);
              if (symbolMatch) {
                symbolName = symbolMatch[1];
              }
            }
            break;
          } else {
            path += rest[i];
          }
          i++;
        }
        if (!pathOrUrl!) {
          throw new Error("Unterminated string in .slurp path");
        }
      } else {
        // Unquoted path
        const parts = rest.split(/\s+/);
        pathOrUrl = parts[0];
        if (parts[1]) {
          symbolName = parts[1];
        }
      }

      // Handle URLs vs files differently
      let content: string;
      if (pathOrUrl.startsWith("http://") || pathOrUrl.startsWith("https://")) {
        // Async fetch for URLs
        const response = await fetch(pathOrUrl);
        if (!response.ok) {
          throw new SSpecError(`HTTP ${response.status}: ${response.statusText}`);
        }
        content = await response.text();
      } else {
        // Sync file read
        const resolvedPath = resolve(pathOrUrl);
        if (!existsSync(resolvedPath)) {
          throw new SSpecError(`File not found: ${resolvedPath}`);
        }
        content = readFileSync(resolvedPath, "utf-8");
      }

      const data = JSON.parse(content);

      const convertToSSpec = (value: any): any => {
        if (value === null || value === undefined) {
          return null;
        }
        if (typeof value === "object" && !Array.isArray(value)) {
          const obj: Record<string, any> = {};
          for (const [k, v] of Object.entries(value)) {
            obj[k] = convertToSSpec(v);
          }
          return obj;
        }
        if (Array.isArray(value)) {
          return value.map(convertToSSpec);
        }
        return value;
      };

      const sspecValue = convertToSSpec(data);
      env.set(symbolName, sspecValue);
      console.log(`Loaded into '${symbolName}'`);
    } catch (e) {
      console.error(`Error: ${(e as Error).message}`);
    }
    return {};
  }

  console.error(`Unknown command: ${trimmed}`);
  console.error("Type .help for available commands");
  return {};
}

/**
 * Evaluate and print a complete expression
 */
function evalAndPrint(input: string, env: Environment): void {
  try {
    const tokens = lex(input);
    const exprs = parse(tokens);

    for (const expr of exprs) {
      const expanded = macroExpand(expr, env);
      const result = evalExpr(expanded, env);
      const formatted = formatValue(result);
      if (formatted) {
        console.log(formatted);
      }
    }
  } catch (e) {
    if (e instanceof SSpecError) {
      console.error(`Error: ${e.message}`);
    } else {
      console.error(`Error: ${(e as Error).message}`);
    }
  }
}

/**
 * Main REPL loop
 */
async function startRepl(): Promise<void> {
  console.log(`s-spec REPL v${VERSION}`);
  console.log("Type .help for available commands, .exit to quit\n");

  const rl = readline.createInterface({ input, output });
  let env = createEnv();

  // Add REPL-only builtins
  const replBuiltins = createReplBuiltins();
  for (const [name, fn] of Object.entries(replBuiltins)) {
    env.set(name, fn);
  }

  let buffer = "";
  let inMultiLine = false;

  try {
    while (true) {
      const prompt = inMultiLine ? "....... " : "s-spec> ";

      let line: string;
      try {
        line = await rl.question(prompt);
      } catch (e) {
        // Handle Ctrl+D (AbortError)
        if ((e as Error).name === "AbortError") {
          console.log("\nBye!");
          break;
        }
        throw e;
      }

      // Handle Ctrl+D (null input - older Node versions)
      if (line === null) {
        console.log("\nBye!");
        break;
      }

      // Accumulate input
      buffer += (buffer ? "\n" : "") + line;

      // Check for commands (only on first line, not in multi-line mode)
      if (!inMultiLine && buffer.trim().startsWith(".")) {
        const result = await handleCommand(buffer, env);
        if (result.exit) {
          console.log("Bye!");
          break;
        }
        if (result.newEnv) {
          env = result.newEnv;
        }
        buffer = "";
        continue;
      }

      // Check if expression is complete
      if (isBalanced(buffer)) {
        // Evaluate complete expression
        if (buffer.trim()) {
          evalAndPrint(buffer, env);
        }
        buffer = "";
        inMultiLine = false;
      } else {
        // Continue reading for multi-line expression
        inMultiLine = true;
      }
    }
  } finally {
    rl.close();
  }
}

/**
 * Execute a .lisp file
 */
function executeFile(filePath: string): void {
  try {
    const resolvedPath = resolve(filePath);
    const code = readFileSync(resolvedPath, "utf-8");
    const env = createEnv();
    const tokens = lex(code);
    const exprs = parse(tokens);

    for (const expr of exprs) {
      const expanded = macroExpand(expr, env);
      const result = evalExpr(expanded, env);
      // Don't print intermediate results when executing files
    }
  } catch (e) {
    if (e instanceof SSpecError) {
      console.error(`Error: ${e.message}`);
    } else {
      console.error(`Error: ${(e as Error).message}`);
    }
    process.exit(1);
  }
}

/**
 * Evaluate a single expression
 */
function evaluateExpression(expr: string): void {
  try {
    const result = evaluate(expr);
    const formatted = formatValue(result);
    if (formatted) {
      console.log(formatted);
    }
  } catch (e) {
    console.error((e as Error).message);
    process.exit(1);
  }
}

/**
 * Entry point - handles REPL, file execution, and expression evaluation
 */
if (import.meta.url === `file://${process.argv[1]}`) {
  const arg = process.argv[2];

  if (!arg) {
    // No arguments: start REPL
    startRepl().catch((e) => {
      // Ignore AbortError (Ctrl+D) - it's a normal exit
      if ((e as Error).name === "AbortError") {
        return;
      }
      console.error("REPL error:", e);
      process.exit(1);
    });
  } else if (arg.endsWith(".lisp")) {
    // File argument: execute file
    executeFile(arg);
  } else {
    // Expression argument: evaluate expression
    evaluateExpression(arg);
  }
}
