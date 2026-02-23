# s-spec Design Document

> A minimal, embeddable Lisp DSL for validating and conforming JSON values.
> A tip of the hat to s-expressions and Clojure Spec.

---

## 1. Rationale

JSON is the lingua franca of modern APIs, but validating it well is surprisingly hard. The tools available today each make a significant tradeoff:

**JSON Schema** is, at its core, a constraint and validation system over JSON values — closer in spirit to Clojure Spec than to a type system. It does not describe _types_, it describes _rules_. A JSON Schema says "this value must be a string matching this pattern and have these properties" — that is validation, not typing.

The problem is that almost nobody uses it that way. Code generators, UI form builders, and OpenAPI tooling have collectively decided that JSON Schema is a type encoding, and most developers have absorbed that assumption. The result is a category error baked into the ecosystem: people reach for JSON Schema when they want to share types across language boundaries, find it awkward and limited for that purpose, and conclude that JSON Schema is just bad — when really it is being asked to do something it was not built to do.

The spec has also grown significantly more complex over time — partly driven by the needs of ecosystem tools like OpenAPI that wanted richer schema composition. Starting with Draft 2019-09, JSON Schema introduced annotation-dependent validation and dynamic references, features which a 2024 academic paper formally proved make validation PSPACE-complete, up from the polynomial complexity of earlier drafts. The result is a spec that is harder to implement, harder to reason about, and harder to write — without feeling more expressive to the everyday schema author.

Let validation be validation again.

**Type generators (OpenAPI, Prisma, GraphQL codegen)** move the schema to a different format and generate host-language types from it. This creates a brittle pipeline: schema → generated types → mapping code. The schema is nominally the source of truth, but you are always working with a lossy derivative. When the API changes, the whole pipeline breaks. The generated types rarely match your domain model, so you end up writing mapping code on top of generated code, which is the worst of both worlds.

**Host-language validation libraries (Zod, Valibot, Yup, io-ts)** are expressive and ergonomic within their host language, but are not portable. A schema written in Zod cannot be shared with a Go service or a Python script. Each language reinvents the same wheel with slightly different ergonomics.

**s-spec** takes a different approach. It is a small, purpose-built language — a Lisp — whose only job is to describe constraints on JSON values. It is designed to be embedded in any host language. The schema is a string. Parsing that string produces a program. That program can validate arbitrary JSON, explain validation errors in host-idiomatic ways, and — most importantly — _conform_ JSON into navigable, type-safe values without a code generation step.

The core insight borrowed from Clojure Spec is: **validation and parsing are the same operation**. You should not validate data and then re-interpret it. You should parse it once at the boundary and get back something you can trust. s-spec calls this operation `conform`.

---

## 2. Goals

**Primary goals:**

- A small, readable syntax for expressing constraints on JSON shapes, scalars, and compositions thereof.
- A language-neutral DSL: one schema string works in TypeScript, Go, Python, Rust, or any other host.
- A `validate` function that returns structured, serializable errors with a common schema across all hosts.
- A `conform` function that validates and returns a navigable, typed wrapper — parse, don't validate.
- An `explain` function that translates validation errors into human-readable messages suitable for UIs and exception handlers.

**Non-goals (for now):**

- Generating host-language types from specs.
- Generating JSON from specs (the reverse direction).
- A general-purpose Lisp runtime.
- Complex module systems with dependency management, versioning, or package registries.
- Namespaces as a first-class language feature — code organization should use naming conventions (e.g., `email/validator` symbols).
- JSONPath support in `ConformedNode.get()` — single-key access only for now. Path traversal would propagate null through optional absences and throw `AccessError` on required absences, jq-style.

**Basic file loading is in scope:**

A simple `load` function allows splitting large specs across multiple files. Files are loaded relative to the loading file and evaluated once per session (idempotent). All definitions from loaded files share the global environment. For code organization, use naming conventions in symbol names (e.g., `user/email-validator`, `common/string-checks`) rather than true namespaces.

---

## 3. Design Principles

**The spec is a value.** A parsed spec is a first-class runtime object. You can pass it around, store it, compose it with other specs. It is not a type annotation that disappears at compile time.

