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
