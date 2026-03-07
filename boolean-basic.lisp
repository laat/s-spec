(test "boolean literals"
  (assert/equal true true)
  (assert/equal false false)
  (assert/equal (if true true false) true)
  (assert/equal (if false true false) false))

(test "boolean values with logical forms"
  (assert/equal (and true true) true)
  (assert/equal (and true false) false)
  (assert/equal (or false true) true)
  (assert/equal (or false false) false))

(test "boolean values are distinct from nil and null"
  (assert/equal (if nil true false) false)
  (assert/equal (if null true false) true)
  (assert/equal (if false true false) false))
