# s-spec

A minimal, embeddable Lisp for validating and conforming JSON values.

## Implementor's Reference

This section lists everything a host language must implement. The stdlib (`stdlib.lisp`) builds everything else from these primitives.

### Types

| Type | Description |
|------|-------------|
| number | IEEE 754 float (1, -3, 4.2) |
| string | UTF-8 with escapes: `\"` `\\` `\n` `\t` `\r` |
| boolean | `true`, `false` |
| nil | Empty list, falsey. Distinct from null. |
| null | JSON null. Truthy. Distinct from nil. |
| symbol | Identifiers: `x`, `my-var`, `cfg/port` |
| keyword | `:name`, `:"spaced key"` |
| pair | Cons cell. `(cons a b)` |
| array | `[1 2 3]` — ordered, zero-indexed |
| object | `{:key val}` — keyword keys, insertion-order |
| function | `(fn [params] body...)` — closure |
| macro | `(defmacro name [params] body...)` — receives unevaluated forms |

### Truthiness

Only `false` and `nil` are falsey. Everything else is truthy — including `null`, `0`, `""`, `[]`, `{}`, symbols, keywords, functions, and macros.

### Special Forms

These must be implemented in the host evaluator. Arguments are **not** evaluated before dispatch.

| Form | Syntax | Description |
|------|--------|-------------|
| `fn` | `(fn [params] body...)` | Create a closure. A leading string is a docstring only when at least one more body form follows; otherwise it is itself a body form. Supports `& rest`. |
| `def` | `(def name expr)` | Bind at the root of the current env chain (not the lexical scope). Returns value. |
| `if` | `(if cond then else)` | Evaluate selected branch only. |
| `do` | `(do forms...)` | Sequential eval, return last. `(do)` → `nil`. |
| `and` | `(and forms...)` | Short-circuit. Returns first falsey or last value. `(and)` → `true`. |
| `or` | `(or forms...)` | Short-circuit. Returns first truthy or last value. `(or)` → `false`. |
| `quote` | `(quote form)` | Return form unevaluated. |
| `quasiquote` | `(quasiquote form)` | Template. `unquote` evaluates, `splice-unquote` splices. |
| `defmacro` | `(defmacro name [params] body...)` | Define macro. Supports `& rest` and docstrings. |
| `load` | `(load "path")` | Read and eval file. Paths resolve relative to caller. |
| `require` | `(require "path")` | Like `load`, but cached by resolved absolute path — requiring the same file from different call sites or via different relative paths evaluates it only once. |

### Tail Calls

Calls in tail position MUST NOT grow the host call stack. This allows recursion-based looping without stack overflow. Tail positions are:

- the last form in a `do`, `fn`, or `defmacro` body
- both branches of an `if`
- the last form in `and` / `or` (the one whose value is returned)
- the body of `load` / `require` (the last form of the loaded file)
- any derived form that expands to the above (e.g. `let`, `when`, `defn`)

Hosts typically implement this as a trampoline or loop in the evaluator.

### Reader Syntax (shorthands)

Built-in shorthands that expand during reading. These are not user-definable.

| Syntax | Expansion |
|--------|-----------|
| `'x` | `(quote x)` |
| `` `x `` | `(quasiquote x)` |
| `~x` | `(unquote x)` |
| `~@x` | `(splice-unquote x)` |
| `;` | Comment to end of line |

### Number Grammar

A token that starts with a digit, or with `-` followed by a digit, is a number and MUST match the JSON number grammar (RFC 8259 §6). Any other token is a symbol.

    number = [ "-" ] int [ frac ] [ exp ]
    int    = "0" / ( digit1-9 *digit )
    frac   = "." 1*digit
    exp    = ("e" / "E") [ "+" / "-" ] 1*digit

- Valid numbers: `0`, `1`, `-3`, `4.2`, `1e10`, `-2.5E-3`
- Invalid — token starts number-like but doesn't match, throws `"invalid number"` at read time: `01`, `1.`, `1.e2`, `1a`, `123abc`
- Symbols — no leading digit and not `-digit`: `+1`, `-`, `-x`, `.5`, `.x`, `a1`

This matches `json/parse` exactly, so any literal valid as a JSON number is valid as a source number, and vice versa.

### Validation Model

The reader is a pure syntax-to-AST converter. It handles:
- Tokenization (numbers, strings, symbols, keywords, booleans, `nil`, `null`). Whitespace separates tokens; comma (`,`) is whitespace.
- Delimiter matching (`(` `)`, `[` `]`, `{` `}`)
- Reader shorthand expansion (`'x` → `(quote x)`, etc.)
- Object literal structure (even number of forms)

