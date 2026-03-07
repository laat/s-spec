(test "macroexpand-1 expands one step"
  (defmacro inc1 [x]
    (quasiquote (+ (unquote x) 1)))
  (assert/equal
    (print (macroexpand-1 (quote (inc1 2))))
    "(+ 2 1)")
  (assert/equal
    (print (macroexpand-1 (quote (+ 1 2))))
    "(+ 1 2)"))

(test "macroexpand expands recursively"
  (defmacro when [pred body]
    (quasiquote (if (unquote pred) (unquote body) nil)))
  (defmacro unless [pred body]
    (quasiquote (when (if (unquote pred) false true) (unquote body))))
  (assert/equal
    (print (macroexpand (quote (unless false 1))))
    "(if (if false false true) 1 nil)"))

(test "macro expansion only applies in list head position"
  (defmacro mark [x]
    (quasiquote [expanded (unquote x)]))
  (assert/equal
    (print (macroexpand (quote [mark 1])))
    "[mark 1]")
  (assert/equal
    (print (macroexpand (quote (+ mark 1))))
    "(+ mark 1)")
  (assert/equal
    (print (macroexpand (quote (mark 1))))
    "[expanded 1]"))
