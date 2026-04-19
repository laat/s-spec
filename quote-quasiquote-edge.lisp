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
    "splice-unquote requires a list or array")
  (assert/throws
    (fn [] (quasiquote (list (splice-unquote {:a 1}) 3)))
    "splice-unquote requires a list or array"))

(test "splice-unquote is invalid in object key position"
  (assert/throws
    (fn [] (quasiquote {(splice-unquote [:a]) 1}))
    "splice-unquote is not valid in object key position"))

(test "splice-unquote in object value position is allowed"
  (assert/equal
    (quasiquote {:xs (splice-unquote (list 1 2 3))})
    {:xs (list 1 2 3)}))

(test "unquote and splice-unquote require quasiquote context"
  (assert/throws (fn [] (unquote 1)) "unquote outside quasiquote")
  (assert/throws (fn [] (splice-unquote [1 2])) "splice-unquote outside quasiquote"))
