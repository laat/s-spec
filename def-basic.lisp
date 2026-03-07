(test "def binds scalar values"
  (assert/equal (def answer 42) 42)
  (assert/equal answer 42)
  (assert/equal (def greeting "hi") "hi")
  (assert/equal greeting "hi"))

(test "def binds structured values"
  (assert/equal (def xs [1 2 3]) [1 2 3])
  (assert/equal xs [1 2 3])
  (assert/equal (def user {:name "Ada" :active true}) {:name "Ada" :active true})
  (assert/equal (:name user) "Ada"))

(test "def binds functions"
  (assert/equal
    (def add2 (fn [x y] "Add two numbers." (+ x y)))
    add2)
  (assert/equal (add2 2 3) 5)
  (assert/equal (doc add2) "Add two numbers."))

(test "def can be used for missing-key behavior checks"
  (def profile {:name "Ada"})
  (assert/equal (:name profile) "Ada")
  (assert/equal (:email profile) nil)
  (assert/equal (:email profile "none") "none"))

(test "def allows redefinition"
  (assert/equal (def version 1) 1)
  (assert/equal version 1)
  (assert/equal (def version 2) 2)
  (assert/equal version 2))

(test "def supports recursive functions"
  (def sum-list
    (fn [xs]
      (if (= xs nil)
        0
        (+ (first xs) (sum-list (rest xs))))))
  (assert/equal (sum-list (list 1 2 3 4)) 10)
  (assert/equal (sum-list (list)) 0))
