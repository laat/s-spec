(test "let binds local names"
  (assert/equal (let [x 1 y 2] (+ x y)) 3)
  (assert/equal (let [name "Ada"] name) "Ada"))

(test "let bindings are sequential"
  (assert/equal (let [x 2 y (+ x 3)] y) 5)
  (assert/equal (let [x 2 y (+ x 3)] (+ x y)) 7))

(test "let supports shadowing"
  (assert/equal
    (let [x 10]
      (let [x 20]
        x))
    20)
  (assert/equal
    (let [x 10]
      (let [x 20]
        (+ x 1)))
    21))

(test "let locals do not leak"
  (assert/throws
    (fn []
      (let [x 1] x)
      x)
    "undefined symbol"))

(test "let works with closures"
  (assert/equal
    (let [x 7 f (fn [y] (+ x y))]
      (f 5))
    12))
