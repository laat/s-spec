(test "json/parse reads JSON scalars"
  (assert/equal (json/parse "1") 1)
  (assert/equal (json/parse "\"hello\"") "hello")
  (assert/equal (json/parse "true") true)
  (assert/equal (json/parse "false") false)
  (assert/equal (json/parse "null") null))

(test "json/parse reads arrays and objects"
  (assert/equal (json/parse "[1,2,3]") [1 2 3])
  (assert/equal
    (json/parse "{\"name\":\"Ada\",\"active\":true,\"tags\":[\"math\",\"logic\"]}")
    {:name "Ada" :active true :tags ["math" "logic"]}))

(test "json/stringify writes JSON values"
  (assert/equal (json/stringify 1) "1")
  (assert/equal (json/stringify "hello") "\"hello\"")
  (assert/equal (json/stringify true) "true")
  (assert/equal (json/stringify false) "false")
  (assert/equal (json/stringify null) "null")
  (assert/equal (json/stringify [1 2 3]) "[1,2,3]")
  (assert/equal
    (json/stringify {:name "Ada" :active true :tags ["math" "logic"]})
    "{\"name\":\"Ada\",\"active\":true,\"tags\":[\"math\",\"logic\"]}"))

(test "json/parse does not preserve integer/decimal distinction"
  (assert/equal (json/parse "1") (json/parse "1.0"))
  (assert/equal (json/stringify (json/parse "1.0")) "1")
  (assert/equal (json/stringify 1.0) "1")
  (assert/equal (json/stringify 1.5) "1.5"))

(test "number printing uses integer form for integral values below 1e21"
  (assert/equal (json/stringify 1.0) "1")
  (assert/equal (json/stringify 1000.0) "1000")
  (assert/equal (json/stringify 1e10) "10000000000")
  (assert/equal (json/stringify 1e15) "1000000000000000")
  (assert/equal (print 1e10) "10000000000"))

(test "number printing uses scientific form at or above 1e21"
  (assert/equal (json/stringify 1e21) "1e+21")
  (assert/equal (print 1e21) "1e+21"))

(test "number printing uses shortest round-trip decimal for non-integers"
  (assert/equal (json/stringify 0.5) "0.5")
  (assert/equal (json/stringify -0.25) "-0.25")
  (assert/equal (print 1.5) "1.5"))

(test "json boundary keeps nil distinct from null"
  (assert/equal (json/parse "null") null)
  (assert/throws (fn [] (json/stringify nil)) "json/stringify does not support nil"))

(test "json/stringify rejects non-json runtime values"
  (assert/throws (fn [] (json/stringify (list 1 2 3))) "json/stringify does not support list")
  (assert/throws (fn [] (json/stringify (fn [x] x))) "json/stringify does not support function"))
