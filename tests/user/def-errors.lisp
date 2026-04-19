(test "def requires a symbol name"
  (assert/throws (fn [] (def "x" 1)) "def name must be a symbol")
  (assert/throws (fn [] (def :x 1)) "def name must be a symbol")
  (assert/throws (fn [] (def [x] 1)) "def name must be a symbol"))

(test "def requires exactly two arguments"
  (assert/throws (fn [] (def x)) "def requires exactly two arguments")
  (assert/throws (fn [] (def x 1 2)) "def requires exactly two arguments"))

(test "reading undefined symbols throws"
  (assert/throws (fn [] not-defined-yet) "undefined symbol"))