**Permissive input, strict output.** `conform` validates the entire document eagerly, but only the parts of the spec you declare matter. Extra fields in the JSON are ignored. After `conform`, everything downstream can trust what it receives.

**Parse, don't validate.** The pattern from Alexis King's essay: untrusted data should be parsed into trusted types at the boundary, not validated and re-used in raw form. `conform` is that boundary operation.

**Errors are data.** Validation errors serialize to a common structure across all host languages. How those errors are _surfaced_ (exceptions, Result types, error returns) is up to each host. The underlying error data is the same.

**The DSL is a library, not a mode.** s-spec is a Lisp with one evaluation model. Validator forms like `(>= 18)` and `(and ...)` are ordinary function calls that return validator objects. `fn` and `defn` are ordinary functions. There is no context switch — the DSL feel comes from the standard library. Reader macros handle syntactic sugar (`?foo`, `.foo`) before evaluation.

---

## 4. Language Reference

### 4.1 Evaluation Model

s-spec is a Lisp. There is one evaluation model: expressions. The DSL feel comes from the standard library, not the evaluator.

`(>= 18)` is a normal function call. It returns a validator object — a value that knows how to check whether a number is greater than or equal to 18. `(and int32 (>= 18))` is also a normal function call, composing two validators into one. `rule` and `spec` bind names to validators, just as `def` binds names to any value. There is no mode switch, no pattern matching on form shapes by the evaluator, no special interpretation of forms depending on where they appear.

`fn` and `defn` are likewise ordinary — they define functions. A predicate passed to a validator is just a function that returns a boolean. The "escape hatch" framing in earlier drafts was misleading: you are always in the same language.

**Reader macros** handle syntactic sugar before evaluation. The reader transforms shorthand forms into their canonical s-expression equivalents:

| Sugar  | Expands to         |
| ------ | ------------------ |
| `?foo` | `(? .foo)`         |
| `.foo` | `(accessor "foo")` |

This keeps map literals scannable while preserving homoiconicity — `?` is a real composable operator, not a special token the evaluator has to recognize.

### 4.2 Binding Forms

```clojure
;; def: bind a name to any value
(def max-age 150)
(def email-regex (re "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$"))

;; defn: define a named function
(defn adult? [v] (>= v 18))

;; rule: bind a name to a validator (implicit `and` over multiple arguments)
(rule age int32 (>= 18))
;; equivalent to:
(rule age (and int32 (>= 18)))

;; spec: bind a name to a validator, marking it as a composition root
(spec person
  { .id        id
    .firstName string
    .lastName  string
    ?age       age })
```

`rule` and `spec` are mechanically the same — both define named validators. The distinction is semantic: `spec` marks a validator as a **composition root** — a shape intended to be passed directly to `conform` as an entry point. `rule` defines a building block. A well-structured schema reads like a pyramid: `rule`s at the base, one or more `spec`s at the top. Nothing enforces this, but tooling and documentation assume it.

### 4.3 Object Shapes

Object shapes are written as map literals inside `spec` bodies.

```clojure
(spec address
  { .street  string
    .city    string
    .zip     string
    .country string })
```

**Property accessors:**

- `.foo` — required property named `foo`
- `?foo` — optional property named `foo` (reader macro for `(? .foo)`)
- `."I'm a weird key"` — required property with a quoted name (for keys containing special characters)
- `?"I'm a weird key"` — optional, quoted

### 4.4 Composition

```clojure
;; and: value must satisfy all constraints (implicit when multiple are listed)
(rule username string (min-len 3) (max-len 20) (re "^[a-z0-9_]+$"))
;; equivalent:
(rule username (and string (min-len 3) (max-len 20) (re "^[a-z0-9_]+$")))

;; or: value must satisfy at least one constraint
;; Tags are optional but all-or-nothing — if any branch is tagged, all must be.
;; Without tags, or works for validate but :tag is unavailable on conform.
(spec entity
  { .id (or int32 string) })

;; Tagged or — :tag is available on the conformed node
(spec entity
  { .id (or :int int32 :str string) })

;; not: value must not satisfy the constraint
(rule not-banned (and string (not "67")))
```

### 4.5 Arrays

