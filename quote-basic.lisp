(test "quote returns forms without evaluation"
  (assert/equal (print (quote (+ 1 2))) "(+ 1 2)")
  (assert/equal (print (quote [1 2 3])) "[1 2 3]")
  (assert/equal (print (quote {:a 1 :b 2})) "{:a 1 :b 2}"))

(test "quote preserves symbols"
  (assert/equal (print (quote x)) "x")
  (assert/equal (print (quote :user)) ":user"))
