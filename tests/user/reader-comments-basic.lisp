(test "reader ignores line comments"
  (assert/equal
    (print (parse "; just a comment\n42"))
    "42")
  (assert/equal
    (print (parse "(+ 1 ; inline comment\n 2)"))
    "(+ 1 2)")
  (assert/equal
    (print (parse "[1 ; c1\n 2 ; c2\n 3]"))
    "[1 2 3]"))

(test "comments work across object and quote reader macros"
  (assert/equal
    (print (parse "{:a 1 ; keep a\n :b 2}"))
    "{:a 1 :b 2}")
  (assert/equal
    (print (parse "' ; quote next form\n(+ 1 2)"))
    "(quote (+ 1 2))"))
