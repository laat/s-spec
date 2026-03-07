(test "defmacro requires symbol name and vector params"
  (assert/throws (fn [] (defmacro "m" [x] x)) "defmacro name must be a symbol")
  (assert/throws (fn [] (defmacro m x x)) "defmacro params must be a vector"))

(test "defmacro requires a body"
  (assert/throws (fn [] (defmacro m [x])) "defmacro requires a body"))

(test "macro expansion requires list forms"
  (assert/throws (fn [] (macroexpand-1 123)) "macroexpand-1 requires exactly one form")
  (assert/throws (fn [] (macroexpand null)) "macroexpand requires exactly one form"))

(test "unquote forms must appear inside quasiquote"
  (assert/throws (fn [] (unquote 1)) "unquote outside quasiquote")
  (assert/throws (fn [] (splice-unquote (list 1 2))) "splice-unquote outside quasiquote"))
