; Type safety tests - verify runtime type checking in builtins

(test "add - type error on string first arg"
  (assert/throws (fn [] (add "hello" 5)) "add requires number for argument 1"))

(test "add - type error on string second arg"
  (assert/throws (fn [] (add 5 "hello")) "add requires number for argument 2"))

(test "sub - type error on boolean arg"
  (assert/throws (fn [] (sub true 5)) "sub requires number for argument 1"))

(test "mul - type error on nil arg"
  (assert/throws (fn [] (mul nil 5)) "mul requires number for argument 1"))

(test "div - type error before division by zero check"
  (assert/throws (fn [] (div "10" 0)) "div requires number for argument 1"))

(test "gt - type error on string comparison"
  (assert/throws (fn [] (gt "5" 3)) "gt requires number for argument 1"))

(test "lt - type error on mixed types"
  (assert/throws (fn [] (lt 5 "3")) "lt requires number for argument 2"))

(test "gte - type error on keyword"
  (assert/throws (fn [] (gte :foo 5)) "gte requires number for argument 1"))

(test "lte - type error on array"
  (assert/throws (fn [] (lte [1 2 3] 5)) "lte requires number for argument 1"))

; Verify type checking happens through macros too
(test "+ macro with type error"
  (assert/throws (fn [] (+ 1 "two" 3)) "add requires number for argument"))

(test "- macro with type error"
  (assert/throws (fn [] (- 10 true)) "sub requires number for argument"))

(test "* macro with type error"
  (assert/throws (fn [] (* 2 3 nil)) "mul requires number for argument"))

(test "/ macro with type error"
  (assert/throws (fn [] (/ 10 "2")) "div requires number for argument"))

(test "> macro with type error"
  (assert/throws (fn [] (> 5 "3" 1)) "gt requires number for argument"))

(test "< macro with type error"
  (assert/throws (fn [] (< 1 2 :three)) "lt requires number for argument"))

(test ">= macro with type error"
  (assert/throws (fn [] (>= 10 5 false)) "gte requires number for argument"))

(test "<= macro with type error"
  (assert/throws (fn [] (<= 1 [2] 3)) "lte requires number for argument"))
