; Logical operator tests ported from logical.test.ts

(test "boolean literals"
  (assert/equal true true)
  (assert/equal false false)
  (assert/equal nil nil))

(test "and - all truthy"
  (assert/equal (and true true) true)
  (assert/equal (and 1 2 3) 3)
  (assert/equal (and "a" "b" "c") "c"))

(test "and - with falsy"
  (assert/equal (and true false) false)
  (assert/equal (and 1 nil 3) nil)
  (assert/equal (and false 2) false)
  (assert/equal (and 1 2 false 3) false))

(test "and - empty and single arg"
  (assert/equal (and) true)
  (assert/equal (and true) true)
  (assert/equal (and false) false)
  (assert/equal (and nil) nil)
  (assert/equal (and 42) 42))

(test "or - with truthy"
  (assert/equal (or false true) true)
  (assert/equal (or nil 2) 2)
  (assert/equal (or 1 2 3) 1)
  (assert/equal (or false nil 3) 3))

(test "or - all falsy"
  (assert/equal (or false false) false)
  (assert/equal (or nil false) false)
  (assert/equal (or false nil) nil))

(test "or - empty and single arg"
  (assert/equal (or) nil)
  (assert/equal (or true) true)
  (assert/equal (or false) false)
  (assert/equal (or nil) nil)
  (assert/equal (or 42) 42))

(test "nil punning - 0 and empty string are truthy"
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
  (assert/equal (or nil (- 10 5)) 5))
