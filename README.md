# s-spec

A minimal, embeddable Lisp for validating and conforming JSON values.

## Implementor's Reference

This section lists everything a host language must implement. The stdlib (`stdlib.lisp`) builds everything else from these primitives.

### Types

| Type | Description |
|------|-------------|
| number | finite IEEE 754 float64 (1, -3, 4.2) — `NaN`, `Infinity`, `-Infinity` are not representable |
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

### Namespace Model

s-spec is a **Lisp-1**: functions, macros, and values share a single variable namespace. A symbol resolves the same way in operator position (head of a call) as in value position.

- `(def x 1)` followed by `(defmacro x [y] ...)` replaces `x` — the later binding wins.
- `(bound? (quote name))` is `true` for any binding — var, function, or macro.
- `defmacroonce` no-ops if the name is already bound **by anything** (var or macro). This is the standard Lisp-1 interpretation of "already bound".
- Special-form names (`if`, `def`, `fn`, `quote`, …) are not in the namespace at all; they dispatch before name lookup. See the `defmacro` row below.

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
| `defmacro` | `(defmacro name [params] body...)` | Define macro. Supports `& rest` and docstrings. The name is bound in both the macro table (for call-site expansion) and the variable namespace (for `bound?`, `doc`, and symbol lookup); `(doc name)` returns the macro's docstring and `(bound? (quote name))` returns `true`. **Special-form names always win**: shadowing a special form (e.g. `(defmacro if [...] ...)`) installs the macro but the special form continues to dispatch — the macro is effectively unreachable by name. Hosts MUST dispatch special forms before consulting the macro table. |
| `load` | `(load "path")` | Read and eval file. Paths resolve relative to caller. Always returns `nil` — use the file's own `def`s to expose values. |
| `require` | `(require "path")` | Like `load`, but cached by resolved absolute path — requiring the same file from different call sites or via different relative paths evaluates it only once. **Always returns `nil`**, whether the file was just evaluated or served from cache; use `require` for side effects (installing bindings, macros) and the loaded file's own `def`s to expose values. **Failed loads are not cached**: if evaluating the file throws (parser error, runtime error, any error), the cache is not populated and a subsequent `require` of the same path re-reads and re-evaluates the file from scratch. |

### Tail Calls

Calls in tail position MUST NOT grow the host call stack. This allows recursion-based looping without stack overflow. Tail positions are:

- the last form in a `do`, `fn`, or `defmacro` body
- both branches of an `if`
- the last form in `and` / `or` (the one whose value is returned)
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
- A literal that matches the grammar but overflows float64 (e.g. `1e400`) also throws `"invalid number"` at read time — numbers are finite
- Symbols — no leading digit and not `-digit`: `+1`, `-`, `-x`, `.5`, `.x`, `a1`

This matches `json/parse` exactly, so any literal valid as a JSON number is valid as a source number, and vice versa.

### Symbol and Keyword Names

The body of a symbol, or the unquoted body of a keyword, is a **name**:

    name-char  = %x41-5A / %x61-7A / %x30-39     ; A-Z a-z 0-9
               / "_" / "+" / "-" / "*" / "/"
               / "?" / "!" / "<" / ">" / "=" / "." / "&"
    symbol     = (name-char - digit) *name-char  ; first char cannot start a number
    kw-name    = 1*name-char                     ; first char may be a digit (the `:` disambiguates)

`:` is not a name character — it's reserved as the keyword prefix. Symbol first-char restrictions follow from the Number Grammar (tokens that start with a digit or `-digit` are numbers).

