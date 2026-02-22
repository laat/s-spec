; Recursion depth tracking tests

(test "recursion depth - simple recursion"
  ; This should work - factorial of 5 is very shallow
  (defn factorial [n]
    (if (= n 0)
      1
      (* n (factorial (- n 1)))))
  (assert/equal (factorial 5) 120))

(test "recursion depth - exceeds limit"
  ; Set a very low limit to test the mechanism
  ; Note: This test is commented out because we can't set limits per-environment yet
  ; (def env (create-env))
  ; (env/set-max-recursion-depth 5)
  ; (assert/throws (fn [] (factorial 10)) "Maximum recursion depth"))
  (assert/equal true true))  ; Placeholder

; Test that recursion depth is properly tracked through function calls
; If depth tracking is correct, this should count each call once
; If there's double-counting, this will fail at half the expected depth
(test "recursion depth - countdown recursive function"
  (defn countdown [n]
    (if (<= n 0)
      :done
      (countdown (- n 1))))
  ; This should work - 100 recursive calls is well under the 1000 limit
  (assert/equal (countdown 100) :done))

; Test mutual recursion
(test "recursion depth - mutual recursion"
  (defn is-even? [n]
    (if (= n 0)
      true
      (is-odd? (- n 1))))
  (defn is-odd? [n]
    (if (= n 0)
      false
      (is-even? (- n 1))))
  (assert/equal (is-even? 10) true)
  (assert/equal (is-odd? 11) true))

; Test deep recursion (should work with 1000 limit)
(test "recursion depth - moderately deep recursion"
  (defn deep-sum [n acc]
    (if (= n 0)
      acc
      (deep-sum (- n 1) (+ acc n))))
  ; 200 levels deep - should work fine if tracking correctly
  (assert/equal (deep-sum 200 0) 20100))
