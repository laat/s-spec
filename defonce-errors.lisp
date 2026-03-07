(test "defonce requires a symbol name"
  (assert/throws (fn [] (defonce "x" 1)) "defonce name must be a symbol")
  (assert/throws (fn [] (defonce :x 1)) "defonce name must be a symbol")
  (assert/throws (fn [] (defonce [x] 1)) "defonce name must be a symbol"))

(test "defonce requires exactly two arguments"
  (assert/throws (fn [] (defonce x)) "defonce requires exactly two arguments")
  (assert/throws (fn [] (defonce x 1 2)) "defonce requires exactly two arguments"))
