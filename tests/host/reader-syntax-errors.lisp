(test "quasiquote reader shorthands require following form"
  (assert/throws (fn [] (parse "`")) "expected form after quasiquote")
  (assert/throws (fn [] (parse "~")) "expected form after unquote")
  (assert/throws (fn [] (parse "~@")) "expected form after splice-unquote"))
