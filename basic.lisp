(test "numbers"
  (assert/equal 1 1)
  (assert/equal -3 -3)
  (assert/equal 4.2 4.2)
  (assert/equal (+ 1 2) 3)
  (assert/equal (+ 1 2 3 4) 10)
  (assert/equal (+) 0)
  (assert/equal (+ 5) 5))

(test "numbers are finite — overflow literals throw at read time"
  (assert/throws (fn [] (parse "1e400")) "invalid number")
  (assert/throws (fn [] (parse "-1e400")) "invalid number"))

(test "+ requires numbers"
  (assert/throws (fn [] (+ 1 "x")) "+ requires numbers")
  (assert/throws (fn [] (+ nil 1)) "+ requires numbers")
  (assert/throws (fn [] (+ :a 1)) "+ requires numbers"))

(test "+ overflow throws"
  (assert/throws (fn [] (+ 1e308 1e308)) "arithmetic overflow"))

(test "strings"
  (assert/equal "hello" "hello")
  (assert/equal "a\"b" "a\"b")
  (assert/equal "path\\file" "path\\file"))

(test "null"
  (assert/equal null null))
