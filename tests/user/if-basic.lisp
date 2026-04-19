(test "if chooses then branch when condition is truthy"
  (assert/equal (if true 1 2) 1)
  (assert/equal (if 1 "yes" "no") "yes")
  (assert/equal (if "non-empty" :then :else) :then)
  (assert/equal (if [] "array" "other") "array")
  (assert/equal (if {} "object" "other") "object"))

(test "if chooses else branch when condition is falsey"
  (assert/equal (if false 1 2) 2)
  (assert/equal (if nil 1 2) 2))

(test "if is an expression"
  (assert/equal (+ 1 (if true 2 3)) 3)
  (assert/equal (let [x 10] (if x "big" "small")) "big"))

(test "if only evaluates selected branch"
  (assert/equal (if true 1 (not-defined)) 1)
  (assert/equal (if false (not-defined) 2) 2))

(test "if works with objects and keyword lookup"
  (assert/equal
    (if (:active {:active true :name "Ada"})
      "enabled"
      "disabled")
    "enabled")
  (assert/equal
    (if (:active {:name "Ada"})
      "enabled"
      "disabled")
    "disabled"))
