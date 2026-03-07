(test "let requires a bindings vector"
  (assert/throws (fn [] (let x (+ x 1))) "let bindings must be a vector")
  (assert/throws (fn [] (let {:x 1} x)) "let bindings must be a vector"))

(test "let bindings must have even forms"
  (assert/throws (fn [] (let [x] x)) "let requires an even number of binding forms")
  (assert/throws (fn [] (let [x 1 y] (+ x y))) "let requires an even number of binding forms"))

(test "let binding names must be symbols"
  (assert/throws (fn [] (let ["x" 1] 1)) "let binding name must be a symbol")
  (assert/throws (fn [] (let [:x 1] 1)) "let binding name must be a symbol")
  (assert/throws (fn [] (let [[x] 1] 1)) "let binding name must be a symbol"))
