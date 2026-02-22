; Map/object tests ported from maps.test.ts

(test "empty map"
  (assert/equal (= {} {}) true))

(test "map with keyword keys"
  (assert/equal (= {:name "John" :age 30} {:name "John" :age 30}) true)
  (assert/equal (= {:x 42} {:x 42}) true))

(test "map with quoted keyword keys"
  (assert/equal (= {:"first name" "John"} {:"first name" "John"}) true)
  (assert/equal (= {:"" "value"} {:"" "value"}) true)
  (assert/equal (= {:"key.with.dots" 1} {:"key.with.dots" 1}) true))

(test "map with string keys"
  (assert/equal (= {"name" "John" "age" 30} {"name" "John" "age" 30}) true)
  (assert/equal (= {:kw-key 1 "str-key" 2} {:kw-key 1 "str-key" 2}) true))

(test "map with mixed value types"
  (assert/equal (= {:str "hello" :num 42 :bool true :nil nil}
                   {:str "hello" :num 42 :bool true :nil nil}) true))

(test "map with keyword values"
  (assert/equal (= {:status :active :type :user} {:status :active :type :user}) true))

(test "map with computed values"
  (assert/equal (= {:sum (+ 1 2) :product (* 3 4)} {:sum 3 :product 12}) true))

(test "map with variable values"
  (def x 10)
  (def y 20)
  (assert/equal (= {:x x :y y} {:x 10 :y 20}) true))

(test "nested maps"
  (assert/equal (= {:user {:name "John" :age 30}} {:user {:name "John" :age 30}}) true)
  (assert/equal (= {:a {:b {:c 1}}} {:a {:b {:c 1}}}) true))

(test "map equality - same maps"
  (assert/equal (= {:a 1} {:a 1}) true)
  (assert/equal (= {:x 1 :y 2} {:x 1 :y 2}) true)
  (assert/equal (= {} {}) true))

(test "map equality - different maps"
  (assert/equal (= {:a 1} {:a 2}) false)
  (assert/equal (= {:a 1} {:b 1}) false)
  (assert/equal (= {:x 1} {:x 1 :y 2}) false))

(test "map equality - nested maps"
  (assert/equal (= {:a {:b 1}} {:a {:b 1}}) true)
  (assert/equal (= {:a {:b 1}} {:a {:b 2}}) false))

(test "map equality - with keyword values"
  (assert/equal (= {:status :ok} {:status :ok}) true)
  (assert/equal (= {:status :ok} {:status :error}) false))

(test "map equality - order independent"
  (assert/equal (= {:a 1 :b 2} {:b 2 :a 1}) true))

(test "map from function"
  (defn make-user [name age] {:name name :age age})
  (assert/equal (= (make-user "John" 30) {:name "John" :age 30}) true))

(test "map as function argument"
  (defn get-user [user] user)
  (assert/equal (= (get-user {:name "John"}) {:name "John"}) true))

(test "map with def"
  (def user {:name "John" :age 30})
  (assert/equal (= user {:name "John" :age 30}) true))

; Note: Parser-level errors (odd number of elements, invalid key types)
; cannot be tested in Lisp since they're caught at parse time, not runtime.
; These errors are tested in the TypeScript test suite.

(test "map in expressions"
  (assert/equal (= (if true {:x 1} {:y 2}) {:x 1}) true)
  (assert/equal (= (and true {:x 1}) {:x 1}) true))

(test "maps with commas"
  (assert/equal (= {:name "John", :age 30} {:name "John" :age 30}) true)
  (assert/equal (= {:a 1, :b 2, :c 3} {:a 1 :b 2 :c 3}) true)
  (assert/equal (= {:sum (+ 1 2), :product (* 3 4)} {:sum 3 :product 12}) true)
  (assert/equal (= {:user {:name "John", :age 30}} {:user {:name "John" :age 30}}) true)
  (assert/equal (= {:a 1, :b 2 :c 3, :d 4} {:a 1 :b 2 :c 3 :d 4}) true)
  (assert/equal (= {:a 1, :b 2,} {:a 1 :b 2}) true))
