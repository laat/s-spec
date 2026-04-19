(test "defmacro defines a callable macro"
  (defmacro unless [pred then else]
    "Evaluate then when pred is falsey."
    (quasiquote (if (unquote pred)
                 (unquote else)
                 (unquote then))))
  (assert/equal (unless false 1 2) 1)
  (assert/equal (unless true 1 2) 2)
  (assert/equal (doc unless) "Evaluate then when pred is falsey."))

(test "macros receive unevaluated forms"
  (defmacro literal-form [x]
    (quasiquote (quote (unquote x))))
  (assert/equal (print (literal-form (+ 1 2))) "(+ 1 2)")
  (assert/equal (print (literal-form {:a 1 :b [2 3]})) "{:a 1 :b [2 3]}"))

(test "non-hygienic macro can capture names"
  (require "../../stdlib.lisp")
  (defmacro with-tmp [value body]
    (quasiquote (let [tmp (unquote value)]
                 (unquote body))))
  (assert/equal
    (let [tmp 99]
      (with-tmp 1 tmp))
    1))

(test "defmacro binds the name in the variable namespace too"
  (defmacro m [x] (quasiquote (+ (unquote x) 1)))
  (assert/equal (bound? 'm) true)
  (assert/equal (bound? 'never-a-macro) false))

(test "special forms always win over user macros with the same name"
  (defmacro if [p t e] (quasiquote (+ (unquote p) 100)))
  (assert/equal (if true 1 2) 1)
  (assert/equal (if false 1 2) 2))

(test "defmacro supports rest parameters"
  (defmacro do-all [& body]
    (quasiquote (do (splice-unquote body))))
  (assert/equal (do-all 1 2 3) 3)
  (assert/equal (do-all "only") "only"))
