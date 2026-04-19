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

### Reader Syntax (shorthands)

Built-in shorthands that expand during reading. These are not user-definable.

| Syntax | Expansion |
|--------|-----------|
| `'x` | `(quote x)` |
| `` `x `` | `(quasiquote x)` |
| `~x` | `(unquote x)` |
| `~@x` | `(splice-unquote x)` |
| `;` | Comment to end of line |

### Validation Model

The reader is a pure syntax-to-AST converter. It handles:
- Tokenization (numbers, strings, symbols, keywords, booleans, `nil`, `null`)
- Delimiter matching (`(` `)`, `[` `]`, `{` `}`)
- Reader shorthand expansion (`'x` → `(quote x)`, etc.)
- Object literal structure (even number of forms)

All semantic validation happens at eval time:
- Special-form arity and argument types (`def`, `fn`, `if`, `defmacro`, `quote`, `quasiquote`)
- Object key type validation (must be keywords)
- `unquote` / `splice-unquote` quasiquote context requirement

`unquote` and `splice-unquote` outside a `quasiquote` context throw "unquote/splice-unquote outside quasiquote" regardless of arity — context is checked before arity.

The `parse` builtin exposes the reader directly — it returns a form without semantic validation.

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
| `get` | `(get coll key [default])` | Index into array or key into object. |
| `nil?` | `(nil? v)` | |
| `null?` | `(null? v)` | |
| `pair?` | `(pair? v)` | |
| `list?` | `(list? v)` | True for nil and proper lists. |
| `array?` | `(array? v)` | |
| `symbol?` | `(symbol? v)` | |
| `bound?` | `(bound? 'sym)` | True if `sym` is bound in the current lexical scope (walks the env chain). Presence check, not truthiness — a binding to `nil` or `false` still returns `true`. |
| `=` | `(= vals...)` | Deep equality. Objects ignore key order. Functions, macros, and builtins compare by identity. `(=)` → `true`. |
| `/=` | `(/= vals...)` | Logical inverse of `=`. `(/=)` → `false`. |
| `print` | `(print v)` | Canonical string representation. |
| `parse` | `(parse str)` | Read s-spec source string into a form. No semantic validation. |
| `json/parse` | `(json/parse str)` | Parse strict JSON into s-spec values. |
| `json/stringify` | `(json/stringify v)` | Serialize to compact JSON. Rejects nil, lists, functions. |
| `doc` | `(doc fn)` | Get docstring. |
| `gensym` | `(gensym [prefix])` | Unique symbol. |
| `error` | `(error msg)` | Throw an error. |
| `macroexpand-1` | `(macroexpand-1 form)` | If `form` is a list whose head is a symbol bound to a macro, apply that macro once. Otherwise return `form` unchanged. |
| `macroexpand` | `(macroexpand form)` | Repeatedly apply `macroexpand-1` at the head until the head is no longer a macro. Does not descend into sub-forms. |

### Keyword-as-function

Keywords are callable: `(:name obj)` is equivalent to `(get obj :name)`. Accepts optional default: `(:name obj fallback)`.

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
