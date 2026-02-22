; Edge case tests for type guards and object handling

(test "map with :type key (user data)"
  ; Users should be able to create objects with :type key
  (def user {:type :admin :name "Alice"})
  (assert/equal (= user {:type :admin :name "Alice"}) true))

(test "map with :pos key (user data)"
  ; Users should be able to create objects with :pos key
  (def location {:pos 10 :x 5 :y 3})
  (assert/equal (= location {:pos 10 :x 5 :y 3}) true))

(test "map with both :type and :pos keys (user data)"
  ; Users should be able to create objects with both keys
  (def entity {:type :player :pos {:x 10 :y 20}})
  (assert/equal (= entity {:type :player :pos {:x 10 :y 20}}) true))

(test "map with :type string value"
  ; :type key can have any value, including strings
  (def config {:type "production" :debug false})
  (assert/equal (= config {:type "production" :debug false}) true))

(test "map with :pos object with :line and :col"
  ; Even if user creates {:pos {:line 1 :col 5}}, it should work
  ; (though this is the same structure as AST pos, the parent object differs)
  (def cursor {:pos {:line 1 :col 5} :file "foo.txt"})
  (assert/equal (= cursor {:pos {:line 1 :col 5} :file "foo.txt"}) true))

(test "nested maps with reserved keys"
  (def data {:outer {:type :inner :pos 42} :id 123})
  (assert/equal (= data {:outer {:type :inner :pos 42} :id 123}) true))

(test "map equality with :type values"
  ; Different :type values should not be equal
  (assert/equal (= {:type :foo} {:type :bar}) false)
  (assert/equal (= {:type :foo} {:type :foo}) true))
