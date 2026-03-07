(test "require evaluates once and uses global cache"
  (def require_once_count 0)
  (assert/equal (require "fixtures/require/once.lisp") "require-once-loaded")
  (assert/equal require_once_count 1)
  (assert/equal (require "fixtures/require/once.lisp") "require-once-loaded")
  (assert/equal require_once_count 1))

(test "require resolves paths relative to caller file"
  (def require_nested_count 0)
  (assert/equal (require "fixtures/require/nested/parent.lisp") "require-nested-parent-loaded")
  (assert/equal require_nested_count 1)
  (assert/equal require_nested_value 9))

(test "require works with defmacroonce modules"
  (def require_macro_count 0)
  (assert/equal (require "fixtures/require/macro-once.lisp") "require-macro-once-loaded")
  (assert/equal require_macro_count 1)
  (assert/equal (macro/inc2 3) 5)
  (assert/equal (require "fixtures/require/macro-once.lisp") "require-macro-once-loaded")
  (assert/equal require_macro_count 1)
  (assert/equal (macro/inc2 4) 6))
