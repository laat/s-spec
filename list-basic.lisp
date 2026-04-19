(test "nil is the empty list"
  (assert/equal (list) nil)
  (assert/equal (nil? nil) true)
  (assert/equal (list? nil) true)
  (assert/equal (pair? nil) false))

(test "null and nil are distinct"
  (assert/equal (null? null) true)
  (assert/equal (null? nil) false)
  (assert/equal (nil? null) false)
  (assert/equal (list? null) false))

(test "cons creates a pair"
  (assert/equal (pair? (cons 1 nil)) true)
  (assert/equal (nil? (cons 1 nil)) false)
  (assert/equal (first (cons 1 nil)) 1)
  (assert/equal (rest (cons 1 nil)) nil))

(test "list builds nested pairs ending in nil"
  (assert/equal (first (list 1 2 3)) 1)
  (assert/equal (first (rest (list 1 2 3))) 2)
  (assert/equal (first (rest (rest (list 1 2 3)))) 3)
  (assert/equal (rest (rest (rest (list 1 2 3)))) nil)
  (assert/equal (list? (list 1 2 3)) true))

(test "first and rest on empty list"
  (assert/equal (first nil) nil)
  (assert/equal (rest nil) nil))

(test "improper list is pair but not list"
  (assert/equal (pair? (cons 1 2)) true)
  (assert/equal (list? (cons 1 2)) false)
  (assert/equal (first (cons 1 2)) 1)
  (assert/equal (rest (cons 1 2)) 2))

(test "print of an improper pair uses dotted form"
  (def p (cons 1 2))
  (assert/equal (print p) "(1 . 2)")
  (assert/equal (= p (parse (print p))) false))

(test "print of a deep improper pair uses walk form"
  (assert/equal (print (cons 1 (cons 2 3))) "(1 2 . 3)")
  (assert/equal (print (cons 1 (cons 2 (cons 3 :end)))) "(1 2 3 . :end)")
  (assert/equal (print (cons :a (cons :b :c))) "(:a :b . :c)"))

(test "first and rest throw on non-pair non-nil"
  (assert/throws (fn [] (first 42)) "first requires a pair or nil")
  (assert/throws (fn [] (first "hello")) "first requires a pair or nil")
  (assert/throws (fn [] (first [1 2 3])) "first requires a pair or nil")
  (assert/throws (fn [] (first {:a 1})) "first requires a pair or nil")
  (assert/throws (fn [] (rest 42)) "rest requires a pair or nil")
  (assert/throws (fn [] (rest "hello")) "rest requires a pair or nil")
  (assert/throws (fn [] (rest [1 2 3])) "rest requires a pair or nil")
  (assert/throws (fn [] (rest {:a 1})) "rest requires a pair or nil"))
