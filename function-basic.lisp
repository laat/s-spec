(test "fn with vector params"
  (assert/equal ((fn [] 42)) 42)
  (assert/equal ((fn [x] x) 9) 9)
  (assert/equal ((fn [x y] (+ x y)) 2 3) 5))

(test "fn supports multiple body forms and returns last"
  (assert/equal
    ((fn [x]
       (+ x 1)
       (+ x 2)
       (+ x 3))
     10)
    13))

(test "fn captures lexical scope"
  (assert/equal
    ((fn [x]
       ((fn [y] (+ x y)) 5))
     7)
    12))

(test "fn arity is strict"
  (assert/throws (fn [] ((fn [x] x))) "arity mismatch")
  (assert/throws (fn [] ((fn [x] x) 1 2)) "arity mismatch")
  (assert/throws (fn [] ((fn [x y] (+ x y)) 1)) "arity mismatch"))

(test "calling non-function throws"
  (assert/throws (fn [] (1 2 3)) "requires a function")
  (assert/throws (fn [] (null 1)) "requires a function")
  (assert/throws (fn [] ([1 2] 0)) "requires a function"))
