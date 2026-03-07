(test "numbers"
  (assert/equal 1 1)
  (assert/equal -3 -3)
  (assert/equal 4.2 4.2)
  (assert/equal (+ 1 2) 3)
  (assert/equal (+ 1 2 3 4) 10)
  (assert/equal (+) 0)
  (assert/equal (+ 5) 5))

(test "strings"
  (assert/equal "hello" "hello")
  (assert/equal "a\"b" "a\"b")
  (assert/equal "path\\file" "path\\file"))

(test "null"
  (assert/equal null null))
