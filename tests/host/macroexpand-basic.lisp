(test "macroexpand docstrings"
  (assert/equal (doc macroexpand-1) "Expand the form once at the head, if it is a macro call.")
  (assert/equal (doc macroexpand) "Repeatedly macroexpand at the head until a fixpoint."))

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

(test "macroexpand returns non-list forms unchanged"
  (assert/equal (macroexpand-1 123) 123)
  (assert/equal (macroexpand null) null)
  (assert/equal (macroexpand-1 "hello") "hello")
  (assert/equal (macroexpand :foo) :foo)
  (assert/equal (macroexpand-1 true) true)
  (assert/equal (macroexpand-1 false) false)
  (assert/equal (macroexpand nil) nil)
  (assert/equal
    (print (macroexpand (quote x)))
    "x")
  (assert/equal
    (print (macroexpand [1 2 3]))
    "[1 2 3]")
  (assert/equal
    (print (macroexpand {:a 1}))
    "{:a 1}"))

(test "macroexpand on list with non-macro head returns unchanged"
  (assert/equal
    (print (macroexpand (quote (undefined-sym 1 2))))
    "(undefined-sym 1 2)")
  (def not-a-macro (fn [x] x))
  (assert/equal
    (print (macroexpand (quote (not-a-macro 1 2))))
    "(not-a-macro 1 2)"))
