(test "defonce binds value when symbol is unbound"
  (assert/equal (defonce app/version 1) 1)
  (assert/equal app/version 1))

(test "defonce does not overwrite existing binding"
  (assert/equal (defonce build/id 10) 10)
  (assert/equal (defonce build/id 20) 10)
  (assert/equal build/id 10))

(test "defonce does not evaluate value when already bound"
  (defonce stable/value 7)
  (assert/equal
    (defonce stable/value
      (do
        (not-defined)
        99))
    7)
  (assert/equal stable/value 7))

(test "defonce can bind function values"
  (defonce add/one (fn [x] (+ x 1)))
  (assert/equal (add/one 5) 6)
  (assert/equal (defonce add/one (fn [x] (+ x 2))) add/one)
  (assert/equal (add/one 5) 6))

(test "defonce treats nil as already bound"
  (assert/equal (defonce maybe/value nil) nil)
  (assert/equal (defonce maybe/value 42) nil)
  (assert/equal maybe/value nil))
