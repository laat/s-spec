; let tests - local bindings

(test "let - basic binding"
  (assert/equal (let [x 10] x) 10))

(test "let - multiple bindings"
  (assert/equal (let [x 10 y 20] (+ x y)) 30))

(test "let - bindings can reference earlier bindings"
  (assert/equal (let [x 10 y (+ x 5)] y) 15))

(test "let - sequential binding evaluation"
  (assert/equal (let [x 5 y (* x 2) z (+ y 3)] z) 13))

(test "let - empty bindings"
  (assert/equal (let [] 42) 42))

(test "let - local scope doesn't affect outer"
  (def outer-x 100)
  (let [x 10] (+ x 1))
  (assert/equal outer-x 100))

(test "let - shadowing outer binding"
  (def x 100)
  (assert/equal (let [x 10] x) 10)
  (assert/equal x 100))

(test "let - nested let"
  (assert/equal (let [x 10]
                  (let [y 20]
                    (+ x y)))
                30))

(test "let - inner let shadows outer let"
  (assert/equal (let [x 10]
                  (let [x 20]
                    x))
                20))

(test "let - with expressions in body"
  (assert/equal (let [x 5]
                  (if (> x 3)
                    (* x 2)
                    x))
                10))

(test "let - with function call in binding"
  (defn double [n] (* n 2))
  (assert/equal (let [x (double 5)] x) 10))

(test "let - with do block in body"
  (assert/equal (let [x 10]
                  (do
                    (def temp (+ x 5))
                    (* temp 2)))
                30))

(test "let - error on non-array bindings"
  (assert/throws (fn [] (let 42 (+ 1 2))) "let bindings must be an array"))

(test "let - error on odd number of binding elements"
  (assert/throws (fn [] (let [x 10 y] (+ x y))) "let bindings must have even number of elements"))

(test "let - error on non-symbol binding name"
  (assert/throws (fn [] (let [42 10] (+ 1 2))) "let binding name must be a symbol"))

(test "let - error on wrong arity"
  (assert/throws (fn [] (let [x 10])) "let requires 2 arguments"))

(test "let - bindings visible in order"
  (assert/equal (let [a 1
                       b (+ a 1)
                       c (+ b 1)]
                  c)
                3))

(test "let - can bind functions"
  (assert/equal (let [f (fn [x] (* x 2))]
                  (f 5))
                10))

(test "let - closure over let bindings"
  (def make-adder
    (fn [n]
      (let [amount n]
        (fn [x] (+ x amount)))))
  (def add5 (make-adder 5))
  (assert/equal (add5 10) 15))

(test "let - with macro-expanded binding value"
  (assert/equal (let [x (+ 1 2 3)] x) 6))
