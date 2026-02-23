import { test, describe } from "node:test";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import {
  lex,
  parse,
  Environment,
  evalExpr,
  macroExpand,
  SSpecError,
  createEnv,
  UserFunction,
  BuiltinFunction,
  isCallable,
  builtins,
} from "./index.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Creates an environment with test-specific builtins
 */
function createTestEnvironment(): Environment {
  // Start with a standard environment (includes stdlib)
  const env = createEnv();

  // Load test stdlib (stdlib-test.lisp)
  try {
    const stdlibTestPath = join(dirname(__filename), "stdlib-test.lisp");
    const stdlibTestCode = readFileSync(stdlibTestPath, "utf-8");
    const exprs = parse(lex(stdlibTestCode));
    for (const expr of exprs) {
      const expanded = macroExpand(expr, env);
      evalExpr(expanded, env);
    }
  } catch (err) {
    console.warn("Warning: Could not load stdlib-test.lisp");
    if (process.env.DEBUG) {
      console.error("Test stdlib load error:", err);
    }
  }

  // Add test/test builtin - binds to Node.js test function
  env.set("test/test", new BuiltinFunction((args: any[], testEnv: Environment) => {
    if (args.length !== 2)
      throw new SSpecError("test/test requires 2 arguments: name and function");
    const name = args[0];
    const fn = args[1];

    if (typeof name !== "string") {
      throw new SSpecError(
        "test/test first argument must be a string (test name)"
      );
    }
    if (!isCallable(fn)) {
      throw new SSpecError("test/test second argument must be a function");
    }

    // Call Node.js test function
    // Use testEnv (the environment where test/test was called)
    // This ensures tests run in the same environment where load was called
    test(name, () => {
      fn.call([], testEnv); // Call with the test file's environment
    });

    return null;
  }));

  // Add assert/equal builtin
  env.set("assert/equal", new BuiltinFunction((args: any[], testEnv: Environment) => {
    if (args.length < 2 || args.length > 3) {
      throw new SSpecError(
        "assert/equal requires 2-3 arguments: actual, expected, [message]"
      );
    }

    const actual = args[0];
    const expected = args[1];
    const message = args[2] || "";

    // Use eq function from environment (now defined in stdlib.lisp)
    const eqFn = testEnv.get("eq");
    if (!isCallable(eqFn)) {
      throw new SSpecError("eq function not found in environment");
    }
    const equal = eqFn.call([actual, expected], testEnv);

    if (!equal) {
      const msg = message ? `${message}: ` : "";
      throw new SSpecError(
        `${msg}Expected ${JSON.stringify(expected)} but got ${JSON.stringify(
          actual
        )}`
      );
    }

    return null;
  }));

  // Add assert/throws builtin
  env.set("assert/throws", new BuiltinFunction((args: any[], testEnv: Environment) => {
    if (args.length !== 2) {
      throw new SSpecError(
        "assert/throws requires 2 arguments: function and expected-error-substring"
      );
    }

    const fn = args[0];
    const expectedError = args[1];

    if (!isCallable(fn)) {
      throw new SSpecError("assert/throws first argument must be a function");
    }
    if (typeof expectedError !== "string") {
      throw new SSpecError("assert/throws second argument must be a string");
    }

    let threw = false;
    let error: any = null;

    try {
      fn.call([], testEnv); // Call with the test environment
    } catch (e) {
      threw = true;
      error = e;
    }

    if (!threw) {
      throw new SSpecError(
        `Expected error containing "${expectedError}" but no error was thrown`
      );
    }

    const errorMessage = error?.message || String(error);
    if (!errorMessage.includes(expectedError)) {
      throw new SSpecError(
        `Expected error containing "${expectedError}" but got "${errorMessage}"`
      );
    }

    return null;
  }));

  return env;
}

/**
 * Load and execute a Lisp test file
 */
function runLispTestFile(filepath: string): void {
  const code = readFileSync(filepath, "utf-8");
  const env = createTestEnvironment();

  const exprs = parse(lex(code));
  for (const expr of exprs) {
    const expanded = macroExpand(expr, env);
    evalExpr(expanded, env);
  }
}

// Run Lisp test files
runLispTestFile(join(__dirname, "test/simple.test.lisp"));
runLispTestFile(join(__dirname, "test/basic.test.lisp"));
runLispTestFile(join(__dirname, "test/comparison.test.lisp"));
runLispTestFile(join(__dirname, "test/logical.test.lisp"));
runLispTestFile(join(__dirname, "test/keywords.test.lisp"));
runLispTestFile(join(__dirname, "test/maps.test.lisp"));
runLispTestFile(join(__dirname, "test/vectors.test.lisp"));
runLispTestFile(join(__dirname, "test/control-flow.test.lisp"));
runLispTestFile(join(__dirname, "test/cond.test.lisp"));
runLispTestFile(join(__dirname, "test/let.test.lisp"));
runLispTestFile(join(__dirname, "test/functions.test.lisp"));
runLispTestFile(join(__dirname, "test/variadic.test.lisp"));
runLispTestFile(join(__dirname, "test/load.test.lisp"));
runLispTestFile(join(__dirname, "test/regex.test.lisp"));
runLispTestFile(join(__dirname, "test/macros.test.lisp"));
runLispTestFile(join(__dirname, "test/gensym.test.lisp"));
runLispTestFile(join(__dirname, "test/seq.test.lisp"));
runLispTestFile(join(__dirname, "test/type-safety.test.lisp"));
runLispTestFile(join(__dirname, "test/recursion-depth.test.lisp"));
runLispTestFile(join(__dirname, "test/edge-cases.test.lisp"));
