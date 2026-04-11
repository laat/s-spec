(test "object literal requires key/value pairs"
  (assert/throws (fn [] (parse "{:a}")) "requires an even number of forms")
  (assert/throws (fn [] (parse "{:a 1 :b}")) "requires an even number of forms"))

(test "object literal keys must be keywords"
  (assert/throws (fn [] (parse "{\"a\" 1}")) "object keys must be keywords")
  (assert/throws (fn [] (parse "{1 2}")) "object keys must be keywords")
  (assert/throws (fn [] (parse "{null 1}")) "object keys must be keywords")
  (assert/throws (fn [] (parse "{[1] 2}")) "object keys must be keywords"))

(test "parse rejects malformed delimiters"
  (assert/throws (fn [] (parse "[1 2")) "unexpected end of input")
  (assert/throws (fn [] (parse "{:a 1")) "unexpected end of input")
  (assert/throws (fn [] (parse "(+ 1 2")) "unexpected end of input")
  (assert/throws (fn [] (parse "]")) "unexpected closing delimiter")
  (assert/throws (fn [] (parse "}")) "unexpected closing delimiter")
  (assert/throws (fn [] (parse ")")) "unexpected closing delimiter"))

(test "parse rejects malformed strings"
  (assert/throws (fn [] (parse "\"unterminated")) "unterminated string")
  (assert/throws (fn [] (parse "{:\"bad key 1}")) "unterminated string"))

(test "parse rejects malformed keywords"
  (assert/throws (fn [] (parse ":")) "invalid keyword")
  (assert/throws (fn [] (parse "{: 1}")) "invalid keyword")
  (assert/throws (fn [] (parse "{:\"bad 1}")) "unterminated string")
  (assert/throws (fn [] (parse "{:\"bad\\q\" 1}")) "invalid string escape"))

(test "parse rejects malformed fn forms"
  (assert/throws (fn [] (parse "(fn x (+ x 1))")) "fn params must be a vector")
  (assert/throws (fn [] (parse "(fn [x y] )")) "fn requires a body")
  (assert/throws (fn [] (parse "(fn [] )")) "fn requires a body"))

(test "parse rejects malformed def forms"
  (assert/throws (fn [] (parse "(def)")) "def requires exactly two arguments")
  (assert/throws (fn [] (parse "(def x)")) "def requires exactly two arguments")
  (assert/throws (fn [] (parse "(def x 1 2)")) "def requires exactly two arguments"))


(test "parse rejects malformed if forms"
  (assert/throws (fn [] (parse "(if)")) "if requires exactly three arguments")
  (assert/throws (fn [] (parse "(if true 1)")) "if requires exactly three arguments")
  (assert/throws (fn [] (parse "(if true 1 2 3)")) "if requires exactly three arguments"))

(test "parse rejects malformed defmacro forms"
  (assert/throws (fn [] (parse "(defmacro)")) "defmacro requires a name, params, and body")
  (assert/throws (fn [] (parse "(defmacro m)")) "defmacro requires a name, params, and body")
  (assert/throws (fn [] (parse "(defmacro m [x])")) "defmacro requires a body")
  (assert/throws (fn [] (parse "(defmacro m x x)")) "defmacro params must be a vector"))


(test "parse rejects malformed quote-family forms"
  (assert/throws (fn [] (parse "(quote)")) "quote requires exactly one argument")
  (assert/throws (fn [] (parse "(quote a b)")) "quote requires exactly one argument")
  (assert/throws (fn [] (parse "(quasiquote)")) "quasiquote requires exactly one argument")
  (assert/throws (fn [] (parse "(quasiquote a b)")) "quasiquote requires exactly one argument")
  (assert/throws (fn [] (parse "(unquote)")) "unquote requires exactly one argument")
  (assert/throws (fn [] (parse "(unquote a b)")) "unquote requires exactly one argument")
  (assert/throws (fn [] (parse "(splice-unquote)")) "splice-unquote requires exactly one argument")
  (assert/throws (fn [] (parse "(splice-unquote a b)")) "splice-unquote requires exactly one argument"))
