(test "quote keeps unquote forms literal"
  (assert/equal
    (print (quote (quasiquote (x (unquote y) (splice-unquote zs)))))
    "(quasiquote (x (unquote y) (splice-unquote zs)))"))

(test "nested quasiquote only unquotes at the current level"
  (assert/equal
    (print (quasiquote (a (quasiquote (b (unquote c))) (unquote (+ 1 2)))))
    "(a (quasiquote (b (unquote c))) 3)"))

(test "splice-unquote requires a sequence value"
  (assert/throws
    (fn [] (quasiquote [1 (splice-unquote 2) 3]))
    "splice-unquote value must be a list or array")
  (assert/throws
    (fn [] (quasiquote (list (splice-unquote {:a 1}) 3)))
    "splice-unquote value must be a list or array"))

(test "splice-unquote at top of quasiquote has no container"
  (assert/throws
    (fn [] (quasiquote (splice-unquote (list 1 2 3))))
    "splice-unquote requires an enclosing list or array"))

(test "splice-unquote is invalid in object key position"
  (assert/throws
    (fn [] (quasiquote {(splice-unquote [:a]) 1}))
    "splice-unquote is not valid in object key position"))

(test "unquote in object key position evaluates to the key"
  (def k :name)
  (assert/equal
    (quasiquote {(unquote k) "Ada"})
    {:name "Ada"})
  (assert/equal
    (quasiquote {(unquote k) 1 :b 2})
    {:name 1 :b 2}))

(test "unquote in object key position must yield a keyword"
  (def not-kw "name")
  (assert/throws
    (fn [] (quasiquote {(unquote not-kw) 1}))
    "object keys must be keywords")
  (assert/throws
    (fn [] (quasiquote {(unquote 7) 1}))
    "object keys must be keywords"))

(test "splice-unquote object-key check fires only at depth 1"
  (assert/equal
    (print (quasiquote (quasiquote {(splice-unquote x) 1})))
    "(quasiquote {(splice-unquote x) 1})"))

(test "splice-unquote in object value position is allowed"
  (assert/equal
    (quasiquote {:xs (splice-unquote (list 1 2 3))})
    {:xs (list 1 2 3)}))

(test "splicing nil contributes zero elements"
  (assert/equal
    (quasiquote (a (splice-unquote nil) b))
    (list (quote a) (quote b)))
  (assert/equal
    (quasiquote [1 (splice-unquote nil) 2])
    [1 2])
  (assert/equal
    (quasiquote ((splice-unquote nil)))
    nil))

(test "splicing an improper pair hits the value-type error"
  (assert/throws
    (fn [] (quasiquote (a (splice-unquote (cons 1 2)) b)))
    "splice-unquote value must be a list or array"))

(test "unquote and splice-unquote require quasiquote context"
  (assert/throws (fn [] (unquote 1)) "unquote outside quasiquote")
  (assert/throws (fn [] (splice-unquote [1 2])) "splice-unquote outside quasiquote"))
