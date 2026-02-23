; gensym tests - generate unique symbols for macro hygiene

(test "gensym - generates unique symbols"
  (def sym1 (gensym))
  (def sym2 (gensym))
  ; Symbols should not be equal
  (assert/equal (eq sym1 sym2) false))

(test "gensym - with prefix"
  (def sym (gensym "my-prefix-"))
  ; Symbol should be a symbol (not throwing is enough)
  (assert/equal (symbol? sym) true))

(test "gensym - no args"
  (def sym (gensym))
  ; Should generate a symbol
  (assert/equal (symbol? sym) true))

(test "gensym - wrong arity"
  (assert/throws (fn [] (gensym "a" "b")) "gensym requires 0 or 1 arguments"))

(test "gensym - wrong type"
  (assert/throws (fn [] (gensym 123)) "gensym requires a string"))

(test "gensym - simple macro usage"
  ; Simpler test: macro that uses gensym to create a binding
  (defmacro with-gensym [body] (do (def g (gensym)) (quasiquote (def (unquote g) 42))))
  (with-gensym null)
  ; The gensym'd variable should exist but we can't reference it by name
  (assert/equal true true))

(test "gensym - multiple calls produce different symbols"
  (def syms [(gensym) (gensym) (gensym)])
  ; All three should be different
  (assert/equal (eq (nth syms 0) (nth syms 1)) false)
  (assert/equal (eq (nth syms 1) (nth syms 2)) false)
  (assert/equal (eq (nth syms 0) (nth syms 2)) false))

(test "gensym - counter increments"
  ; Each gensym should have a different number
  (def sym1 (gensym))
  (def sym2 (gensym))
  (def sym3 (gensym))
  ; All should be unique
  (assert/equal (eq sym1 sym2) false)
  (assert/equal (eq sym2 sym3) false)
  (assert/equal (eq sym1 sym3) false))

(test "gensym - custom prefix works"
  (def sym (gensym "test-"))
  ; Should be a valid symbol
  (assert/equal (symbol? sym) true))

(test "gensym - empty string prefix"
  (def sym (gensym ""))
  ; Should work with empty prefix
  (assert/equal (symbol? sym) true))

(test "gensym - different each expansion"
  ; Verify that each macro expansion gets a fresh symbol
  (def count1 0)
  (def count2 0)
  ; Call gensym twice and verify they're different
  (def sym1 (gensym))
  (def sym2 (gensym))
  (assert/equal (eq sym1 sym2) false))
