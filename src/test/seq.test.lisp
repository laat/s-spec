; seq tests

(test "seq - array basics"
  (def s (seq [10 20 30]))
  (assert/equal (first s) 10)
  (assert/equal (first (rest s)) 20)
  (assert/equal (first (rest (rest s))) 30)
  (assert/equal (rest (rest (rest s))) null))

(test "seq - empty and null"
  (assert/equal (seq []) null)
  (assert/equal (seq null) null))

(test "seq - list passthrough"
  (assert/equal (first (seq (list 1 2 3))) 1)
  (assert/equal (first (rest (seq (list 1 2 3)))) 2))

(test "seq - count over remainder"
  (def s (seq [1 2 3 4]))
  (assert/equal (count s) 4)
  (assert/equal (count (rest s)) 3)
  (assert/equal (count (rest (rest s))) 2))

(test "seq - works in recursive iteration"
  (defn sum-seq [s]
    (if (empty? s)
      0
      (+ (first s) (sum-seq (rest s)))))
  (assert/equal (sum-seq (seq [1 2 3 4 5])) 15))

(test "seq - errors on non-sequential values"
  (assert/throws (fn [] (seq 42)) "seq requires a list, array, or null")
  (assert/throws (fn [] (seq {:a 1})) "seq requires a list, array, or null"))
