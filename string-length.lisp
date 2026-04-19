(test "length on ASCII strings counts characters"
  (assert/equal (length "") 0)
  (assert/equal (length "a") 1)
  (assert/equal (length "hello") 5))

(test "length on strings counts Unicode code points, not UTF-16 code units or UTF-8 bytes"
  (assert/equal (length "é") 1)
  (assert/equal (length "🎉") 1)
  (assert/equal (length "a🎉b") 3)
  (assert/equal (length "🎉🎉🎉") 3))
