# s-spec — Host Implementation Tier

This document specifies the **host-impl tier**: a superset of the user-space language (see [README.md](./README.md)) needed to author and run the reference `stdlib.lisp`. Read README.md first — this document only describes the delta.

## Who needs to read this

- **Path A implementors** — hosts that ship stdlib by running `stdlib.lisp` through a host-impl evaluator at startup. You need everything here.
- **Path B implementors** — hosts that re-implement the stdlib bindings natively as special forms or builtins. You don't need to implement the forms in this document, but you must match the behavior of `stdlib.lisp` as tested under `tests/host/`.

The reference implementation is `stdlib.lisp`. Tests under `tests/host/` exercise the host-impl tier.

## Additional Special Forms

| Form | Syntax | Description |
|------|--------|-------------|
| `quasiquote` | `(quasiquote form)` | Template. `unquote` evaluates, `splice-unquote` splices. |
| `defmacro` | `(defmacro name [params] body...)` | Define macro. Supports `& rest` and docstrings. The name is bound in both the macro table (for call-site expansion) and the variable namespace (for `bound?`, `doc`, and symbol lookup); `(doc name)` returns the macro's docstring and `(bound? (quote name))` returns `true`. **Special-form names always win**: shadowing a special form (e.g. `(defmacro if [...] ...)`) installs the macro but the special form continues to dispatch — the macro is effectively unreachable by name. Hosts MUST dispatch special forms before consulting the macro table. |
| `load` | `(load "path")` | Read and eval file. Paths resolve relative to caller. Always returns `nil` — use the file's own `def`s to expose values. |
| `require` | `(require "path")` | Like `load`, but cached by resolved absolute path — requiring the same file from different call sites or via different relative paths evaluates it only once. **Always returns `nil`**, whether the file was just evaluated or served from cache; use `require` for side effects (installing bindings, macros) and the loaded file's own `def`s to expose values. **Failed loads are not cached**: if evaluating the file throws (parser error, runtime error, any error), the cache is not populated and a subsequent `require` of the same path re-reads and re-evaluates the file from scratch. |

### Tail-position additions

In addition to the user-space tail positions, the last form in a `defmacro` body is also in tail position.

## Additional Reader Shorthands

The host-impl parser recognizes the quasiquote family in addition to `'` and `;`:

| Syntax | Expansion |
|--------|-----------|
| `` `x `` | `(quasiquote x)` |
| `~x` | `(unquote x)` |
| `~@x` | `(splice-unquote x)` |

The user-space parser does **not** recognize these — feeding them to `parse` in user-space is a read-time error.

## Quasiquote Semantics

`unquote` and `splice-unquote` outside a `quasiquote` context throw `"unquote outside quasiquote"` / `"splice-unquote outside quasiquote"` regardless of arity — context is checked before arity.

Inside `quasiquote`, `splice-unquote` splices into lists and arrays. In an object **value** position it is allowed and behaves like `unquote` — the evaluated sequence becomes the value (no spread is possible since only one value is expected). In object **key** position it throws `"splice-unquote is not valid in object key position"`. Directly as the `quasiquote` argument with no enclosing container — `` `(splice-unquote xs) `` — there is nothing to splice into, so it throws `"splice-unquote requires an enclosing list or array"`. When the container exists but the spliced value is not a sequence (e.g. `` `(a (splice-unquote 2) b) ``), it throws a distinct `"splice-unquote value must be a list or array"`. `nil` is the empty proper list, so splicing `nil` into a list or array contributes zero elements (no error).

`unquote` **is** allowed in object key position: `` `{(unquote k) 1} `` evaluates `k` and uses its value as the key. The same key-type rule applies — the value `k` evaluates to must be a keyword, otherwise `"object keys must be keywords"` is thrown. Unlike the splice-unquote key-position rule (which is a structural constraint), this is just the ordinary key-type check applied to the computed key.

All of the above — splicing, key-position rejection, no-container rejection — apply only at **depth 1** (the enclosing `quasiquote` currently being expanded). Each nested `quasiquote` increments depth; each `unquote` / `splice-unquote` decrements it. At depth > 1 the forms are preserved as literal data for the inner `quasiquote` to handle, and no validation fires. So `` ``{(splice-unquote x) 1} `` expands to the form `` `{(splice-unquote x) 1} `` without raising.

## Additional Builtins

| Function | Signature | Description |
|----------|-----------|-------------|
| `gensym` | `(gensym [prefix])` | Unique symbol. Output is `<prefix>__<n>` where `<n>` is a monotonically increasing counter starting at `1`. Default prefix is `"G"`, so `(gensym)` produces `G__1`, `G__2`, …. The counter resets between tests (see *Test Harness* in README). |
| `macroexpand-1` | `(macroexpand-1 form)` | If `form` is a list whose head is a symbol bound to a macro in the caller's env, apply that macro once. Otherwise return `form` unchanged. (Caller-env form — see README.) |
| `macroexpand` | `(macroexpand form)` | Repeatedly apply `macroexpand-1` at the head until the head is no longer bound to a macro. Termination is decided by head inspection only (not by structural comparison of successive expansions), so a macro that rewrites to a form with the same head symbol halts as soon as that head ceases to name a macro. Does not descend into sub-forms. (Caller-env form — see README.) |

### Additional Builtin Docstrings

| Builtin | Docstring |
|---------|-----------|
| `gensym` | `Unique symbol.` |
| `macroexpand-1` | `Expand the form once at the head, if it is a macro call.` |
| `macroexpand` | `Repeatedly macroexpand at the head until a fixpoint.` |

## Additional stdlib Forms

On top of the user-space stdlib (see README), the host tier additionally provides:

| Form | Description |
|------|-------------|
| `defonce` | `(defonce name expr)` — bind only if unbound. Used primarily inside stdlib and module files to make reloads idempotent. |
| `defmacroonce` | `(defmacroonce name [params] body...)` — define macro only if unbound. Counterpart to `defonce` for macros. |

## Additional Error Vocabulary

**Reader**

| Condition | Substring |
|---|---|
| Quasiquote reader shorthand with nothing after it | `expected form after quasiquote` / `expected form after unquote` / `expected form after splice-unquote` |

**Special-form arity and shape**

| Condition | Substring |
|---|---|
| `(defmacro)` / `(defmacro m)` | `defmacro requires a name, params, and body` |
| `(defmacro "m" [x] x)` | `defmacro name must be a symbol` |
| `(defmacro m x x)` | `defmacro params must be a vector` |
| `(defmacro m [x])` — no body | `defmacro requires a body` |
| `(defonce)` / `(defonce x 1 2)` | `defonce requires exactly two arguments` |
| `(defonce "x" 1)` etc. | `defonce name must be a symbol` |
| `(defmacroonce "m" …)` | `defmacroonce name must be a symbol` |
| `(defmacroonce m x x)` | `defmacroonce params must be a vector` |
| `(defmacroonce m [x])` | `defmacroonce requires a body` |
| `(quasiquote)` / `(quasiquote a b)` | `quasiquote requires exactly one argument` |
| `(unquote)` / `(unquote a b)` inside `quasiquote` | `unquote requires exactly one argument` |
| `(splice-unquote)` / `(splice-unquote a b)` inside `quasiquote` | `splice-unquote requires exactly one argument` |
| `unquote` / `splice-unquote` outside `quasiquote` (any arity) | `unquote outside quasiquote` / `splice-unquote outside quasiquote` |

**Quasiquote expansion**

| Condition | Substring |
|---|---|
| `splice-unquote` at top of `quasiquote` (no enclosing list/array) | `splice-unquote requires an enclosing list or array` |
| `splice-unquote` whose value is not a list or array | `splice-unquote value must be a list or array` |
| `splice-unquote` in object key position | `splice-unquote is not valid in object key position` |

**Utilities**

| Condition | Substring |
|---|---|
| `(gensym p)` where `p` is not a string | `gensym prefix must be a string` |
| `(gensym a b)` — too many args | `gensym requires zero or one argument` |
| `(macroexpand-1)` / `(macroexpand-1 a b)` | `macroexpand-1 requires exactly one argument` |
| `(macroexpand)` / `(macroexpand a b)` | `macroexpand requires exactly one argument` |

**Modules**

| Condition | Substring |
|---|---|
| `(load v)` / `(require v)` where `v` is not a string | `load requires a string path` / `require requires a string path` |
| `(load)` / `(load a b)` / `(require)` / `(require a b)` — wrong arity | `load requires exactly one argument` / `require requires exactly one argument` |
| Target file does not exist | `file not found` |

**let (stdlib, authored as a host-impl macro)**

`let` is delivered to user-space as a pre-expanded macro (Path A) or as a native special form (Path B); either way the errors below are observable in user-space too, but the macro that raises them lives in `stdlib.lisp`.

| Condition | Substring |
|---|---|
| `(let x body)` — bindings not a vector | `let bindings must be a vector` |
| `(let [x] body)` — odd bindings | `let requires an even number of binding forms` |
| `(let ["x" 1] body)` / `(let [:x 1] body)` | `let binding name must be a symbol` |