All semantic validation happens at eval time:
- Special-form arity and argument types (`def`, `fn`, `if`, `defmacro`, `quote`, `quasiquote`)
- Object key type validation (must be keywords)
- `unquote` / `splice-unquote` quasiquote context requirement

`unquote` and `splice-unquote` outside a `quasiquote` context throw "unquote/splice-unquote outside quasiquote" regardless of arity — context is checked before arity.

The `parse` builtin exposes the reader directly — it returns a form without semantic validation. Input must contain exactly one form; trailing tokens after the first form throw `"unexpected trailing"` at read time.

### Builtins

Functions bound in the global environment.

| Function | Signature | Description |
|----------|-----------|-------------|
| `+` | `(+ nums...)` | Addition. `(+)` → `0`. |
| `first` | `(first pair)` | Head of pair. `(first nil)` → `nil`. |
| `rest` | `(rest pair)` | Tail of pair. `(rest nil)` → `nil`. |
| `cons` | `(cons a b)` | Create pair. |
| `list` | `(list items...)` | Build proper list. `(list)` → `nil`. |
| `array` | `(array items...)` | Build array. |
| `length` | `(length v)` | Length of array, string, or list. |
| `get` | `(get coll key [default])` | Index into array or key into object. Array indices must be integers; out-of-bounds or non-integer indices return the default (or `nil` if none given). |
| `nil?` | `(nil? v)` | |
| `null?` | `(null? v)` | |
| `pair?` | `(pair? v)` | |
| `list?` | `(list? v)` | True for nil and proper lists. |
| `array?` | `(array? v)` | |
| `symbol?` | `(symbol? v)` | |
| `=` | `(= vals...)` | Deep equality. Objects ignore key order. Functions, macros, and builtins compare by identity. `(=)` → `true`. |
| `/=` | `(/= vals...)` | Logical inverse of `=`. `(/=)` → `false`. |
| `print` | `(print v)` | Canonical string representation (see *Canonical Printing*). |
| `parse` | `(parse str)` | Read s-spec source string into a form. No semantic validation. |
| `json/parse` | `(json/parse str)` | Parse strict JSON into s-spec values (see *JSON Serialization*). |
| `json/stringify` | `(json/stringify v)` | Serialize to compact JSON (see *JSON Serialization*). |
| `doc` | `(doc fn)` | Get docstring. |
| `gensym` | `(gensym [prefix])` | Unique symbol. |
| `error` | `(error msg)` | Throw an error. |

### Caller-Env Forms

These three forms are listed separately from the builtins because they require access to the caller's lexical environment and macro bindings, so they cannot be implemented as ordinary closures. A host may implement them as special forms, or as builtins that receive the caller env as an implicit first argument — but their arguments are evaluated (unlike the special forms above).

| Form | Behavior |
|------|----------|
| `bound?` | `(bound? 'sym)` — `sym` is evaluated and must be a symbol (otherwise throws `"bound? requires a symbol"`). Walks the caller's lexical env chain. Presence, not truthiness — a binding to `nil` or `false` still returns `true`. |
| `macroexpand-1` | `(macroexpand-1 form)` — If `form` is a list whose head is a symbol bound to a macro in the caller's env, apply that macro once. Otherwise return `form` unchanged. |
| `macroexpand` | `(macroexpand form)` — Repeatedly apply `macroexpand-1` at the head until the head is no longer a macro (fixpoint by identity). Does not descend into sub-forms. |

