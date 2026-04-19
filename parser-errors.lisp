(test "object literal requires key/value pairs"
  (assert/throws (fn [] (parse "{:a}")) "requires an even number of forms")
  (assert/throws (fn [] (parse "{:a 1 :b}")) "requires an even number of forms"))

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

