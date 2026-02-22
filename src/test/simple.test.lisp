; Simple test to verify the test harness works
; Uses the 'test' macro from stdlib-test.lisp for convenience

(test "addition"
  (assert/equal (+ 1 2) 3 "1 + 2 should equal 3"))

(test "addition multiple"
  (assert/equal (+ 5 5) 10 "5 + 5 should equal 10"))

(test "string concatenation"
  (assert/equal (str "hello" " " "world") "hello world" "str should concatenate"))

(test "comparison >"
  (assert/equal (> 5 3) true "> works"))

(test "comparison <"
  (assert/equal (< 1 5) true "< works"))