```clojure
;; Array of persons, at most 100 elements
(spec person
  { ?friends [person :max 100] })

;; Array of strings, at least 1 element
{ .tags [string :min 1] }

;; Array with both bounds
{ .scores [number :min 1 :max 10] }
```

### 4.6 Matching (Discriminated Unions)

`match` is the primitive for discriminated unions — the hard case in JSON schema.

The accessor (e.g. `.type`) is itself a predicate. If the property is absent, null punning applies: the match does not fire and the whole `match` form is silently skipped. This means `match` composes naturally with optional fields without needing explicit null checks.

The match arms are also predicates — not just string literals. A string literal like `"person"` is shorthand for an equality predicate, but any rule works as a discriminator. This means you can match on types, ranges, regex patterns, or any named rule.

Match arms are evaluated in order. The first arm whose predicate matches wins.

**Tags** are optional but all-or-nothing: if any arm has a tag, all arms must have one (including `:else`). Tags allow `conform` to report which branch fired via `:tag` on the resulting node. Without tags, `:tag` is unavailable.

```clojure
;; Classic discriminated union — string literal arms are equality predicates
(spec entity
  (match .type
    "person"  person-spec
    "company" company-spec
    :else     generic-spec))

;; Tagged arms — .tag is available on the conformed node
(spec response
  (match .status
    :error   (>= 400)  error-spec
    :success (>= 200)  success-spec
    :unknown :else     unknown-spec))

;; Any rule works as a match arm, not just string literals
(spec response
  (match .status
    (>= 400)  error-spec      ;; predicate arm
    (>= 200)  success-spec    ;; predicate arm
    :else     unknown-spec))

;; Nil punning: if .role is absent, this match is skipped entirely
(spec { .payload (and user-spec (match .role "admin" admin-extra)) })

;; Match can be composed with and for staged validation
(spec entity
  common-fields-spec           ;; Stage 1: must have id, timestamp, etc.
  (match .type                 ;; Stage 2: based on .type, apply more rules
    "person"  person-spec
    "company" company-spec))
```

On the conform side, tagged match arms expose `.tag`:

```typescript
const response = program.conform(json);
const node = response.get("status");

switch (node.tag) {
  case "error":
    return node.get("message").string;
  case "success":
    return node.get("data").raw;
  case "unknown":
    break;
}
```

### 4.7 Custom Predicates

For constraints the standard library cannot express, define a predicate with `defn`. A predicate is a function that takes a value and returns a boolean. Predicates compose with validators naturally — they are just values.

```clojure
;; Simple predicate
(defn adult? [v] (>= v 18))
(rule age int32 adult?)

;; Cross-field predicate (receives the whole object)
(defn valid-range? [obj]
  (< (+ (get obj "min") 10) (get obj "max")))

(spec range-spec
  { .min number
    .max number }
  valid-range?)
```

### 4.8 Regex

