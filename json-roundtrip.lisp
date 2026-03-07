(test "json roundtrip: parse then stringify"
  (assert/equal
    (json/stringify (json/parse "1"))
    "1")
  (assert/equal
    (json/stringify (json/parse "\"hello\""))
    "\"hello\"")
  (assert/equal
    (json/stringify (json/parse "[1,2,3]"))
    "[1,2,3]")
  (assert/equal
    (json/stringify (json/parse "{\"a\":1,\"b\":true,\"c\":null}"))
    "{\"a\":1,\"b\":true,\"c\":null}"))

(test "json roundtrip: stringify then parse"
  (assert/equal
    (json/parse (json/stringify 1))
    1)
  (assert/equal
    (json/parse (json/stringify "hello"))
    "hello")
  (assert/equal
    (json/parse (json/stringify [1 2 3]))
    [1 2 3])
  (assert/equal
    (json/parse (json/stringify {:name "Ada" :active true :meta {:score 7}}))
    {:name "Ada" :active true :meta {:score 7}}))

(test "json roundtrip preserves null and does not introduce nil"
  (assert/equal
    (json/parse (json/stringify {:x null :y [1 null 3]}))
    {:x null :y [1 null 3]})
  (assert/equal
    (= (json/parse "null") nil)
    false))
