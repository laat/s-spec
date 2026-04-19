(test "json/parse rejects malformed JSON delimiters"
  (assert/throws (fn [] (json/parse "[1,2")) "unexpected end of input")
  (assert/throws (fn [] (json/parse "{\"a\":1")) "unexpected end of input")
  (assert/throws (fn [] (json/parse "]")) "unexpected token")
  (assert/throws (fn [] (json/parse "}")) "unexpected token"))

(test "json/parse rejects trailing commas"
  (assert/throws (fn [] (json/parse "[1,2,]")) "trailing comma")
  (assert/throws (fn [] (json/parse "{\"a\":1,}")) "trailing comma"))

(test "json/parse rejects invalid object forms"
  (assert/throws (fn [] (json/parse "{a:1}")) "object keys must be strings")
  (assert/throws (fn [] (json/parse "{\"a\" 1}")) "expected ':'")
  (assert/throws (fn [] (json/parse "{\"a\":}")) "expected value"))

(test "json/parse rejects invalid array forms"
  (assert/throws (fn [] (json/parse "[1 2]")) "expected ',' or ']'" )
  (assert/throws (fn [] (json/parse "[,1]")) "expected value"))

(test "json/parse rejects invalid numbers and literals"
  (assert/throws (fn [] (json/parse "01")) "invalid number")
  (assert/throws (fn [] (json/parse "1.")) "invalid number")
  (assert/throws (fn [] (json/parse "+1")) "invalid number")
  (assert/throws (fn [] (json/parse "tru")) "invalid literal")
  (assert/throws (fn [] (json/parse "nul")) "invalid literal"))

(test "json/parse rejects unterminated strings and bad escapes"
  (assert/throws (fn [] (json/parse "\"unterminated")) "unterminated string")
  (assert/throws (fn [] (json/parse "\"bad\\q\"")) "invalid string escape"))
