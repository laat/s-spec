# s-spec

A minimal, embeddable Lisp DSL for validating and conforming JSON values.

## Current Status

This is an early reference implementation with a complete Lisp interpreter foundation. Currently supports:

- **Literals**: numbers, strings, booleans (`true`, `false`), `nil`, keywords (`:keyword`), objects (`{:key value}`), arrays (`[1 2 3]`)
- **Keywords**: Clojure-style keywords (`:name`, `:"any key"`) for tags and object keys
- **Objects**: JavaScript object literals (`{:key "value"}`) with keyword or string keys
- **Arrays**: JSON-style arrays with random access (`[1 2 3]`), operations: `array`, `nth`, `length`, `push`, `array?`
- **Lists**: Cons cell linked lists for s-expressions, operations: `list`, `cons`, `car`, `cdr`
- **Arithmetic**: `+`, `-`, `*`, `/`
- **Comparison operators**: `=`, `>`, `<`, `>=`, `<=` (with chained comparisons and deep equality)
- **Logical operators**: `and`, `or`, `not` (with nil punning)
- **Control flow**: `if` (with lazy evaluation)
- **Variable binding**: `def` (global), `let` (local bindings)
- **Functions**: `fn` (anonymous), `defn` (named - now a macro!)
- **Lexical closures**: functions capture their environment
- **First-class functions**: functions are values, can be passed and returned
- **Recursion**: recursive functions work with `if` conditionals
- **Macros**: `defmacro`, `quote`, `quasiquote`, `unquote`, `unquote-splicing`
- **Standard library**: auto-loaded Lisp code (stdlib.lisp)
- **File loading**: `load` - split code across multiple files
- **Naming conventions**: organize code with prefixed symbols (e.g., `email/validator`)
- **Logging**: `log`
- **Nested expressions**
- **Comments** (`;`)
- **Commas as whitespace**: use commas for readability in maps, arrays, and function calls

## Quick Start

```bash
# Install dependencies
pnpm install

# Build
pnpm build

# Run tests
pnpm test

# Try it out
node dist/index.js "(+ 1 2 3)"
node dist/index.js "(- (* 10 5) (/ 20 4))"
node dist/index.js '(log "Hello from s-spec!")'
```

## Examples

