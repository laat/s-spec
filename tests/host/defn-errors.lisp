(test "defn requires symbol name and vector params"
  (require "../../stdlib.lisp")
  (assert/throws (fn [] (defn "f" [x] x)) "def name must be a symbol")
  (assert/throws (fn [] (defn f x x)) "fn params must be a vector"))

(test "defn requires a body"
  (require "../../stdlib.lisp")
  (assert/throws (fn [] (defn f [x])) "fn requires a body"))
