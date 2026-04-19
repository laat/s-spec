(test "defmacroonce requires symbol name and vector params"
  (require "../../stdlib.lisp")
  (assert/throws (fn [] (defmacroonce "m" [x] x)) "defmacroonce name must be a symbol")
  (assert/throws (fn [] (defmacroonce m x x)) "defmacroonce params must be a vector"))

(test "defmacroonce requires a body"
  (require "../../stdlib.lisp")
  (assert/throws (fn [] (defmacroonce m [x])) "defmacroonce requires a body"))