s-spec uses [I-regexp](https://www.rfc-editor.org/rfc/rfc9485) — the Interoperable Regular Expression format — to ensure regex patterns work across all host languages.

```clojure
(def slug-re (re "^[a-z0-9-]+$"))
(rule slug string slug-re)

;; inline
(rule username string (re "^[a-z0-9_]+$"))
```

### 4.9 Comments

```clojure
;; This is a comment
```

### 4.10 Standard Library

**Scalar types:**

| Name      | Description                        |
| --------- | ---------------------------------- |
| `boolean` | JSON boolean                       |
| `null`    | JSON null                          |
| `number`  | Any JSON number                    |
| `int32`   | Integer in the range −2³¹ to 2³¹−1 |
| `int64`   | Integer in the range −2⁶³ to 2⁶³−1 |
| `float64` | 64-bit floating point              |
| `string`  | Any JSON string                    |

**String formats:**

| Name               | Description                        |
| ------------------ | ---------------------------------- |
| `string/uuid`      | UUID (RFC 4122)                    |
| `string/date`      | Date (RFC 3339 full-date)          |
| `string/date-time` | Date-time (RFC 3339)               |
| `string/time`      | Time (RFC 3339 partial-time)       |
| `string/duration`  | Duration (ISO 8601)                |
| `string/ipv4`      | IPv4 address                       |
| `string/ipv6`      | IPv6 address                       |
| `string/base64`    | Base64-encoded bytes               |
| `string/int32`     | String representation of an int32  |
| `string/int64`     | String representation of an int64  |
| `string/float64`   | String representation of a float64 |

**Constraint predicates:**

| Name           | Applies to    | Description              |
| -------------- | ------------- | ------------------------ |
| `(>= n)`       | number        | Value ≥ n                |
| `(<= n)`       | number        | Value ≤ n                |
| `(> n)`        | number        | Value > n                |
| `(< n)`        | number        | Value < n                |
| `(min-len n)`  | string, array | Length ≥ n               |
| `(max-len n)`  | string, array | Length ≤ n               |
| `(re pattern)` | string        | Matches I-regexp pattern |

### 4.11 Naming Conventions

**Private/internal definitions:**

Functions and macros prefixed with `__` (double underscore) are internal implementation details and should not be used directly:

- `__cond-helper` — internal helper for the `cond` macro
- `__array-eq`, `__array-eq-iter` — internal helpers for array equality
- `__object-eq`, `__object-eq-iter` — internal helpers for object equality

These are exported in the global namespace for implementation reasons but are not part of the public API and may change without notice.

**Why not true privacy?**

s-spec deliberately avoids complex module systems or namespaces. The `__` prefix is a lightweight convention that signals intent without requiring language-level privacy enforcement. This keeps the implementation simple while maintaining clear boundaries between public API and internal helpers.

---

## 5. Error Model

Validation errors are structured data with a common serialization format across all host languages.

### 5.1 Error Document

```typescript
interface ValidationError {
  path: string; // JSONPath to the failing value, e.g. "$.person.age"
  rule: string; // The rule or constraint that failed, e.g. "int32"
  message: string; // Human-readable explanation
  value?: unknown; // The actual value that failed (optional)
}
```

A validation result is either a success or a list of one or more `ValidationError` objects.

### 5.2 Host Idioms

Each host language surfaces these errors in its own idiomatic way:

```typescript
// TypeScript: throws or returns a Result depending on preference
const result = program.validate(json);
if (!result.ok) {
  console.log(result.errors); // ValidationError[]
}
```

```go
// Go: multiple return values
errors, err := program.Validate(json)
```

```rust
// Rust: Result type
let result: Result<(), Vec<ValidationError>> = program.validate(&json);
```

The underlying `ValidationError` objects serialize to the same JSON structure in every host, enabling cross-language error reporting.

---

## 6. Host Language API — TypeScript Reference

### 6.1 Core API

```typescript
import { parse } from "s-spec";

const spec = `
  (spec person
    { .id         string/uuid
      .firstName  string
      .lastName   string
      .email      email
      ?age        (and int32 (>= 18))
      ?friends    [person :max 100] })
`;

// Parse the spec string into a program
const program = parse(spec); // throws ParseError if spec is invalid

// Validate raw JSON
const result = program.validate(json);
if (!result.ok) {
  console.log(program.explain(result.errors)); // human-readable string
}

// Conform: parse at the boundary, extract typed values immediately
const person = program.conform(json); // always succeeds for valid JSON
```

### 6.2 The Conformed Tree

`conform` returns a `ConformedNode` — a wrapper around the validated JSON that knows which spec governs each of its descendants.

**Important: `ConformedNode` is a boundary tool, not a data carrier.** The intended pattern is to conform at the edge of your system — when data arrives from the network, a file, or a database — extract plain typed values immediately, and pass those values into the rest of your application. This is "parse, don't validate": after the boundary, your app works with trusted native values and never needs to re-check them.

```typescript
// ✅ Correct: conform at the boundary, return plain values
async function fetchUser(id: string): Promise<User> {
  const r = await fetch(`/users/${id}`);
  const d = await r.json();
  const c = program.conform(d);
  return {
    email: c.get("email").string,
    age: c.get("age").number ?? null,
    createdAt: c.get("createdAt").Date,
  };
}

// ❌ Wrong: passing ConformedNode into the rest of the app
async function fetchUser(id: string): Promise<ConformedNode> {
  const r = await fetch(`/users/${id}`);
  const d = await r.json();
  return program.conform(d); // caller still has to know how to read it
  // errors surface late, far from the source
  // this is just validate() with extra steps
}
```

Once you return a plain `User` object, the rest of your application is working with trusted data. No more validation, no more spec knowledge required downstream.

```typescript
// .get() returns a ConformedNode for the property
// If the property is absent and optional, typed accessors return null
// If the property is absent and required (per spec), throws AccessError
const node = person.get("createdAt");

// Typed accessors — always return `T | null`.
// null means the property was absent (only possible for optional fields).
// Throws AccessError if the value is present but fails its rule.
const str = node.string; // string | null
const date = node.Date; // Date | null   — rule must be string/date-time
const num = node.number; // number | null
const bool = node.boolean; // boolean | null

// The raw JSON value, uncoerced
const value = node.raw; // unknown

// .required asserts presence at the call site, independent of the spec.
// Use this when you know a field must be present and want to be explicit.
// If the field is absent (optional per spec), throws AssertionError — a
// programming error, not a validation error. Does not affect required fields
// (those already throw AccessError on absence regardless).
const email = person.get("email").required.string; // string (never null)

// Arrays
const friends = person.get("friends"); // ConformedArrayNode | null
for (const friend of friends ?? []) {
  console.log(friend.get("firstName").string);
}
```

**Error taxonomy for absent fields:**

| Field declared in spec | Accessor used      | Result                                                  |
| ---------------------- | ------------------ | ------------------------------------------------------- |
| Required (`.email`)    | `.string`          | `AccessError` (validation failure — bad data)           |
| Optional (`?email`)    | `.string`          | `null`                                                  |
| Optional (`?email`)    | `.required.string` | `AssertionError` (programming error — wrong assumption) |

`AccessError` carries a `ValidationError` and is part of the validation error model. `AssertionError` is not — it signals a bug in the calling code, not a problem with the data. Callers can catch them separately.

### 6.3 Eager Validation

`conform(json)` runs all validators immediately and stores the results in an internal `Map<path, ValidationError[]>`. There is no lazy evaluation or deferred validation — the entire document is validated upfront.

Typed accessors (`.string`, `.number`, etc.) perform a path lookup into this map. If an error is recorded for that path, they throw `AccessError`. If the field is absent and required per the spec, they throw `AccessError`. Otherwise they return the typed value or `null`.

This means:

- `conform()` itself never throws on a valid JSON value. The only early failure is a `ParseError` if the input is not valid JSON at all.
- All validation work happens once, at the boundary. Accessor calls are cheap map lookups.
- `validate()` and `conform()` agree on what the errors are — they share the same validation pass.

### 6.4 Error Handling

```typescript
// ParseError: the spec string itself is invalid
try {
  const program = parse(badSpec);
} catch (e: ParseError) {
  console.log(e.message); // describes the syntax error
  console.log(e.line); // line number in the spec string
  console.log(e.column); // column number
}

// ParseError: conform() only throws if json is not a valid JSON value
try {
  const node = program.conform(notJson);
} catch (e: ParseError) {
  console.log(e.message);
}

// ValidationResult: validate() never throws
const result = program.validate(json);
result.ok; // boolean
result.errors; // ValidationError[] (empty if ok)

// conform() itself never throws on a valid JSON value
const person = program.conform(json);

// AccessError: thrown when a required field is absent, or a value fails its rule.
// This is a validation failure — the data is wrong.
try {
  const age = person.get("age").number; // fails int32 >= 18
} catch (e: AccessError) {
  console.log(e.error); // ValidationError
  console.log(program.explain([e.error])); // human-readable
}

// Typed accessors return T | null — null means the field was absent (optional).
const age = person.get("age").number; // number | null
const email = person.get("email").string; // string | null

// AssertionError: thrown by .required when the field is absent.
// This is a programming error — the caller made a wrong assumption.
// It is NOT a ValidationError and is not part of the validation error model.
try {
  const email = person.get("optionalEmail").required.string;
} catch (e: AssertionError) {
  // caller assumed optionalEmail was present; it was not
}
```

### 6.5 Explain

`explain` translates `ValidationError[]` into a human-readable string suitable for display in a UI or an exception message.

```typescript
const message = program.explain(errors);
// "person.age: expected int32 >= 18, got \"seventeen\""
// "person.email: expected string matching ^[a-zA-Z0-9._%+-]+@..., got \"not-an-email\""
```

Each host may provide its own `explain` formatting. The contract is: given the common `ValidationError` structure, produce a string. The format is not standardized across hosts — `explain` is for humans, not machines.

---

## 7. Full Example

```clojure
;; schema.sspec

(def email-regex (re "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$"))

(rule id       string/uuid)
(rule email    string email-regex)
(rule username string (min-len 3) (max-len 20) (re "^[a-z0-9_]+$"))
(rule age      int32 (>= 18))

(spec address
  { .street  string
    .city    string
    .zip     string
    .country string })

(spec person
  { .id        id
    .username  username
    .email     email
    ?age       age
    ?address   address
    ?friends   [person :max 100] })

(spec api-response
  (match .type
    "person"  person
    :else     { .error string }))
```

```typescript
import { parse } from "s-spec";
import { readFileSync } from "fs";

const program = parse(readFileSync("schema.sspec", "utf8"));

// validate
const result = program.validate(responseJson);
if (!result.ok) {
  throw new Error(program.explain(result.errors));
}

// conform and use
const response = program.conform(responseJson);
const type = response.get("type").required.string; // AssertionError if absent
const username = response.get("username").required.string;
const age = response.get("age").number ?? null; // number | null (optional field)
const joined = response.get("createdAt").Date; // Date | null

// nested navigation
const firstFriend = response.get("friends").at(0);
const friendName = firstFriend.get("username").string;
```

---

## 8. Implementation Notes

### 8.1 Parser

The parser has two stages. The **reader** handles tokenization and desugars reader macros (`?foo` → `(? .foo)`, `.foo` → `(accessor "foo")`) before producing an AST. The **parser** is a recursive descent parser over the resulting s-expression grammar. The AST is the basis for both the validator compiler and any future tooling (formatters, linters, language servers).

### 8.2 Validator Compilation

The AST is compiled by a standard Lisp evaluator against the s-spec standard library. Validator functions, composition operators, and predicates are all ordinary values. Each validator is a function `(value, context) => ValidationError[]`. `rule` and `spec` definitions are stored in a registry keyed by name.

Custom predicates (`defn`) require a small Lisp interpreter to evaluate function bodies. This is an optional extension — a minimal host implementation can support the full standard library without implementing `fn`/`defn`.

### 8.3 Conform

`conform(json)` parses the JSON value and immediately runs all validators over the entire document, storing results in a `Map<path, ValidationError[]>` keyed by JSONPath string. Cross-field validators receive the whole object and are run once per object node. The resulting `ConformedNode` wraps both the raw JSON and this error map. Typed accessor calls are path lookups into the map — no re-evaluation occurs.

### 8.4 Portability

The core of s-spec — the parser, the validator compiler, and the conform runtime — should be implementable in any language with:

- A string parser
- First-class functions or closures
- A hash map

Custom predicates (`fn`/`defn`) require a small Lisp interpreter and are an optional extension. A minimal host implementation can support the full standard library without implementing function evaluation.

---

## 9. What s-spec Is Not

- It is not a code generator. It does not produce TypeScript types, Go structs, or Rust enums.
- It is not a serialization format. It does not replace Protocol Buffers or MessagePack.
- It is not a general-purpose language. `fn`/`defn` are a limited extension for custom predicates, not a platform.
- It is not a replacement for JSON Schema in contexts where JSON Schema interoperability is required.

---

## 10. Prior Art and Influences

- **Clojure Spec** — the primary inspiration. The `conform` API, the treatment of schemas as values, the separation of validation from typing.
- **Alexis King, "Parse, Don't Validate"** — the philosophical foundation for `conform`.
- **JSON Schema** — the incumbent we are reacting against. We borrow its vocabulary (formats, constraints) while rejecting its syntax.
- **Zod / Valibot** — host-language libraries that demonstrate the demand for expressive, composable schema definitions.
- **I-regexp (RFC 9485)** — the regex portability standard we adopt wholesale.
