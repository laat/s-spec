(test "fn with rest parameter collects extra arguments"
  (assert/equal ((fn [x & rest] rest) 1 2 3) (list 2 3))
  (assert/equal ((fn [x & rest] rest) 1 2) (list 2))
  (assert/equal ((fn [x & rest] rest) 1) nil))

(test "fn with rest-only parameter"
  (assert/equal ((fn [& all] all) 1 2 3) (list 1 2 3))
  (assert/equal ((fn [& all] all)) nil))

(test "rest parameter is a proper list"
  (assert/equal (list? ((fn [& xs] xs) 1 2 3)) true)
  (assert/equal (list? ((fn [& xs] xs))) true))

(test "rest parameter works with fixed params"
  (def collect (fn [a b & more] {:a a :b b :more more}))
  (assert/equal (:a (collect 1 2 3 4)) 1)
  (assert/equal (:b (collect 1 2 3 4)) 2)
  (assert/equal (:more (collect 1 2 3 4)) (list 3 4))
  (assert/equal (:more (collect 1 2)) nil))

(test "rest parameter in defmacro"
  (defmacro do-all [& body]
    (quasiquote (do (splice-unquote body))))
  (assert/equal (do-all 1 2 3) 3)
  (assert/equal (do-all "only") "only"))

(test "fixed arity still enforced before rest"
  (assert/throws (fn [] ((fn [x y & more] x) 1)) "arity mismatch"))
