(test "quasiquote with unquote"
  (assert/equal
    (print (quasiquote (+ 1 (unquote (+ 1 2)))))
    "(+ 1 3)")
  (assert/equal
    (print (quasiquote {:a (unquote (+ 2 3)) :b 9}))
    "{:a 5 :b 9}"))

(test "quasiquote with splice-unquote"
  (assert/equal
    (print (quasiquote (list (splice-unquote (list 1 2)) 3)))
    "(list 1 2 3)")
  (assert/equal
    (print (quasiquote [0 (splice-unquote [1 2]) 3]))
    "[0 1 2 3]"))

(test "nested quasiquote keeps inner unquote literal"
  (assert/equal
    (print (quasiquote (quasiquote (x (unquote y)))))
    "(quasiquote (x (unquote y)))"))