Keywords whose body contains any character outside the name grammar — whitespace, comma, `()[]{}`, `"`, `;`, `'`, `` ` ``, `~`, `:` — MUST use the quoted form `:"..."`, which permits any characters with standard string escapes. The empty body `:""` also requires the quoted form.

Examples:
- Unquoted: `:foo`, `:cfg/port`, `:+`, `:<=`, `:a-b`, `:2023`
- Quoted required: `:"foo bar"`, `:"a:b"`, `:"a,b"`, `:"a;b"`, `:""`

**Printer rule.** When printing a keyword, emit the unquoted form if the name matches the grammar above; otherwise emit the quoted form. Symbol printing is unconditional (symbols always have valid names by construction).

### Validation Model

The reader is a pure source-to-form converter. Its output is ordinary s-spec data — lists, arrays, atoms — with **one exception**: because object keys are validated at eval/quote time (not at read time), the reader's result for `{…}` is an unvalidated *object-literal form* that may hold any shape of key. `(parse "{\"a\" 1}")` must succeed, even though eval and quote will later throw `"object keys must be keywords"`. Hosts may represent this as a distinct internal form or as an Object that permits any key — the externally observable requirements are: (1) `parse` succeeds on syntactically well-formed `{…}` regardless of key types, (2) every eval and quote path turns it into a runtime Object with keyword-only keys, (3) the printer prints object-literal forms the same as runtime Objects, and (4) when an object-literal form happens to have keyword-only keys, it compares `=` to the runtime Object with the same keys and values — so `(= (parse "{:a 1}") {:a 1})` is `true`.

The reader handles:
- Tokenization (numbers, strings, symbols, keywords, booleans, `nil`, `null`). Whitespace separates tokens; comma (`,`) is whitespace.
- Delimiter matching (`(` `)`, `[` `]`, `{` `}`)
- Reader shorthand expansion (`'x` → `(quote x)`, etc.)
- Object literal structure (even number of forms)

All semantic validation happens at eval time:
- Special-form arity and argument types (`def`, `fn`, `if`, `defmacro`, `quote`, `quasiquote`)
- Object key type validation (must be keywords)
- `unquote` / `splice-unquote` quasiquote context requirement

**Literal-to-constructor equivalence.** The literal forms `[…]` and `{…}` are equivalent to calls to their constructors — they share representation and equality semantics:

- `[v1 v2 …]` evaluates to the same value as `(array v1 v2 …)` — so `(= [1 2] (array 1 2))` is `true`
- `{:k1 v1 :k2 v2 …}` evaluates to the same value as `(object :k1 v1 :k2 v2 …)` — so `(= {:a 1} (object :a 1))` is `true`

Quoted literals evaluate through the same construction path as their literal form: `(quote {:a 1})` runs the quote construction path (validate keys, take values unevaluated) and produces a runtime Object, identical to `{:a 1}`. Therefore `(= (quote {:a 1}) {:a 1})` is `true`, `(= (quote {:a 1}) (quote {:a 1}))` is `true`, and the parallel holds for arrays. Quoted object literals whose value positions contain forms (e.g. `(quote {:a (+ 1 2)})`) are objects whose values happen to be list forms (the quote path does not evaluate values).

**Object literal key validation.** `{…}` is a form. Two construction paths produce a runtime Object from it, and **both validate that every key is a keyword**:

- **Evaluation** — validate keys, evaluate each value, build the Object.
- **Quote** — validate keys, take values unevaluated (each value may itself be any form, including a list), build the Object. Quote **recurses into nested object literals** — any object-literal form appearing as a value (including inside nested arrays) is itself validated and converted to a runtime Object. This means `(quote {:a {"b" 1}})` throws, and a runtime Object never contains a nested unvalidated object-literal form.

Either path throws `"object keys must be keywords"` if any key is not a keyword. So `(fn [] {"a" 1})` throws when called, **and** `(quote {"a" 1})` also throws. The only difference between the two paths is whether values are evaluated. This keeps runtime Object a single type whose keys are always keywords; only the short-lived object-literal form produced by `parse` ever holds non-keyword keys.

`unquote` and `splice-unquote` outside a `quasiquote` context throw "unquote/splice-unquote outside quasiquote" regardless of arity — context is checked before arity.

Inside `quasiquote`, `splice-unquote` splices into lists and arrays. In an object **value** position it is allowed and behaves like `unquote` — the evaluated sequence becomes the value (no spread is possible since only one value is expected). In object **key** position it throws `"splice-unquote is not valid in object key position"`. Directly as the `quasiquote` argument with no enclosing container — `` `(splice-unquote xs) `` — there is nothing to splice into, so it throws `"splice-unquote requires an enclosing list or array"`. When the container exists but the spliced value is not a sequence (e.g. `` `(a (splice-unquote 2) b) ``), it throws a distinct `"splice-unquote value must be a list or array"`. `nil` is the empty proper list, so splicing `nil` into a list or array contributes zero elements (no error).

