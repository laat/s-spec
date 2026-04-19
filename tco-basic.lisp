(test "tail recursion of 15000 calls does not overflow the host stack"
  (def count-down (fn [n]
    (if (= n 0)
      :done
      (count-down (+ n -1)))))
  (assert/equal (count-down 15000) :done))
