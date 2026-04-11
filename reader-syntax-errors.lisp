(test "reader shorthand requires following form"
  (assert/throws (fn [] (parse "'")) "expected form after quote")
  (assert/throws (fn [] (parse "`")) "expected form after quasiquote")
  (assert/throws (fn [] (parse "~")) "expected form after unquote")
  (assert/throws (fn [] (parse "~@")) "expected form after splice-unquote"))

(test "unquote shorthands require quasiquote context"
  (assert/throws (fn [] (parse "~x")) "unquote outside quasiquote")
  (assert/throws (fn [] (parse "~@xs")) "splice-unquote outside quasiquote"))

(test "splice-unquote shorthand is invalid in object key position"
  (assert/throws
    (fn [] (parse "`{~@ks 1}"))
    "splice-unquote is not valid in object key position"))
