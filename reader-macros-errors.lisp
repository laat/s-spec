(test "reader macro requires following form"
  (assert/throws (fn [] (parse "'")) "expected form after quote")
  (assert/throws (fn [] (parse "`")) "expected form after quasiquote")
  (assert/throws (fn [] (parse "~")) "expected form after unquote")
  (assert/throws (fn [] (parse "~@")) "expected form after splice-unquote"))

(test "unquote reader macros require quasiquote context"
  (assert/throws (fn [] (parse "~x")) "unquote outside quasiquote")
  (assert/throws (fn [] (parse "~@xs")) "splice-unquote outside quasiquote"))

(test "splice-unquote reader macro is invalid in object key position"
  (assert/throws
    (fn [] (parse "`{~@ks 1}"))
    "splice-unquote is not valid in object key position"))