### Keyword-as-function

Keywords are callable: `(:name obj)` is equivalent to `(get obj :name)`. Accepts optional default: `(:name obj fallback)`.

### Canonical Printing

`print` emits a canonical string representation. For data values the output is re-readable — feeding it back through `parse` yields an equal value:

- numbers, strings, booleans, `nil`, `null`, symbols, keywords — as written
- arrays, objects, proper lists — as literal syntax
- integers use integer form; non-integers use the shortest decimal that round-trips (same rule as `json/stringify`, so `(print 1.0)` is `"1"`)

Non-data values — functions, macros, builtins, and improper pairs — have an implementation-defined string representation, subject to two requirements:

1. The output MUST be legal s-spec source: `(parse (print v))` must succeed.
2. The parsed result MUST NOT be equal to the original: `(= v (parse (print v)))` must return `false`.

Since functions, macros, and builtins compare by identity and improper pairs have no data-literal syntax, requirement (2) is automatically satisfied by any legal-source output (a parsed symbol or list will never be `=` to a function or an improper pair). The practical contract is: **print output must always be parseable.**

Impls may use any legal-source form — e.g. a symbol like `<fn>` or a list like `(fn)` or `(builtin +)`. Improper pairs are typically printed as a list such as `(cons 1 2)` or `(1 . 2)` — the latter requires `.` to be a legal symbol so the form parses as a 3-element list.

### JSON Serialization

Numbers are float64. `json/parse` does not preserve the integer/decimal distinction — `1` and `1.0` read to the same value. A JSON source literal like `1.0` does not survive a round-trip as `"1.0"`.

`json/stringify` accepts only values that correspond directly to JSON:

| s-spec value     | JSON output                                                           |
|------------------|-----------------------------------------------------------------------|
| `null`           | `null`                                                                |
| boolean          | `true` / `false`                                                      |
| number (finite)  | shortest decimal that round-trips; integer form when integral         |
| string           | JSON string with standard escapes                                     |
| array            | JSON array (recurses)                                                 |
| object           | JSON object; keys are the keyword names without the leading `:`       |

Every other value throws `"json/stringify does not support <type>"` where `<type>` is one of: `nil`, `list`, `pair`, `function`, `macro`, `builtin`, `symbol`, `keyword`, `NaN`, `Infinity`, `-Infinity`.

`json/parse` accepts strict JSON only — no comments, no trailing commas, no unquoted keys, no `NaN`/`Infinity`. Duplicate object keys: last value wins (matches object-literal semantics).

### stdlib

The standard library (`stdlib.lisp`) defines these from primitives. Host implementations may inline them as special forms for performance, but semantics must match.

| Form | Description |
|------|-------------|
| `defonce` | `(defonce name expr)` — bind only if unbound |
| `defmacroonce` | `(defmacroonce name [params] body...)` — define macro only if unbound |
| `let` | `(let [bindings...] body...)` — sequential local bindings |
| `when` | `(when pred then)` |
| `when-not` | `(when-not pred then)` |
| `unless` | `(unless pred then else)` |
| `if-not` | `(if-not pred then else)` |
| `or-else` | `(or-else a b)` — evaluate `a` once; return if truthy, else `b` |
| `and-then` | `(and-then a b)` — evaluate `a` once; return `b` if truthy, else `a` |
| `defn` | `(defn name [params] body...)` — define named function |

### Test Harness

The spec is tested via `.lisp` files using these forms (implemented as special forms in the test runner):

- `(test "name" body...)` — isolated test block
- `(assert/equal actual expected)` — deep equality assertion
- `(assert/throws (fn [] expr) "substring")` — error assertion

Isolation rules:
- Each test runs in a fresh root environment; `def` targets that root — even when called from a nested function or a loaded file — so bindings never leak across tests
- `require` cache and `gensym` counter reset between tests