`unquote` **is** allowed in object key position: `` `{(unquote k) 1} `` evaluates `k` and uses its value as the key. The same key-type rule applies — the value `k` evaluates to must be a keyword, otherwise `"object keys must be keywords"` is thrown. Unlike the splice-unquote key-position rule (which is a structural constraint), this is just the ordinary key-type check applied to the computed key.

All of the above — splicing, key-position rejection, no-container rejection — apply only at **depth 1** (the enclosing `quasiquote` currently being expanded). Each nested `quasiquote` increments depth; each `unquote` / `splice-unquote` decrements it. At depth > 1 the forms are preserved as literal data for the inner `quasiquote` to handle, and no validation fires. So `` ``{(splice-unquote x) 1} `` expands to the form `` `{(splice-unquote x) 1} `` without raising.

The `parse` builtin exposes the reader directly — it returns a form without semantic validation. Input must contain exactly one form; trailing tokens after the first form throw `"unexpected trailing"` at read time.

### Builtins

Functions bound in the global environment.

| Function | Signature | Description |
|----------|-----------|-------------|
| `+` | `(+ nums...)` | Addition. `(+)` → `0`. Throws `"+ requires numbers"` on any non-number argument and `"arithmetic overflow"` if the result is not finite. |
| `first` | `(first pair)` | Head of pair. `(first nil)` → `nil`. Throws `"first requires a pair or nil"` on any other value. |
| `rest` | `(rest pair)` | Tail of pair. `(rest nil)` → `nil`. Throws `"rest requires a pair or nil"` on any other value. |
| `cons` | `(cons a b)` | Create pair. |
| `list` | `(list items...)` | Build proper list. `(list)` → `nil`. |
| `array` | `(array items...)` | Build array. |
| `object` | `(object items...)` | Build object. Items alternate keyword keys and values. Throws `"object arity mismatch"` on odd count and `"object keys must be keywords"` on non-keyword keys. |
| `length` | `(length v)` | Length of array, string, list, or object. On strings, counts Unicode code points (so `(length "🎉")` is `1`, not `2` UTF-16 code units or `4` UTF-8 bytes). On objects, returns the number of keys. |
| `get` | `(get coll key [default])` | Look up in an array (integer index) or object (keyword key). Returns the default (or `nil` if none given) when `coll` is `nil`, or when the key/index type doesn't match the collection, or when the index is out of bounds / key missing. Throws `"get requires an array or object"` for any other value — numbers, strings, booleans, improper pairs. |
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
| `doc` | `(doc v)` | Get docstring. Accepts functions, macros, and builtins; throws `"doc requires a function, macro, or builtin"` on any other value. Returns `nil` for a function or macro with no docstring; returns the canonical one-line docstring (see *Builtin Docstrings*) for every builtin. |
| `gensym` | `(gensym [prefix])` | Unique symbol. Output is `<prefix>__<n>` where `<n>` is a monotonically increasing counter starting at `1`. Default prefix is `"G"`, so `(gensym)` produces `G__1`, `G__2`, …. The counter resets between tests (see *Test Harness*). |
| `error` | `(error msg)` | Throw an error. |

### Builtin Docstrings

`doc` on a builtin MUST return exactly the string listed here. This makes `(doc +)` interchangeable across host implementations.

