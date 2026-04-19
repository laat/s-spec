(test "let is a derived form via macro"
  (defmacro let [bindings body]
    (quasiquote
      ((fn [(unquote (get bindings 0))]
         (unquote body))
       (unquote (get bindings 1)))))
  (assert/equal (let [x 10] (+ x 5)) 15)
  (assert/equal
    (print (macroexpand-1 (quote (let [x 10] (+ x 5)))))
    "((fn [x] (+ x 5)) 10)"))
