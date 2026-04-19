(test "bound? returns false for undefined symbols"
  (assert/equal (bound? 'never-defined) false))

(test "bound? returns true for defined symbols"
  (def defined-value 42)
  (assert/equal (bound? 'defined-value) true))

(test "bound? is a presence check, not a truthiness check"
  (def nil-value nil)
  (def false-value false)
  (assert/equal (bound? 'nil-value) true)
  (assert/equal (bound? 'false-value) true))

(test "bound? walks the lexical chain"
  (require "stdlib.lisp")
  (assert/equal
    (let [local-x 1] (bound? 'local-x))
    true)
  (assert/equal
    ((fn [param-y] (bound? 'param-y)) 7)
    true))

(test "bound? returns false outside the binding scope"
  (require "stdlib.lisp")
  (let [transient 1] transient)
  (assert/equal (bound? 'transient) false))

(test "bound? rejects non-symbol arguments"
  (assert/throws (fn [] (bound? 42)) "requires a symbol")
  (assert/throws (fn [] (bound? "x")) "requires a symbol")
  (assert/throws (fn [] (bound? :x)) "requires a symbol")
  (assert/throws (fn [] (bound? nil)) "requires a symbol"))
