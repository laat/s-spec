(test "and truthy and falsey behavior"
  (assert/equal (and) true)
  (assert/equal (and true true) true)
  (assert/equal (and true 1 "x") "x")
  (assert/equal (and true false "x") false)
  (assert/equal (and true nil "x") nil))

(test "or truthy and falsey behavior"
  (assert/equal (or) false)
  (assert/equal (or false nil) nil)
  (assert/equal (or false nil 0) 0)
  (assert/equal (or false nil "x" 99) "x"))

(test "and short-circuits"
  (assert/equal (and false (not-defined)) false)
  (assert/equal (and nil (not-defined)) nil)
  (assert/equal (and true 1 2) 2))

(test "or short-circuits"
  (assert/equal (or true (not-defined)) true)
  (assert/equal (or "ok" (not-defined)) "ok")
  (assert/equal (or false nil 3) 3))

(test "and/or with keyword lookups"
  (assert/equal
    (and (:active {:active true :name "Ada"}) (:name {:active true :name "Ada"}))
    "Ada")
  (assert/equal
    (or (:email {:name "Ada"}) "none")
    "none"))
