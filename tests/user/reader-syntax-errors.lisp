(test "quote shorthand requires following form"
  (assert/throws (fn [] (parse "'")) "expected form after quote"))
