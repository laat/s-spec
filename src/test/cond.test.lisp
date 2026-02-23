; Tests for cond macro

(test "cond - basic usage"
  (assert/equal
    (cond
      false 1
      true 2
      :else 3)
    2))

(test "cond - first match wins"
  (assert/equal
    (cond
      true 1
      true 2
      :else 3)
    1))

(test "cond - else clause"
  (assert/equal
    (cond
      false 1
      false 2
      :else 3)
    3))

(test "cond - no else, no match returns null"
  (assert/equal
    (cond
      false 1
      false 2)
    null))

(test "cond - empty cond returns null"
  (assert/equal (cond) null))

(test "cond - with expressions"
  (def x 5)
  (assert/equal
    (cond
      (< x 0) "negative"
      (> x 0) "positive"
      :else "zero")
    "positive"))

(test "cond - null and false are falsy"
  (assert/equal
    (cond
      null 1
      false 2
      :else 3)
    3))

(test "cond - truthy values (0 and empty string)"
  (assert/equal
    (cond
      0 "zero"
      :else "other")
    "zero")
  (assert/equal
    (cond
      "" "empty"
      :else "other")
    "empty"))

(test "cond - side effects evaluated only once"
  (def counter 0)
  (cond
    true (def counter (+ counter 1))
    true (def counter (+ counter 10))
    :else (def counter (+ counter 100)))
  (assert/equal counter 1))

(test "cond - short-circuit evaluation"
  (def counter 0)
  (cond
    true (def counter 1)
    (do (def counter 10) true) 2
    :else 3)
  (assert/equal counter 1))

(test "cond - with arithmetic"
  (def x 10)
  (assert/equal
    (cond
      (< x 5) (* x 2)
      (< x 15) (* x 3)
      :else (* x 4))
    30))

(test "cond - nested cond"
  (def x 5)
  (def y 10)
  (assert/equal
    (cond
      (< x 0) "x negative"
      (< x 10) (cond
                 (< y 5) "x small, y small"
                 :else "x small, y big")
      :else "x big")
    "x small, y big"))

(test "cond - with let bindings"
  (let [x 7]
    (assert/equal
      (cond
        (< x 5) "small"
        (< x 10) "medium"
        :else "large")
      "medium")))

(test "cond - with function calls"
  (defn is-small [n] (< n 10))
  (defn is-positive [n] (> n 0))
  (def n 4)
  (assert/equal
    (cond
      (and (is-positive n) (is-small n)) "positive small"
      (is-positive n) "positive large"
      (is-small n) "negative small"
      :else "negative large")
    "positive small"))

(test "cond - returns last evaluated expression"
  (assert/equal
    (cond
      false (do (def x 1) (def y 2) 3)
      true (do (def a 10) (def b 20) 30)
      :else 100)
    30))

(test "cond - all clauses false without else"
  (assert/equal
    (cond
      (< 5 3) "impossible"
      (> 2 10) "also impossible")
    null))

(test "cond - single clause with else"
  (assert/equal
    (cond
      false 1
      :else 2)
    2))

(test "cond - multiple conditions chained"
  (def grade 85)
  (assert/equal
    (cond
      (>= grade 90) "A"
      (>= grade 80) "B"
      (>= grade 70) "C"
      (>= grade 60) "D"
      :else "F")
    "B"))
