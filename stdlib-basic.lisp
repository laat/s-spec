(test "require stdlib and use common macros"
  (require "stdlib.lisp")

  (assert/equal (when true 10) 10)
  (assert/equal (when false 10) nil)
  (assert/equal (when-not false 11) 11)
  (assert/equal (when-not true 11) nil)
  (assert/equal (unless false 1 2) 1)
  (assert/equal (unless true 1 2) 2)
  (assert/equal (if-not false 1 2) 1)
  (assert/equal (if-not true 1 2) 2)
  (assert/equal (let [x 5] (+ x 2)) 7)
  (assert/equal (let [x 2] (+ x 3)) 5)
  (assert/equal (let [x 2 y (+ x 3)] (+ x y)) 7)
  (assert/equal (let [a 1 b 2 c 3] (+ a b c)) 6)
  (assert/equal
    (let [x 10 y 20]
      (+ x 1)
      (+ x y))
    30)

  (def stdlib_counter 0)
  (def stdlib_tick
    (fn []
      (do
        (def stdlib_counter (+ stdlib_counter 1))
        stdlib_counter)))

  (assert/equal (or-else false 99) 99)
  (assert/equal (or-else 7 99) 7)
  (assert/equal (or-else (stdlib_tick) 99) 1)
  (assert/equal stdlib_counter 1)

  (assert/equal (and-then false 99) false)
  (assert/equal (and-then 7 99) 99)
  (assert/equal (and-then (stdlib_tick) 88) 88)
  (assert/equal stdlib_counter 2)

  (defn stdlib/add3 [x] (+ x 3))
  (assert/equal (stdlib/add3 4) 7)

  (assert/equal (doc when) "Evaluate then when pred is truthy.")
  (assert/equal (doc let) "Sequential local bindings with arbitrary length and multi-form bodies.")
  (assert/equal (doc defn) "Define a named function; expands to def + fn."))
