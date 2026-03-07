(test "equals arity behavior"
  (assert/equal (=) true)
  (assert/equal (= 1) true)
  (assert/equal (= 1 1 1) true)
  (assert/equal (= 1 1 2) false))

(test "equals on scalar values"
  (assert/equal (= 1 1) true)
  (assert/equal (= 1 2) false)
  (assert/equal (= "a" "a") true)
  (assert/equal (= "a" "b") false)
  (assert/equal (= true true) true)
  (assert/equal (= true false) false)
  (assert/equal (= null null) true)
  (assert/equal (= nil nil) true)
  (assert/equal (= null nil) false)
  (assert/equal (= false nil) false))

(test "nil is distinct from empty values"
  (assert/equal (= nil "") false)
  (assert/equal (= nil []) false)
  (assert/equal (= nil {}) false)
  (assert/equal (= nil null) false))

(test "empty values compare by type"
  (assert/equal (= "" "") true)
  (assert/equal (= [] []) true)
  (assert/equal (= {} {}) true)
  (assert/equal (= "" []) false)
  (assert/equal (= [] {}) false))

(test "equals is deep for arrays lists and objects"
  (assert/equal (= [1 [2 3] {:a 4}] [1 [2 3] {:a 4}]) true)
  (assert/equal (= (list 1 (list 2 3)) (list 1 (list 2 3))) true)
  (assert/equal (= {:a [1 2] :b {:c 3}} {:a [1 2] :b {:c 3}}) true)
  (assert/equal (= [1 2 3] [1 2 4]) false)
  (assert/equal (= (list 1 2) (list 1 3)) false)
  (assert/equal (= {:a 1} {:a 2}) false))

(test "object equality ignores key order"
  (assert/equal (= {:a 1 :b 2} {:b 2 :a 1}) true)
  (assert/equal (= {:x {:a 1 :b 2}} {:x {:b 2 :a 1}}) true)
  (assert/equal (= {:a 1 :b 2} {:a 1 :b 3}) false))

(test "not-equals operator"
  (assert/equal (/=) false)
  (assert/equal (/= 1) false)
  (assert/equal (/= 1 2) true)
  (assert/equal (/= 1 1) false)
  (assert/equal (/= nil "") true)
  (assert/equal (/= {:a 1 :b 2} {:b 2 :a 1}) false))
