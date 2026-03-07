(test "fn docstring is optional"
  (assert/equal
    (doc (fn [x] "Add one to x." (+ x 1)))
    "Add one to x.")
  (assert/equal
    (doc (fn [x] (+ x 1)))
    nil))

(test "docstring must be the first body form"
  (assert/equal
    (doc (fn [x]
           "First string is doc."
           (+ x 1)))
    "First string is doc.")
  (assert/equal
    (doc (fn [x]
           (+ x 1)
           "This is not a docstring"))
    nil))

(test "doc works on function values only"
  (assert/throws (fn [] (doc 123)) "requires a function")
  (assert/throws (fn [] (doc null)) "requires a function")
  (assert/throws (fn [] (doc {:a 1})) "requires a function"))