| Builtin | Docstring |
|---------|-----------|
| `+` | `Add numbers.` |
| `first` | `Return the head of a pair.` |
| `rest` | `Return the tail of a pair.` |
| `cons` | `Create a pair from head and tail.` |
| `list` | `Build a proper list from items.` |
| `array` | `Build an array from items.` |
| `object` | `Build an object from alternating keyword keys and values.` |
| `length` | `Length of an array, string, list, or object.` |
| `get` | `Look up a key in an array or object.` |
| `nil?` | `True when the value is nil.` |
| `null?` | `True when the value is null.` |
| `pair?` | `True when the value is a pair.` |
| `list?` | `True when the value is nil or a proper list.` |
| `array?` | `True when the value is an array.` |
| `symbol?` | `True when the value is a symbol.` |
| `=` | `Deep equality; identity for callables.` |
| `/=` | `Logical inverse of =.` |
| `print` | `Canonical string representation of a value.` |
| `parse` | `Read an s-spec source string into a form.` |
| `json/parse` | `Parse strict JSON into an s-spec value.` |
| `json/stringify` | `Serialize a value to compact JSON.` |
| `doc` | `Get the docstring of a function, macro, or builtin.` |
| `gensym` | `Unique symbol.` |
| `error` | `Throw an error with the given message.` |
| `bound?` | `True when the given symbol is bound in the caller's env.` |
| `macroexpand-1` | `Expand the form once at the head, if it is a macro call.` |
| `macroexpand` | `Repeatedly macroexpand at the head until a fixpoint.` |

### Caller-Env Forms

These three forms are listed separately from the builtins because they require access to the caller's lexical environment and macro bindings, so they cannot be implemented as ordinary closures. A host may implement them as special forms, or as builtins that receive the caller env as an implicit first argument — but their arguments are evaluated (unlike the special forms above).

| Form | Behavior |
|------|----------|
| `bound?` | `(bound? 'sym)` — `sym` is evaluated and must be a symbol (otherwise throws `"bound? requires a symbol"`). Walks the caller's lexical env chain. Presence, not truthiness — a binding to `nil` or `false` still returns `true`. |
| `macroexpand-1` | `(macroexpand-1 form)` — If `form` is a list whose head is a symbol bound to a macro in the caller's env, apply that macro once. Otherwise return `form` unchanged. |
| `macroexpand` | `(macroexpand form)` — Repeatedly apply `macroexpand-1` at the head until the head is no longer bound to a macro. Termination is decided by head inspection only (not by structural comparison of successive expansions), so a macro that rewrites to a form with the same head symbol halts as soon as that head ceases to name a macro. Does not descend into sub-forms. |

### Keyword-as-function

Keywords are callable: `(:name obj)` looks up `:name` in `obj`, with optional default: `(:name obj fallback)`. Unlike `get` (which is lenient), keyword-as-function is strict: `obj` must be an object, and any other value — including `nil`, `null`, arrays, numbers, strings, lists — throws `"requires an object"`.

### Canonical Printing

`print` emits a canonical string representation. For data values the output is re-readable — feeding it back through `parse` yields an equal value:

- numbers — see *Number Printing* below
- strings, booleans, `nil`, `null`, symbols, keywords — as written
- arrays, objects, proper lists — as literal syntax

**Number Printing.** `print` on a number MUST produce exactly the string that ECMAScript's `Number.prototype.toString(10)` would (ECMA-262 §6.1.6.1.13 *Number::toString*). The same formatter is used by `json/stringify`. Hosts that already expose this rule (JavaScript, and most JSON libraries that implement ECMA-404's "shortest round-trip") can delegate directly; others must implement the algorithm. Because numbers are finite, `NaN` / `Infinity` / `-Infinity` never reach the printer.

Informally, the rule produces:

- integer form (no decimal point, no exponent) when `v` is integral and `|v| < 1e21` — so `(print 1.0)` is `"1"` and `(print 1e10)` is `"10000000000"`
- otherwise, the shortest decimal that round-trips to the same float64, with lowercase `e` and a signed exponent for scientific notation: `1e+21`, `1.5e-10`
- `"0"` for both `0` and `-0` (the ECMAScript rule; negative zero is printed without the sign)

The 1e21 threshold is where integer form would require 22+ digits and scientific is always shorter. Any divergence from `Number.toString` is a bug in the implementation, not in the spec.


Non-data values print as fixed list forms. The output is always legal source and never `=` to the original value (since a parsed list is never `=` to a function, macro, builtin, or improper pair):

| Value          | Print form                                         |
|----------------|----------------------------------------------------|
| function       | `(fn)`                                             |
| macro          | `(macro)`                                          |
| builtin        | `(builtin NAME)` — `NAME` is the builtin's symbol  |
| improper pair  | walk form (see below)                              |