```lisp
; Arithmetic
(+ 1 2 3)        ; => 6
(- 10 3)         ; => 7
(* 2 3 4)        ; => 24
(/ 20 4)         ; => 5

; Nested expressions
(+ (* 2 3) (- 10 5))  ; => 11

; Comparison operators
(> 5 3)               ; => true
(< 1 5)               ; => false
(= 1 1)               ; => true

; Chained comparisons (like Python/Clojure)
(> 10 5 3 1)          ; => true (10 > 5 AND 5 > 3 AND 3 > 1)
(< 1 3 5 10)          ; => true (1 < 3 AND 3 < 5 AND 5 < 10)

; Keywords - Clojure-style tags and identifiers
:name                  ; => :name (simple keyword)
:user-id               ; => :user-id (dashes allowed)
:"my key"              ; => :"my key" (quoted - supports any JSON key)
:""                    ; => :"" (empty string key)
:"with spaces"         ; => :"with spaces"

; Keyword equality
(= :foo :foo)          ; => true
(= :foo :bar)          ; => false

; Keywords as enum values
(defn status-message [status]
  (if (= status :success)
    "Operation succeeded"
    "Operation failed"))
(status-message :success)  ; => "Operation succeeded"

; Objects - JavaScript objects with keyword/string keys
{:name "John" :age 30}           ; => {name: "John", age: 30}
{:name "John", :age 30}          ; => same (commas are optional whitespace)
{}                               ; => {} (empty object)
{:x 1, :y 2, :z 3}               ; => {x: 1, y: 2, z: 3}

; Objects with quoted keywords (any JSON key)
{:"first name" "John"}           ; => {"first name": "John"}
{:"" "empty key"}                ; => {"": "empty key"}

; Objects with string keys
{"name" "John" "age" 30}         ; => {name: "John", age: 30}

; Objects with computed values
{:sum (+ 1 2) :product (* 3 4)}  ; => {sum: 3, product: 12}

; Nested objects
{:user {:name "John" :age 30}}   ; => {user: {name: "John", age: 30}}

; Object equality (deep)
(= {:a 1} {:a 1})                ; => true
(= {:a 1} {:a 2})                ; => false
(= {:a {:b 1}} {:a {:b 1}})      ; => true

; Objects with keyword values
{:status :active :type :user}    ; => {status: :active, type: :user}

; Arrays - JSON-style arrays with random access
[1 2 3]                          ; => [1 2 3] (array literal)
[1, 2, 3]                        ; => same (commas are optional whitespace)
(array 1 2 3)                    ; => [1 2 3] (construct from args)
[]                               ; => [] (empty array)
[1, "mixed", :types, true]       ; => [1 "mixed" :types true]

; Array operations
(nth [10 20 30] 1)               ; => 20 (zero-indexed access)
(nth [10 20 30] 10)              ; => nil (out of bounds)
(length [1 2 3])                 ; => 3 (like JSON array.length)
(push [1 2] 3)                   ; => [1 2 3] (append, returns new array)
(array? [1 2 3])                 ; => true (type check)
(array? (list 1 2 3))            ; => false

; Nested arrays
[[1 2] [3 4] [5 6]]              ; => matrix
(nth (nth [[1 2] [3 4]] 0) 1)    ; => 2

; Lists - cons cell linked lists (for code/data)
(list 1 2 3)                     ; => (1 2 3) as cons cells
(cons 1 (cons 2 nil))            ; => (1 2) manual construction
(car (list 1 2 3))               ; => 1 (first element)
(cdr (list 1 2 3))               ; => (2 3) (rest)
(length (list 1 2 3))            ; => 3 (works on lists too)

; Variable binding
(def x 42)            ; define a global variable
(def y (+ x 10))      ; variables can be used in expressions

; Local bindings with let
(let [x 10 y 20]
  (+ x y))            ; => 30

; let bindings are sequential
(let [x 10
      y (+ x 5)]
  y)                  ; => 15

; let creates local scope
(def x 100)
(let [x 10] x)        ; => 10
x                     ; => 100 (outer binding unchanged)

; Nested let
(let [x 10]
  (let [y 20]
    (+ x y)))         ; => 30

; Anonymous functions
((fn [x] (* x 2)) 5)  ; => 10
(def double (fn [x] (* x 2)))
(double 7)            ; => 14

; Named functions
(defn triple [x] (* x 3))
(triple 4)            ; => 12

; Closures - functions capture their environment
(def multiplier 5)
(defn times-n [x] (* multiplier x))
(times-n 3)           ; => 15

; Higher-order functions
(defn make-adder [n]
  (fn [x] (+ n x)))
(def add10 (make-adder 10))
(add10 5)             ; => 15

(defn compose [f g]
  (fn [x] (f (g x))))
(defn inc [x] (+ x 1))
(defn double [x] (* x 2))
(def inc-then-double (compose double inc))
(inc-then-double 5)   ; => 12

; Functions can take predicates (functions) as arguments
(defn check [predicate value]
  (predicate value))

; Create explicit predicates with fn
(def is-hello (fn [x] (= x "hello")))
(check is-hello "hello")  ; => true
(check is-hello "world")  ; => false

; Build validators by composing predicates
(defn and-check [pred1 pred2]
  (fn [x] (and (pred1 x) (pred2 x))))

(def valid-age? (fn [x] (>= x 18)))
(valid-age? 21)       ; => true
(valid-age? 15)       ; => false

; Logical operators with nil punning
(and 1 2 3)           ; => 3 (returns last value)
(and true false)      ; => false (short-circuits on first falsy)
(and 1 nil 3)         ; => nil (nil is falsy)
(or false nil 42)     ; => 42 (returns first truthy)
(or nil false)        ; => false (returns last if all falsy)

; Note: only nil, false, and undefined are falsy
; 0 and "" are truthy (like in Lisp)
(and 0 1)            ; => 1 (0 is truthy!)
(and "" "x")         ; => "x" (empty string is truthy!)

; Logical negation
(not true)           ; => false
(not false)          ; => true
(not nil)            ; => true
(not 0)              ; => false (0 is truthy!)
(not "")             ; => false ("" is truthy!)

; Conditionals
(if true 1 2)        ; => 1
(if false 1 2)       ; => 2
(if (> 5 3) "yes" "no")  ; => "yes"

; if without else clause returns nil
(if false 42)        ; => nil

; Nested conditionals
(if (> 10 5)
  (if (= 2 2) "both true" "first true")
  "first false")     ; => "both true"

; Lazy evaluation - only evaluates taken branch
(def x 5)
(if true x y)        ; => 5 (y doesn't need to exist!)

; Recursive functions
(defn factorial [n]
  (if (= n 0)
    1
    (* n (factorial (- n 1)))))
(factorial 5)        ; => 120

(defn fib [n]
  (if (<= n 1)
    n
    (+ (fib (- n 1)) (fib (- n 2)))))
(fib 6)              ; => 8

; Validation with conditionals
(defn validate-age [age]
  (if (>= age 18)
    "valid adult"
    "valid minor"))
(validate-age 21)    ; => "valid adult"
(validate-age 15)    ; => "valid minor"

; Macros - code that generates code
; quote - prevent evaluation, return AST as-is
(quote (+ 1 2))      ; => AST structure, not 3
(quote x)            ; => symbol object {sym: "x"}

; quasiquote - template with selective evaluation
(def x 5)
(quasiquote (+ 1 (unquote x)))  ; => AST like (+ 1 5)

; defmacro - define macros
(defmacro when [cond body]
  (quasiquote (if (unquote cond) (unquote body) nil)))
(when true 42)       ; => 42
(when false 42)      ; => nil

; unless macro
(defmacro unless [cond body]
  (quasiquote (if (unquote cond) nil (unquote body))))
(unless false 42)    ; => 42
(unless true 42)     ; => nil

; defn is now a macro!
; Defined in stdlib.lisp as:
; (defmacro defn [name params body]
;   (quasiquote (def (unquote name) (fn (unquote params) (unquote body)))))
(defn triple [x] (* x 3))
(triple 5)           ; => 15

; Macros enable user-defined language constructs
(defmacro defconst [name value]
  (quasiquote (def (unquote name) (unquote value))))
(defconst pi 3.14)
pi                   ; => 3.14

; File loading - split code across multiple files
; validators.lisp:
; (def email/pattern (re "^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$"))
; (defn email/validate [s] (email/pattern s))

; main.lisp:
(load "validators.lisp")
(email/validate "user@example.com")  ; => true

; Files are loaded relative to the loading file
; Each file is loaded only once (idempotent)
; All definitions share the same global environment

; Naming conventions for code organization
; No actual namespaces - just use / in symbol names
(def user/min-age 18)
(defn user/valid-age? [age] (>= age user/min-age))
(user/valid-age? 21)  ; => true

(def email/pattern (re "^[a-z]+@[a-z]+\\.[a-z]+$"))
(defn email/check [s] (email/pattern s))
(email/check "test@example.com")  ; => true

; Logging
(log "Hello!")        ; prints "Hello!" and returns nil

; Comments
; This is a comment
(+ 1 2)  ; inline comment

; Writing tests in Lisp
; Tests can be written in Lisp and run alongside TypeScript tests
(test "addition works"
  (test/assert-equal (+ 1 2) 3 "1 + 2 = 3"))

(test "string operations"
  (test/assert-equal (str "hello" " " "world") "hello world" "concatenation"))
```

