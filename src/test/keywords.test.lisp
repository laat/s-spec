; Keyword tests ported from keywords.test.ts

(test "simple keyword literals"
  ; Note: In Lisp we can't check the internal structure like TypeScript,
  ; but we can verify keywords work correctly with equality
  (assert/equal (= :foo :foo) true)
  (assert/equal (= :name :name) true)
  (assert/equal (= :age :age) true)
  (assert/equal (= :user-id :user-id) true))

(test "quoted keyword literals"
  (assert/equal (= :"my key" :"my key") true)
  (assert/equal (= :"" :"") true)
  (assert/equal (= :"with spaces" :"with spaces") true)
  (assert/equal (= :"key-with-dashes" :"key-with-dashes") true)
  (assert/equal (= :"key.with.dots" :"key.with.dots") true)
  (assert/equal (= :"quote\"inside" :"quote\"inside") true))

(test "keyword equality - different keywords"
  (assert/equal (= :foo :bar) false)
  (assert/equal (= :name :age) false)
  (assert/equal (= :"key1" :"key2") false))

(test "keyword equality - multiple args"
  (assert/equal (= :foo :foo :foo) true)
  (assert/equal (= :foo :foo :bar) false))

(test "keyword with def"
  (def x :active)
  (assert/equal (= x :active) true)
  (assert/equal (= x :inactive) false))

(test "keyword as return value"
  (defn status [] :ok)
  (assert/equal (= (status) :ok) true))

(test "keyword as function argument"
  (defn is-active [status] (= status :active))
  (assert/equal (is-active :active) true)
  (assert/equal (is-active :inactive) false))

(test "keyword with logical operators"
  (assert/equal (= (and :foo :bar) :bar) true)
  (assert/equal (= (or false :foo) :foo) true))

(test "keyword with if"
  (def status :success)
  (assert/equal (if (= status :success) "ok" "error") "ok"))

(test "keyword not equal to string"
  (assert/equal (= :foo "foo") false)
  (assert/equal (= :"my key" "my key") false))

; Keyword-as-function tests (Clojure-style)

(test "keyword-as-function - basic lookup"
  (assert/equal (:nisse {:nisse "far"}) "far")
  (assert/equal (:name {:name "John"}) "John")
  (assert/equal (:age {:age 30}) 30))

(test "keyword-as-function - missing key returns null"
  (assert/equal (:missing {:nisse "far"}) null)
  (assert/equal (:foo {}) null))

(test "keyword-as-function - with default value"
  (assert/equal (:missing {:nisse "far"} "default") "default")
  (assert/equal (:foo {} "not-found") "not-found")
  (assert/equal (:bar {:baz 1} 99) 99))

(test "keyword-as-function - default not used when key exists"
  (assert/equal (:nisse {:nisse "far"} "default") "far")
  (assert/equal (:age {:age 0} 99) 0))


(test "keyword-as-function - nested maps"
  (def data {:user {:name "John" :age 30}})
  (assert/equal (:name (:user data)) "John")
  (assert/equal (:age (:user data)) 30))

(test "keyword-as-function - with variables"
  (def k :age)
  (def m {:age 25})
  (assert/equal (k m) 25))

(test "keyword-as-function - error on non-object"
  (assert/throws (fn [] (:key "not-an-object")) "requires an object")
  (assert/throws (fn [] (:key 123)) "requires an object")
  (assert/throws (fn [] (:key null)) "requires an object"))

(test "keyword-as-function - error on wrong arity"
  (assert/throws (fn [] (:key)) "requires 1 or 2 arguments")
  (assert/throws (fn [] (:key {} {} {})) "requires 1 or 2 arguments"))

(test "keyword-as-function - quoted keywords"
  (assert/equal (:"my key" {:"my key" "value"}) "value")
  (assert/equal (:"" {:"" "empty-key"}) "empty-key"))

; get builtin with default parameter

(test "get with default parameter"
  (assert/equal (get {:foo "bar"} :foo "default") "bar")
  (assert/equal (get {} :missing "default") "default")
  (assert/equal (get {:x null} :x "default") null)
  (assert/equal (get {:y 0} :y "default") 0))
