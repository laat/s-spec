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
  (require "stdlib.lisp")
  (defmacro with-tmp [value body]
    (quasiquote (let [tmp (unquote value)]
                 (unquote body))))
  (assert/equal
    (let [tmp 99]
      (with-tmp 1 tmp))
    1))