Improper pairs print in **walk form**: follow the `rest` chain, space-separating each `first`, and stop at the first non-pair tail. If that tail is `nil`, the output is a proper-list form (but this case can only arise if the chain was built by `cons`-ing onto `nil`, in which case equality with a real list still fails because a pair is not `=` to a list form). If the tail is any other value, emit ` . ` followed by its print form. Examples:

- `(cons 1 2)` → `"(1 . 2)"`
- `(cons 1 (cons 2 3))` → `"(1 2 . 3)"`
- `(cons 1 (cons 2 (cons 3 :end)))` → `"(1 2 3 . :end)"`

The improper-pair form relies on `.` being a legal one-character symbol, which it is under the name grammar (`.` is a name-char and not digit-first).

### JSON Serialization

Numbers are float64. `json/parse` does not preserve the integer/decimal distinction — `1` and `1.0` read to the same value. A JSON source literal like `1.0` does not survive a round-trip as `"1.0"`.

`json/stringify` accepts only values that correspond directly to JSON:

| s-spec value     | JSON output                                                           |
|------------------|-----------------------------------------------------------------------|
| `null`           | `null`                                                                |
| boolean          | `true` / `false`                                                      |
| number           | same formatter as `print` (see *Number Printing* above) — all numbers are finite |
| string           | JSON string with standard escapes                                     |
| array            | JSON array (recurses)                                                 |
| object           | JSON object; keys are the keyword names without the leading `:`       |

Every other value throws `"json/stringify does not support <type>"` where `<type>` is one of: `nil`, `list`, `pair`, `function`, `macro`, `builtin`, `symbol`, `keyword`.

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

### Error Vocabulary

Every error s-spec raises is matched by substring in the spec tests (see `(assert/throws … "substring")`). Implementations MUST produce an error whose message contains the substring shown here for the listed condition. The exact full text is unspecified — host implementations can prepend paths, line numbers, or context — but the substring must be present literally.

This table is the canonical vocabulary. Do not invent new phrasings for conditions already listed.

**Reader / parser**

| Condition | Substring |
|---|---|
| Unclosed `(`, `[`, `{`, string, or quote shorthand with no following form | `unexpected end of input` |
| Stray `)`, `]`, or `}` | `unexpected closing delimiter` |
| Extra tokens after the first form in `parse` | `unexpected trailing` |
| `"…` never closed | `unterminated string` |
| `\q` or other unknown escape | `invalid string escape` |
| `01`, `1.`, `1.e2`, `1a`, `123abc`, or a literal that overflows float64 (`1e400`) | `invalid number` |
| Bare `:` or `{: 1}` (no keyword body) | `invalid keyword` |
| Object literal with an odd number of forms (reader-level check) | `requires an even number of forms` |
| Reader shorthand with nothing after it | `expected form after quote` / `expected form after quasiquote` / `expected form after unquote` / `expected form after splice-unquote` |

**Special-form arity and shape**

| Condition | Substring |
|---|---|
| `(def)` / `(def x)` / `(def x 1 2)` | `def requires exactly two arguments` |
| `(def "x" 1)` / `(def :x 1)` / `(def [x] 1)` | `def name must be a symbol` |
| `(defonce)` / `(defonce x 1 2)` | `defonce requires exactly two arguments` |
| `(defonce "x" 1)` etc. | `defonce name must be a symbol` |
| `(if)` / `(if p t)` / `(if p t e extra)` | `if requires exactly three arguments` |
| `(fn x body)` — params not a vector | `fn params must be a vector` |
| `(fn [x y])` / `(fn [])` — no body | `fn requires a body` |
| `(defmacro)` / `(defmacro m)` | `defmacro requires a name, params, and body` |
| `(defmacro "m" [x] x)` | `defmacro name must be a symbol` |
| `(defmacro m x x)` | `defmacro params must be a vector` |
| `(defmacro m [x])` — no body | `defmacro requires a body` |
| `(fn)` with no arguments | `fn requires params and a body` |
| `(fn [1] …)` / `(fn [:k] …)` / `(fn ["x"] …)` — non-symbol in params | `fn param names must be symbols` |
| `(fn [x &] …)` / `(fn [& x y] …)` / `(fn [& &] …)` — `&` misuse | `& must be followed by exactly one rest name` |
| `(defmacroonce "m" …)` | `defmacroonce name must be a symbol` |
| `(defmacroonce m x x)` | `defmacroonce params must be a vector` |
| `(defmacroonce m [x])` | `defmacroonce requires a body` |
| `(quote)` / `(quote a b)` | `quote requires exactly one argument` |
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

