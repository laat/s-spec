; Function tests ported from functions.test.ts

(test "def - variable binding"
  (def x 42)
  (assert/equal x 42)
  (def y (+ 1 2))
  (assert/equal y 3))

(test "def - multiple bindings"
  (def a 10)
  (def b 20)
  (assert/equal (+ a b) 30))

(test "def - shadowing"
  (def x 5)
  (def x 10)
  (assert/equal x 10))

(test "fn - anonymous functions"
  (assert/equal ((fn [x] (* x 2)) 5) 10)
  (assert/equal ((fn [x y] (+ x y)) 3 4) 7)
  (assert/equal ((fn [] 42)) 42))

(test "fn - as value"
  (def double (fn [x] (* x 2)))
  (assert/equal (double 5) 10))

(test "fn - closure"
  (def x 10)
  (def f (fn [y] (+ x y)))
  (assert/equal (f 5) 15))

(test "fn - nested closures"
  (def x 10)
  (def make-adder (fn [y] (fn [z] (+ x (+ y z)))))
  (def add5 (make-adder 5))
  (assert/equal (add5 3) 18))

(test "defn - simple function"
  (defn double [x] (* x 2))
  (assert/equal (double 5) 10))

(test "defn - multiple parameters"
  (defn add [x y] (+ x y))
  (assert/equal (add 3 4) 7))

(test "defn - zero parameters"
  (defn get-42 [] 42)
  (assert/equal (get-42) 42))

(test "defn - closure over outer scope"
  (def multiplier 3)
  (defn triple [x] (* multiplier x))
  (assert/equal (triple 4) 12))

(test "defn - multiple functions"
  (defn add [x y] (+ x y))
  (defn mul [x y] (* x y))
  (assert/equal (mul (add 2 3) 4) 20))

(test "higher-order - function as argument"
  (defn apply-twice [f x] (f (f x)))
  (defn inc [x] (+ x 1))
  (assert/equal (apply-twice inc 5) 7))

(test "higher-order - function as return value"
  (defn make-multiplier [n] (fn [x] (* n x)))
  (def times3 (make-multiplier 3))
  (assert/equal (times3 4) 12))

(test "higher-order - composition"
  (defn compose [f g] (fn [x] (f (g x))))
  (defn inc [x] (+ x 1))
  (defn double [x] (* x 2))
  (def inc-then-double (compose double inc))
  (assert/equal (inc-then-double 5) 12))

(test "scope - lexical scoping"
  (def x 10)
  (defn f [x] (+ x 1))
  (assert/equal (f 5) 6))

(test "scope - closure captures outer binding"
  (def x 10)
  (defn outer [] (fn [] x))
  (def inner (outer))
  (assert/equal (inner) 10))

(test "error - wrong arity"
  (defn f [x y] (+ x y))
  (assert/throws (fn [] (f 1)) "Expected 2 args, got 1")
  (defn g [x] (* x 2))
  (assert/throws (fn [] (g 1 2)) "Expected 1 args, got 2"))

(test "error - undefined variable"
  (assert/throws (fn [] nonexistent) "Undefined variable: nonexistent"))
