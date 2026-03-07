(test "if requires exactly three arguments"
  (assert/throws (fn [] (if)) "if requires exactly three arguments")
  (assert/throws (fn [] (if true 1)) "if requires exactly three arguments")
  (assert/throws (fn [] (if true 1 2 3)) "if requires exactly three arguments"))
