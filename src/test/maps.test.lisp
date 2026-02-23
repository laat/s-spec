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
  (assert/equal (= {:str "hello" :num 42 :bool true :null null}
                   {:str "hello" :num 42 :bool true :null null}) true))

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

(test "keys returns a sequence"
  (def ks (keys {:a 1 :b 2}))
  (assert/equal (count ks) 2)
  (assert/equal (empty? ks) false)
  (assert/equal (or (= (first ks) :a) (= (first ks) :b)) true))

(test "vals returns a sequence"
  (def vs (vals {:a 1 :b 2}))
  (assert/equal (count vs) 2)
  (assert/equal (or (= (first vs) 1) (= (first vs) 2)) true))

(test "entries returns keyword-value pair lists"
  (def es (entries {:a 1 :b 2}))
  (def e1 (first es))
  (assert/equal (count es) 2)
  (assert/equal (or (= (first e1) :a) (= (first e1) :b)) true)
  (assert/equal (or (= (first (rest e1)) 1) (= (first (rest e1)) 2)) true)
  (assert/equal (rest (rest e1)) null))

(test "keys vals entries - empty object"
  (assert/equal (keys {}) null)
  (assert/equal (vals {}) null)
  (assert/equal (entries {}) null))

(test "keys vals entries - type errors"
  (assert/throws (fn [] (keys 42)) "keys requires an object")
  (assert/throws (fn [] (vals 42)) "vals requires an object")
  (assert/throws (fn [] (entries 42)) "entries requires an object"))

(test "has? - key presence"
  (assert/equal (has? {:a 1 :b null} :a) true)
  (assert/equal (has? {:a 1 :b null} :b) true)
  (assert/equal (has? {:a 1 :b null} :c) false)
  (assert/equal (has? {"x" 1} "x") true))

(test "assoc - set and overwrite"
  (def m {:a 1})
  (def m2 (assoc m :b 2 :a 3))
  (assert/equal (= m {:a 1}) true)
  (assert/equal (= m2 {:a 3 :b 2}) true))

(test "dissoc - remove keys immutably"
  (def m {:a 1 :b 2 :c 3})
  (def m2 (dissoc m :a :missing))
  (assert/equal (= m {:a 1 :b 2 :c 3}) true)
  (assert/equal (= m2 {:b 2 :c 3}) true))

(test "merge - shallow object merge"
  (assert/equal (= (merge {:a 1} {:b 2} {:a 9}) {:a 9 :b 2}) true)
  (assert/equal (= (merge) {}) true)
  (assert/equal (= (merge {:nested {:a 1}} {:nested {:b 2}})
                   {:nested {:b 2}}) true))

(test "select-keys - project object"
  (assert/equal (= (select-keys {:a 1 :b 2 :c 3} (list :a :c :x))
                   {:a 1 :c 3}) true)
  (assert/equal (= (select-keys {"a" 1 "b" 2} ["a"]) {"a" 1}) true)
  (assert/equal (= (select-keys {:a 1 :b 2} (keys {:b 0})) {:b 2}) true))

(test "map helpers - type and arity errors"
  (assert/throws (fn [] (has? 42 :a)) "has? requires an object as first argument")
  (assert/throws (fn [] (has? {} 42)) "has? key must be a string or keyword")
  (assert/throws (fn [] (assoc {} :a)) "assoc requires at least 3 arguments")
  (assert/throws (fn [] (assoc {} :a 1 :b)) "assoc requires key-value pairs")
  (assert/throws (fn [] (assoc {} 1 2)) "assoc key must be a string or keyword")
  (assert/throws (fn [] (dissoc 42 :a)) "dissoc requires an object as first argument")
  (assert/throws (fn [] (dissoc {} 1)) "dissoc key must be a string or keyword")
  (assert/throws (fn [] (merge {:a 1} 42)) "merge requires object arguments")
  (assert/throws (fn [] (select-keys 42 (list :a))) "select-keys requires an object as first argument")
  (assert/throws (fn [] (select-keys {} 42)) "select-keys requires keys as a list, sequence, array, or null"))

(test "maps with commas"
  (assert/equal (= {:name "John", :age 30} {:name "John" :age 30}) true)
  (assert/equal (= {:a 1, :b 2, :c 3} {:a 1 :b 2 :c 3}) true)
  (assert/equal (= {:sum (+ 1 2), :product (* 3 4)} {:sum 3 :product 12}) true)
  (assert/equal (= {:user {:name "John", :age 30}} {:user {:name "John" :age 30}}) true)
  (assert/equal (= {:a 1, :b 2 :c 3, :d 4} {:a 1 :b 2 :c 3 :d 4}) true)
  (assert/equal (= {:a 1, :b 2,} {:a 1 :b 2}) true))
