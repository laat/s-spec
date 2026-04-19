(test "quote shorthand canonicalizes"
  (assert/equal (print (parse "'x")) "(quote x)")
  (assert/equal (print (parse "'(+ 1 2)")) "(quote (+ 1 2))")
  (assert/equal (print (parse "'[1 2 3]")) "(quote [1 2 3])")
  (assert/equal (print (parse "'{:a 1 :b 2}")) "(quote {:a 1 :b 2})"))

(test "quote shorthand with boolean literals"
  (assert/equal (print (parse "'true")) "(quote true)")
  (assert/equal (print (parse "'false")) "(quote false)"))
