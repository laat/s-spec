; Comparison operator tests ported from comparison.test.ts

(test "equality (=)"
  (assert/equal (= 1 1) true)
  (assert/equal (= 1 2) false)
  (assert/equal (= "a" "a") true)
  (assert/equal (= "a" "b") false)
  (assert/equal (= 1 1 1) true)
  (assert/equal (= 1 1 2) false)
  (assert/equal (= "x" "x" "x") true))

(test "greater than (>)"
  (assert/equal (> 5 3) true)
  (assert/equal (> 3 5) false)
  (assert/equal (> 5 5) false)
  (assert/equal (> 5 3 1) true)
  (assert/equal (> 5 3 4) false)
  (assert/equal (> 10 5 3 1) true))

(test "less than (<)"
  (assert/equal (< 3 5) true)
  (assert/equal (< 5 3) false)
  (assert/equal (< 5 5) false)
  (assert/equal (< 1 3 5) true)
  (assert/equal (< 1 3 2) false)
  (assert/equal (< 1 3 5 10) true))

(test "greater than or equal (>=)"
  (assert/equal (>= 5 3) true)
  (assert/equal (>= 5 5) true)
  (assert/equal (>= 3 5) false)
  (assert/equal (>= 5 5 3 1) true)
  (assert/equal (>= 5 3 4) false))

(test "less than or equal (<=)"
  (assert/equal (<= 3 5) true)
  (assert/equal (<= 5 5) true)
  (assert/equal (<= 5 3) false)
  (assert/equal (<= 1 1 3 5) true)
  (assert/equal (<= 1 3 2) false))
