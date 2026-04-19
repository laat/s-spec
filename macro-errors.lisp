(test "defmacro requires symbol name and vector params"
  (assert/throws (fn [] (defmacro "m" [x] x)) "defmacro name must be a symbol")
  (assert/throws (fn [] (defmacro m x x)) "defmacro params must be a vector"))

(test "defmacro requires a body"
  (assert/throws (fn [] (defmacro m [x])) "defmacro requires a body"))

(test "macro expansion requires list forms"
  (assert/throws (fn [] (macroexpand-1 123)) "macroexpand-1 requires exactly one form")
  (assert/throws (fn [] (macroexpand null)) "macroexpand requires exactly one form"))

(test "defmacro requires a name, params, and body"
  (assert/throws (fn [] (defmacro)) "defmacro requires a name, params, and body")
  (assert/throws (fn [] (defmacro m)) "defmacro requires a name, params, and body"))

(test "unquote forms must appear inside quasiquote"
  (assert/throws (fn [] (unquote 1)) "unquote outside quasiquote")
  (assert/throws (fn [] (splice-unquote (list 1 2))) "splice-unquote outside quasiquote"))

(test "quote requires exactly one argument"
  (assert/throws (fn [] (quote)) "quote requires exactly one argument")
  (assert/throws (fn [] (quote a b)) "quote requires exactly one argument"))

(test "quasiquote requires exactly one argument"
  (assert/throws (fn [] (quasiquote)) "quasiquote requires exactly one argument")
  (assert/throws (fn [] (quasiquote a b)) "quasiquote requires exactly one argument"))

(test "unquote and splice-unquote require exactly one argument"
  (assert/throws (fn [] (quasiquote (unquote))) "unquote requires exactly one argument")
  (assert/throws (fn [] (quasiquote (unquote a b))) "unquote requires exactly one argument")
  (assert/throws (fn [] (quasiquote ((splice-unquote)))) "splice-unquote requires exactly one argument")
  (assert/throws (fn [] (quasiquote ((splice-unquote a b)))) "splice-unquote requires exactly one argument"))
