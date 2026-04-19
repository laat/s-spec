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

(test "quasiquote reader shorthands with boolean literals"
  (assert/equal
    (print (parse "`[~false ~@xs]"))
    "(quasiquote [(unquote false) (splice-unquote xs)])"))

(test "shorthand and explicit forms are equivalent"
  (assert/equal
    (print (parse "`(x ~y ~@zs)"))
    (print (parse "(quasiquote (x (unquote y) (splice-unquote zs)))"))))

(test "quasiquote unquote and splice-unquote shorthands skip comments"
  (assert/equal
    (print (parse "` ; qq\n(a ~ ; uq\n b ~@ ; sp\n cs)"))
    "(quasiquote (a (unquote b) (splice-unquote cs)))"))
