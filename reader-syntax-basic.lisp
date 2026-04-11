(test "quote shorthand canonicalizes"
  (assert/equal (print (parse "'x")) "(quote x)")
  (assert/equal (print (parse "'(+ 1 2)")) "(quote (+ 1 2))")
  (assert/equal (print (parse "'[1 2 3]")) "(quote [1 2 3])")
  (assert/equal (print (parse "'{:a 1 :b 2}")) "(quote {:a 1 :b 2})"))

(test "quasiquote shorthand canonicalizes"
  (assert/equal (print (parse "`x")) "(quasiquote x)")
  (assert/equal
    (print (parse "`(+ 1 ~(+ 1 2))"))
    "(quasiquote (+ 1 (unquote (+ 1 2))))")
  (assert/equal
    (print (parse "`[0 ~x ~@xs 3]"))
    "(quasiquote [0 (unquote x) (splice-unquote xs) 3])"))

(test "nested reader shorthands canonicalize"
  (assert/equal
    (print (parse "`(a `(b ~c) ~d)"))
    "(quasiquote (a (quasiquote (b (unquote c))) (unquote d)))"))

(test "reader shorthands with boolean literals"
  (assert/equal (print (parse "'true")) "(quote true)")
  (assert/equal (print (parse "'false")) "(quote false)")
  (assert/equal
    (print (parse "`[~false ~@xs]"))
    "(quasiquote [(unquote false) (splice-unquote xs)])"))

(test "shorthand and explicit forms are equivalent"
  (assert/equal
    (print (parse "`(x ~y ~@zs)"))
    (print (parse "(quasiquote (x (unquote y) (splice-unquote zs)))"))))