## Testing in Lisp

s-spec supports writing tests in Lisp, making tests portable across host language implementations.

### Writing Tests

```lisp
; simple.test.lisp
(test "addition"
  (test/assert-equal (+ 1 2) 3 "1 + 2 should equal 3"))

(test "comparison"
  (test/assert-equal (> 5 3) true "5 is greater than 3"))

(test "error handling"
  (test/assert-throws (fn [] (/ 1 0)) "Division by zero"))
```

### Test Utilities

- `test` - Macro for defining tests (from `stdlib-test.lisp`)
- `test/test` - Underlying function that registers tests with Node.js test runner
- `test/assert-equal` - Assert deep equality with optional message
- `test/assert-throws` - Assert that code throws an error containing expected substring
- `str` - String concatenation for building messages

### Benefits

- **Portable**: Same test files work across TypeScript, Go, Python, Rust implementations
- **Simple**: Host languages only need to implement 3 functions (`test/test`, `test/assert-equal`, `test/assert-throws`)
- **Integrated**: Lisp tests run alongside TypeScript tests via `pnpm test`
- **No try/catch needed**: Language stays simple, error handling is in the test harness

## Architecture

The entire implementation is in a single file (`src/index.ts`, ~800 lines) with four phases:

1. **Lexer** - Tokenizes input into symbols, numbers, strings, brackets, and parentheses
2. **Parser** - Builds an AST from tokens with Symbol types for variable references
3. **Macro expansion** - Recursively expands macros until no macro calls remain
4. **Interpreter** - Evaluates the expanded AST with environments for scoping

