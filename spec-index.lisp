(test "spec index exists"
  (assert/equal true true))

(def spec/index
  {:core
   ["basic.lisp"
    "boolean-basic.lisp"
    "list-basic.lisp"
    "array-basic.lisp"
    "object.lisp"
    "function-basic.lisp"
    "function-docs.lisp"
    "def-basic.lisp"
    "def-errors.lisp"
    "defonce-basic.lisp"
    "defonce-errors.lisp"
    "let-basic.lisp"
    "let-errors.lisp"
    "let-derived-form.lisp"
    "if-basic.lisp"
    "if-errors.lisp"
    "do-basic.lisp"
    "logic-basic.lisp"
    "equality-basic.lisp"
    "equality-mixed-types.lisp"]

   :reader
   ["parser-basic.lisp"
    "parser-errors.lisp"
    "reader-comments-basic.lisp"
    "reader-macros-basic.lisp"
    "reader-macros-errors.lisp"]

   :quote-macro
   ["quote-basic.lisp"
    "quasiquote-basic.lisp"
    "quote-quasiquote-edge.lisp"
    "macro-basic.lisp"
    "defmacroonce-basic.lisp"
    "defmacroonce-errors.lisp"
    "macroexpand-basic.lisp"
    "macro-errors.lisp"
    "macro-style.lisp"
    "macro-style-errors.lisp"
    "gensym-basic.lisp"]

   :json
   ["json-boundary-basic.lisp"
    "json-boundary-errors.lisp"
    "json-roundtrip.lisp"]

   :modules
   ["load-basic.lisp"
    "load-errors.lisp"
    "require-basic.lisp"
    "require-errors.lisp"
    "stdlib-basic.lisp"
    "defn-basic.lisp"
    "defn-errors.lisp"]

   :contracts
   ["language-contract.lisp"]})
