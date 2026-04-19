(test "object literals with keyword keys"
  (assert/equal {} {})
  (assert/equal {:foo 1} {:foo 1})
  (assert/equal {:"foo" 1} {:foo 1})
  (assert/equal {:"foo bar" 2} {:"foo bar" 2}))

(test "object values can be nested"
  (assert/equal
    {:user {:name "Ada" :tags ["math" "logic"]} :active true}
    {:user {:name "Ada" :tags ["math" "logic"]} :active true}))

(test "get returns nil for missing keys"
  (assert/equal (get {:a 1 :b null} :a) 1)
  (assert/equal (get {:a 1 :b null} :b) null)
  (assert/equal (get {:a 1 :b null} :c) nil)
  (assert/equal (get {:a 1} :c "fallback") "fallback"))

(test "get with non-keyword key on object returns default"
  (assert/equal (get {:a 1} 0) nil)
  (assert/equal (get {:a 1} "a") nil)
  (assert/equal (get {:a 1} 0 :missing) :missing)
  (assert/equal (get {:a 1} "a" :missing) :missing))

(test "keywords are callable"
  (assert/equal (:a {:a 1 :b 2}) 1)
  (assert/equal (:b {:a 1 :b null}) null)
  (assert/equal (:c {:a 1 :b 2}) nil)
  (assert/equal (:c {:a 1 :b 2} "fallback") "fallback"))

(test "keyword-as-function - error on non-object"
  (assert/throws (fn [] (:key "not-an-object")) "requires an object")
  (assert/throws (fn [] (:key 123)) "requires an object")
  (assert/throws (fn [] (:key null)) "requires an object")
  (assert/throws (fn [] (:key nil)) "requires an object")
  (assert/throws (fn [] (:key [1 2 3])) "requires an object")
  (assert/throws (fn [] (:key (list 1 2 3))) "requires an object"))

(test "duplicate keys are last-write-wins"
  (assert/equal {:a 1 :a 2} {:a 2})
  (assert/equal (get {:a 1 :a 2} :a) 2)
  (assert/equal (:a {:a 1 :a 2}) 2))

(test "print preserves insertion order"
  (assert/equal
    (print (parse "{:z 1 :a 2 :m 3}"))
    "{:z 1 :a 2 :m 3}"))

(test "object keys must be keywords"
  (assert/throws (fn [] {"a" 1}) "object keys must be keywords")
  (assert/throws (fn [] {1 2}) "object keys must be keywords")
  (assert/throws (fn [] {null 1}) "object keys must be keywords")
  (assert/throws (fn [] {[1] 2}) "object keys must be keywords"))

(test "object literal and constructor"
  (assert/equal {} (object))
  (assert/equal {:a 1} (object :a 1))
  (assert/equal {:a 1 :b 2} (object :a 1 :b 2)))

(test "object constructor validates arity and key type"
  (assert/throws (fn [] (object :a)) "object arity mismatch")
  (assert/throws (fn [] (object :a 1 :b)) "object arity mismatch")
  (assert/throws (fn [] (object "a" 1)) "object keys must be keywords")
  (assert/throws (fn [] (object 1 2)) "object keys must be keywords"))

(test "quoted object literal equals runtime object"
  (assert/equal (quote {:a 1}) {:a 1})
  (assert/equal (quote {:a 1}) (quote {:a 1}))
  (assert/equal (= (quote {:a 1}) (object :a 1)) true))