**Data structures:**

- **Cons cells** `{car, cdr}` - Classic Lisp linked lists for s-expressions
- **Arrays** `{vec: Expr[]}` - JSON-style random-access arrays
- **Maps** - JavaScript objects for key-value data
- **Keywords** - Symbolic identifiers for tags and enum values

**Key features:**

- **Lexical scoping** with proper environment chains
- **Closures** - functions capture their defining environment
- **First-class functions** - functions are values that can be passed, returned, and stored
- **Special forms** - Only core primitives are special: `def`, `let`, `fn`, `if`, `quote`, `quasiquote`, `unquote`, `unquote-splicing`, `defmacro`
- **Macros** - User-defined code transformations that run before evaluation
  - `defn` is now a macro defined in stdlib.lisp, not hardcoded!
  - Users can define their own language constructs (`when`, `unless`, `cond`, etc.)
  - Macros receive unevaluated AST nodes and return transformed AST
- **Lazy evaluation** - `if` only evaluates the taken branch
- **Recursion** - tail-call recursion works (though not optimized)
- **Standard library** - Lisp code auto-loaded from stdlib.lisp at startup
- **Nil punning** - only `nil` (represented as JS `null`), `false`, and `undefined` are falsy (0 and "" are truthy!)
- **Higher-order functions** - functions that take and return functions work naturally

## Security Considerations

**Important:** s-spec programs are currently **trusted code**. The interpreter provides several protections against programming errors but is not designed for sandboxing untrusted code.

### Current Protections

1. **Recursion Depth Limits** - Default limit of 1000 prevents stack overflow from infinite recursion

   - Configurable via `env.setMaxRecursionDepth(limit)`
   - Protects against unintentional infinite loops and very deep nesting

2. **Error Boundaries** - All errors include source positions (line:col) for debugging

### Security Implications

1. **File System Access** - The `load` function can access any file readable by the process

   - No path validation or sandboxing
   - Programs can load files using relative or absolute paths
   - **Do not** execute untrusted `.lisp` files

2. **No Resource Limits** - Currently no limits on:

   - Memory usage
   - Execution time
   - Number of loaded files

3. **Regex Execution** - User-provided regex patterns execute without timeouts
   - Malicious patterns could cause ReDoS (Regular Expression Denial of Service)
   - Use with caution when processing untrusted input

### Recommendations

- **Only execute trusted s-spec programs**
- For embedded use cases, consider running the interpreter in a separate process with restricted permissions
- If processing untrusted data, validate inputs before passing to s-spec predicates
- Monitor execution time and memory usage in production
- Consider implementing additional resource limits for your use case
