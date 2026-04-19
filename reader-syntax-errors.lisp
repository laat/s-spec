(test "reader shorthand requires following form"
  (assert/throws (fn [] (parse "'")) "expected form after quote")
  (assert/throws (fn [] (parse "`")) "expected form after quasiquote")
  (assert/throws (fn [] (parse "~")) "expected form after unquote")
  (assert/throws (fn [] (parse "~@")) "expected form after splice-unquote"))
