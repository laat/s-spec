(test "array literal and constructor"
  (assert/equal [] (array))
  (assert/equal [1 2 3] (array 1 2 3)))

(test "array type is distinct"
  (assert/equal (array? [1 2 3]) true)
  (assert/equal (list? [1 2 3]) false)
  (assert/equal (pair? [1 2 3]) false)
  (assert/equal (null? [1 2 3]) false)
  (assert/equal (nil? [1 2 3]) false))

(test "array length"
  (assert/equal (length []) 0)
  (assert/equal (length [1 2 3]) 3))

(test "array get uses zero-based indexes"
  (assert/equal (get [10 20 30] 0) 10)
  (assert/equal (get [10 20 30] 1) 20)
  (assert/equal (get [10 20 30] 2) 30))

(test "array get out of bounds returns nil"
  (assert/equal (get [] 0) nil)
  (assert/equal (get [10 20 30] -1) nil)
  (assert/equal (get [10 20 30] 3) nil)
  (assert/equal (get [10 20 30] 99) nil))

(test "array get with non-integer index returns default"
  (assert/equal (get [10 20 30] 0.5) nil)
  (assert/equal (get [10 20 30] 1.9) nil)
  (assert/equal (get [10 20 30] 0.5 :missing) :missing)
  (assert/equal (get [10 20 30] -0.1 :missing) :missing))

(test "array get with keyword index returns default"
  (assert/equal (get [10 20 30] :x) nil)
  (assert/equal (get [10 20 30] :x :missing) :missing))

(test "get on nil returns default"
  (assert/equal (get nil :x) nil)
  (assert/equal (get nil 0) nil)
  (assert/equal (get nil :x :d) :d)
  (assert/equal (get nil 0 :d) :d))

(test "get on non-collection throws"
  (assert/throws (fn [] (get 42 :x)) "get requires")
  (assert/throws (fn [] (get "str" 0)) "get requires")
  (assert/throws (fn [] (get true :x)) "get requires")
  (assert/throws (fn [] (get (cons 1 2) :x)) "get requires")
  (assert/throws (fn [] (get (list 1 2 3) :x)) "get requires"))

(test "nested arrays"
  (assert/equal (get [1 [2 3] 4] 1) [2 3])
  (assert/equal (get (get [1 [2 3] 4] 1) 0) 2))
