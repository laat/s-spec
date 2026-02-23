; Basic tests ported from basic.test.ts

(test "addition"
  (assert/equal (+ 1 2) 3)
  (assert/equal (+ 1 2 3 4) 10)
  (assert/equal (+) 0)
  (assert/equal (+ 5) 5))

(test "subtraction"
  (assert/equal (- 5 3) 2)
  (assert/equal (- 10 3 2) 5)
  (assert/equal (- 5) -5))

(test "multiplication"
  (assert/equal (* 2 3) 6)
  (assert/equal (* 2 3 4) 24)
  (assert/equal (*) 1)
  (assert/equal (* 5) 5))

(test "division"
  (assert/equal (/ 10 2) 5)
  (assert/equal (/ 20 2 2) 5)
  (assert/equal (/ 4) 0.25))

(test "nested expressions"
  (assert/equal (+ 1 (+ 2 3)) 6)
  (assert/equal (* 2 (+ 3 4)) 14)
  (assert/equal (- (* 5 4) (/ 10 2)) 15))

(test "log returns null"
  (assert/equal (log "hello") null)
  (assert/equal (log 1 2 3) null))

(test "commas as whitespace"
  (assert/equal (+ 1, 2, 3) 6)
  (assert/equal (+ 1, (+ 2, 3)) 6)
  (assert/equal (* 2, (+ 3, 4)) 14)
  (assert/equal (+ 1, 2, 3) (+ 1 2 3))
  (assert/equal (+ 1, 2 3, 4) 10))

(test "error: division by zero"
  (assert/throws (fn [] (/ 10 0)) "Division by zero"))