**Object construction**

| Condition | Substring |
|---|---|
| Non-keyword key in `{…}`, `(object …)`, `(quote {…})`, or computed via `(unquote …)` | `object keys must be keywords` |
| `(object …)` called with an odd number of arguments | `object arity mismatch` |
| `(:key …)` applied to any non-object value | `requires an object` |
| `(:key)` / `(:key obj d extra)` — keyword-as-function with zero or 3+ args | `keyword lookup requires one or two arguments` |

**Callable / arity**

| Condition | Substring |
|---|---|
| Too few or too many positional args to a user function | `arity mismatch` |
| Head of a call form is not a function, macro, builtin, or keyword | `requires a function` |
| `(get v …)` where `v` is not an array, object, or `nil` | `get requires an array or object` (tests match the shorter `get requires`) |
| `(first v)` / `(rest v)` where `v` is neither a pair nor `nil` | `first requires a pair or nil` / `rest requires a pair or nil` |
| `(+ v …)` where any `v` is not a number | `+ requires numbers` |
| `(+ …)` producing a non-finite result | `arithmetic overflow` |

**Resolution / binding**

| Condition | Substring |
|---|---|
| Reference to an unbound symbol | `undefined symbol` |
| `(bound? v)` where `v` is not a symbol | `requires a symbol` |
| `(doc v)` where `v` is not a function, macro, or builtin | `doc requires a function, macro, or builtin` |

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

**JSON**

| Condition | Substring |
|---|---|
| Unterminated array/object in `json/parse` | `unexpected end of input` |
| Stray closing bracket in `json/parse` | `unexpected token` |
| Trailing `,` before `]` or `}` | `trailing comma` |
| Unquoted key in a JSON object | `object keys must be strings` |
| Missing `:` between key and value | `expected ':'` |
| Empty value slot (`{"a":}`, `[,1]`) | `expected value` |
| Missing `,` between array elements | `expected ',' or ']'` |
| `01`, `1.`, `+1`, etc. in JSON | `invalid number` |
| `tru`, `nul`, etc. | `invalid literal` |
| Unterminated JSON string | `unterminated string` |
| Bad escape in JSON string | `invalid string escape` |
| `json/stringify` called on a non-JSON value | `json/stringify does not support <type>` where `<type>` ∈ `nil`, `list`, `pair`, `function`, `macro`, `builtin`, `symbol`, `keyword` |

**let (stdlib)**

| Condition | Substring |
|---|---|
| `(let x body)` — bindings not a vector | `let bindings must be a vector` |
| `(let [x] body)` — odd bindings | `let requires an even number of binding forms` |
| `(let ["x" 1] body)` / `(let [:x 1] body)` | `let binding name must be a symbol` |

### Test Harness

The spec is tested via `.lisp` files using these forms (implemented as special forms in the test runner):

- `(test "name" body...)` — isolated test block
- `(assert/equal actual expected)` — deep equality assertion
- `(assert/throws (fn [] expr) "substring")` — error assertion

File structure: a test file is a sequence of top-level forms. Forms that are `(test …)` blocks are collected as tests; anything else is a **file prelude** (e.g. `(require "stdlib.lisp")`, `(def shared-helper …)`, `(defn helper […] …)`).

Isolation rules:
- Each test runs in a fresh root environment; `def` targets that root — even when called from a nested function or a loaded file — so bindings never leak across tests
- `require` cache and `gensym` counter reset between tests
- The file prelude re-evaluates before each `(test …)` in the file (`beforeEach` semantics). This lets you lift shared `require`/`def`/`defn` to the top of a file while preserving per-test isolation. A top-level `(require "stdlib.lisp")` therefore fires once per test, not once per file.
