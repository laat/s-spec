; Array/vector tests ported from vectors.test.ts

(test "array literals"
  ; Note: We can't check internal structure like TypeScript,
  ; but we can verify arrays work correctly with operations
  (assert/equal (length [1 2 3]) 3)
  (assert/equal (length []) 0)
  (assert/equal (nth [1 "hello" true nil] 0) 1)
  (assert/equal (nth [1 "hello" true nil] 1) "hello")
  (assert/equal (nth [1 "hello" true nil] 2) true)
  (assert/equal (nth [1 "hello" true nil] 3) nil))

(test "array function"
  (assert/equal (length (array 1 2 3)) 3)
  (assert/equal (length (array)) 0)
  (assert/equal (= (array (+ 1 2) (* 3 4)) [3 12]) true))

(test "array? predicate"
  (assert/equal (array? [1 2 3]) true)
  (assert/equal (array? []) true)
  (assert/equal (array? 42) false)
  (assert/equal (array? "string") false)
  (assert/equal (array? nil) false)
  (assert/equal (array? (list 1 2 3)) false))

(test "nth - random access"
  (assert/equal (nth [10 20 30] 0) 10)
  (assert/equal (nth [10 20 30] 1) 20)
  (assert/equal (nth [10 20 30] 2) 30)
  (assert/equal (nth [10 20 30] 3) nil)
  (assert/equal (nth [10 20 30] -1) nil)
  (assert/equal (nth [10 20 30] 100) nil)
  (assert/equal (nth [10 20 30] (+ 1 1)) 30))

(test "nth errors"
  (assert/throws (fn [] (nth 42 0)) "nth requires an array")
  (assert/throws (fn [] (nth [1 2 3] "a")) "nth requires number for argument 2"))

(test "length"
  (assert/equal (length [1 2 3]) 3)
  (assert/equal (length []) 0)
  (assert/equal (length [1]) 1)
  (assert/equal (length (list 1 2 3)) 3)
  (assert/equal (length (list)) 0)
  (assert/equal (length nil) 0))

(test "length error"
  (assert/throws (fn [] (length 42)) "length requires an array or list"))

(test "push"
  (assert/equal (= (push [1 2] 3) [1 2 3]) true)
  (assert/equal (= (push [] 1) [1]) true)
  (def v [1 2])
  (def v2 (push v 3))
  (assert/equal (length v) 2)
  (assert/throws (fn [] (push 42 1)) "push requires an array"))

(test "arrays in functions"
  (defn sum-arr [v] (+ (nth v 0) (nth v 1) (nth v 2)))
  (assert/equal (sum-arr [10 20 30]) 60))

(test "array as return value"
  (defn make-range [n] (array n (+ n 1) (+ n 2)))
  (assert/equal (nth (make-range 10) 1) 11))

(test "arrays with keywords"
  (assert/equal (length [:foo :bar]) 2))

(test "array literal in def"
  (def nums [1 2 3])
  (assert/equal (nth nums 1) 2))

(test "nested array access"
  (def matrix [[1 2] [3 4] [5 6]])
  (assert/equal (nth (nth matrix 1) 0) 3))

(test "array with nil elements"
  (assert/equal (length [nil nil nil]) 3)
  (assert/equal (nth [nil nil nil] 0) nil))

(test "empty array equality"
  (assert/equal (= [] (array)) true))

(test "arrays with commas"
  (assert/equal (= [1, 2, 3] [1 2 3]) true)
  (assert/equal (= ["a", "b", "c"] ["a" "b" "c"]) true)
  (assert/equal (= [1, "hello", true, nil] [1 "hello" true nil]) true)
  (assert/equal (length [[1, 2], [3, 4]]) 2)
  (assert/equal (= [1, 2, 3,] [1 2 3]) true)
  (assert/equal (= [1, 2 3, 4] [1 2 3 4]) true))
