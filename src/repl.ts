import * as readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";
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
 * Format a value for display in the REPL
 */
function formatValue(value: any): string {
  if (value === null || value === undefined) {
    return ""; // Don't print null
  }

  if (isCallable(value)) {
    return "<function>";
  }

  if (typeof value === "object" && "type" in value) {
    // It's an AST node
    return toSExpr(value);
  }

  if (typeof value === "string") {
    return `"${value}"`;
  }

  if (typeof value === "object") {
    return JSON.stringify(value, null, 2);
  }

  return String(value);
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
 * Entry point
 */
if (import.meta.url === `file://${process.argv[1]}`) {
  startRepl().catch((e) => {
    console.error("REPL error:", e);
    process.exit(1);
  });
}
