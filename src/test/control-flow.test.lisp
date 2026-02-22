; Control flow tests ported from control-flow.test.ts

(test "not - logical negation"
  (assert/equal (not true) false)
  (assert/equal (not false) true)
  (assert/equal (not nil) true)
  (assert/equal (not 0) false)
  (assert/equal (not 1) false)
  (assert/equal (not 42) false)
  (assert/equal (not -1) false)
  (assert/equal (not "") false)
  (assert/equal (not "hello") false))

(test "not - composition"
  (assert/equal (not (and true false)) true)
  (assert/equal (not (or false nil)) true)
  (assert/equal (and (not false) true) true))

(test "not - wrong arity"
  (assert/throws (fn [] (not)) "Expected 1 args, got 0")
  (assert/throws (fn [] (not true false)) "Expected 1 args, got 2"))

(test "if - basic conditionals"
  (assert/equal (if true 1 2) 1)
  (assert/equal (if false 1 2) 2))

(test "if - truthy values"
  (assert/equal (if 1 "yes" "no") "yes")
  (assert/equal (if 0 "yes" "no") "yes")
  (assert/equal (if "" "yes" "no") "yes")
  (assert/equal (if "hello" "yes" "no") "yes"))

(test "if - falsy values"
  (assert/equal (if nil "yes" "no") "no")
  (assert/equal (if false "yes" "no") "no"))

(test "if - without else clause"
  (assert/equal (if true 42) 42)
  (assert/equal (if false 42) nil))

(test "if - with expressions"
  (assert/equal (if (> 5 3) (+ 1 2) (- 10 5)) 3)
  (assert/equal (if (< 5 3) (+ 1 2) (- 10 5)) 5))

(test "if - nested conditionals"
  (assert/equal (if true (if false 1 2) 3) 2))

(test "if - with variable binding"
  (def x 10)
  (assert/equal (if (> x 5) (* x 2) (/ x 2)) 20))

(test "if - lazy evaluation"
  (def x 5)
  (assert/equal (if true x y) 5)
  (assert/equal (if false y x) 5))

(test "if - wrong arity"
  (assert/throws (fn [] (if)) "if requires 2 or 3 arguments")
  (assert/throws (fn [] (if true)) "if requires 2 or 3 arguments")
  (assert/throws (fn [] (if true 1 2 3)) "if requires 2 or 3 arguments"))

(test "recursive - factorial"
  (defn factorial [n]
    (if (= n 0)
      1
      (* n (factorial (- n 1)))))
  (assert/equal (factorial 5) 120))

(test "recursive - fibonacci"
  (defn fib [n]
    (if (<= n 1)
      n
      (+ (fib (- n 1)) (fib (- n 2)))))
  (assert/equal (fib 6) 8))

(test "recursive - sum to n"
  (defn sum-to [n]
    (if (= n 0)
      0
      (+ n (sum-to (- n 1)))))
  (assert/equal (sum-to 10) 55))

(test "recursive - countdown"
  (defn countdown [n]
    (if (= n 0)
      nil
      (countdown (- n 1))))
  (assert/equal (countdown 3) nil))
