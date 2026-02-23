import * as readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
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

  // AST nodes (keywords, symbols, cons cells, etc.)
  if (typeof value === "object" && "type" in value) {
    if (value.type === "keyword") {
      return `:${value.kw}`;
    }
    if (value.type === "symbol") {
      return value.sym;
    }
    // For other AST nodes (cons cells, etc), use toSExpr
    return toSExpr(value);
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

  // Plain objects
  if (typeof value === "object") {
    const entries = Object.entries(value).map(
      ([key, val]) => `"${key}": ${formatValueRecursive(val)}`
    );
    return `{${entries.join(", ")}}`;
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
 * Handle REPL commands (lines starting with .)
 */
function handleCommand(
  command: string,
  env: Environment,
): { newEnv?: Environment; exit?: boolean } {
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

To evaluate an expression, just type it and press Enter.
Multi-line expressions are supported - the REPL will wait for balanced parentheses.
`);
    return {};
  }

  if (trimmed === ".reset") {
    console.log("Environment reset.");
    return { newEnv: createEnv() };
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
  let buffer = "";
  let inMultiLine = false;

  try {
    while (true) {
      const prompt = inMultiLine ? "....... " : "s-spec> ";
      const line = await rl.question(prompt);

      // Handle Ctrl+D (null input)
      if (line === null) {
        console.log("\nBye!");
        break;
      }

      // Accumulate input
      buffer += (buffer ? "\n" : "") + line;

      // Check for commands (only on first line, not in multi-line mode)
      if (!inMultiLine && buffer.trim().startsWith(".")) {
        const result = handleCommand(buffer, env);
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
