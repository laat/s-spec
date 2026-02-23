; Logical operator tests ported from logical.test.ts

(test "boolean literals"
  (assert/equal true true)
  (assert/equal false false)
  (assert/equal null null))

(test "and - all truthy"
  (assert/equal (and true true) true)
  (assert/equal (and 1 2 3) 3)
  (assert/equal (and "a" "b" "c") "c"))

(test "and - with falsy"
  (assert/equal (and true false) false)
  (assert/equal (and 1 null 3) null)
  (assert/equal (and false 2) false)
  (assert/equal (and 1 2 false 3) false))

(test "and - empty and single arg"
  (assert/equal (and) true)
  (assert/equal (and true) true)
  (assert/equal (and false) false)
  (assert/equal (and null) null)
  (assert/equal (and 42) 42))

(test "or - with truthy"
  (assert/equal (or false true) true)
  (assert/equal (or null 2) 2)
  (assert/equal (or 1 2 3) 1)
  (assert/equal (or false null 3) 3))

(test "or - all falsy"
  (assert/equal (or false false) false)
  (assert/equal (or null false) false)
  (assert/equal (or false null) null))

(test "or - empty and single arg"
  (assert/equal (or) null)
  (assert/equal (or true) true)
  (assert/equal (or false) false)
  (assert/equal (or null) null)
  (assert/equal (or 42) 42))

(test "null punning - 0 and empty string are truthy"
  (assert/equal (and 0 1) 1)
  (assert/equal (or 0 2) 0)
  (assert/equal (and "" "x") "x")
  (assert/equal (or "" "x") ""))

(test "nested logical ops"
  (assert/equal (and (or false 1) (or 2 3)) 2)
  (assert/equal (or (and false 1) (and 2 3)) 3)
  (assert/equal (and (and 1 2) (and 3 4)) 4))

(test "logical ops with arithmetic"
  (assert/equal (and (+ 1 2) (* 3 4)) 12)
  (assert/equal (or null (- 10 5)) 5))
