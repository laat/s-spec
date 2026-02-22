; Regex tests ported from regex.test.ts

(test "re - creates regex function"
  ; Can't check typeof in Lisp, but verify it's callable
  (def pattern (re "^[a-z]+$"))
  (assert/equal (pattern "hello") true))

(test "re - error on non-string pattern"
  (assert/throws (fn [] (re 123)) "re requires string for argument 1"))

(test "re - error on invalid pattern"
  (assert/throws (fn [] (re "[")) "Invalid regex pattern"))

(test "re - can be bound to variable"
  (def slug-re (re "^[a-z0-9-]+$"))
  (assert/equal (slug-re "hello-world") true))

(test "regex function - simple pattern match"
  (assert/equal ((re "^[a-z]+$") "hello") true)
  (assert/equal ((re "^[a-z]+$") "Hello123") false))

(test "regex function - with bound regex"
  (def slug-re (re "^[a-z0-9-]+$"))
  (assert/equal (slug-re "hello-world") true))

(test "regex function - non-string never matches"
  (assert/equal ((re "^[0-9]+$") 123) false))

(test "regex function - anchors work"
  (assert/equal ((re "^hello$") "hello") true)
  (assert/equal ((re "^hello$") "hello world") false)
  (assert/equal ((re "^he") "hello") true)
  (assert/equal ((re "lo$") "hello") true))

(test "regex function - character classes"
  (assert/equal ((re "^[a-z0-9]+$") "abc123") true)
  (assert/equal ((re "^[a-z0-9]+$") "ABC") false)
  (assert/equal ((re "^[a-z]+$") "hello!") false))

(test "regex function - negated character classes"
  (assert/equal ((re "^[^0-9]+$") "abc") true)
  (assert/equal ((re "^[^0-9]+$") "abc123") false))

(test "regex function - quantifiers"
  (assert/equal ((re "^a+$") "aaa") true)
  (assert/equal ((re "^a+$") "") false)
  (assert/equal ((re "^a*$") "") true)
  (assert/equal ((re "^a*$") "aaa") true)
  (assert/equal ((re "^a?$") "a") true)
  (assert/equal ((re "^a?$") "") true)
  (assert/equal ((re "^a?$") "aa") false))

(test "regex function - counted quantifiers"
  (assert/equal ((re "^a{3}$") "aaa") true)
  (assert/equal ((re "^a{3}$") "aa") false)
  (assert/equal ((re "^a{2,4}$") "aaa") true)
  (assert/equal ((re "^a{2,}$") "aa") true))

(test "regex function - alternation"
  (assert/equal ((re "^(cat|dog)$") "cat") true)
  (assert/equal ((re "^(cat|dog)$") "dog") true)
  (assert/equal ((re "^(cat|dog)$") "bird") false))

(test "regex function - escaping special chars"
  (assert/equal ((re "^\\.$") ".") true)
  (assert/equal ((re "^\\.$") "a") false)
  (assert/equal ((re "^a\\+b$") "a+b") true))

(test "regex function - email-like pattern"
  (assert/equal ((re "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$") "user@example.com") true)
  (assert/equal ((re "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$") "invalid") false))

(test "regex function - error on wrong arity"
  (assert/throws (fn [] ((re "^test$") "hello" "extra")) "regex matcher requires 1 argument"))

(test "function composition - regex with if"
  (def is-valid-slug (re "^[a-z0-9-]+$"))
  (assert/equal (if (is-valid-slug "hello-world") "valid" "invalid") "valid"))

(test "function composition - regex in function"
  (defn validate-username [name]
    ((re "^[a-z0-9_]+$") name))
  (assert/equal (validate-username "user_123") true))

(test "function composition - regex as predicate"
  (def slug? (re "^[a-z0-9-]+$"))
  (defn validate-slug [s]
    (if (slug? s)
      {:valid true :value s}
      {:valid false :value s}))
  (assert/equal (= (validate-slug "hello-world") {:valid true :value "hello-world"}) true))
