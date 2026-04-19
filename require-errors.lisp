(test "require requires a string path"
  (assert/throws (fn [] (require 123)) "require requires a string path")
  (assert/throws (fn [] (require nil)) "require requires a string path")
  (assert/throws (fn [] (require {:path "x"})) "require requires a string path"))

(test "require arity"
  (assert/throws (fn [] (require)) "require requires exactly one argument")
  (assert/throws (fn [] (require "a" "b")) "require requires exactly one argument"))

(test "require fails for missing file"
  (assert/throws (fn [] (require "fixtures/require/does-not-exist.lisp")) "file not found"))

(test "require surfaces parser errors from loaded file"
  (assert/throws (fn [] (require "fixtures/require/invalid-syntax.lisp")) "unexpected end of input"))

(test "require does not cache failed loads — side effects run each time"
  (def require_fail_count 0)
  (assert/throws (fn [] (require "fixtures/require/throws.lisp")) "boom")
  (assert/equal require_fail_count 1)
  (assert/throws (fn [] (require "fixtures/require/throws.lisp")) "boom")
  (assert/equal require_fail_count 2))

(test "require does not cache parser failures"
  (assert/throws (fn [] (require "fixtures/require/invalid-syntax.lisp")) "unexpected end of input")
  (assert/throws (fn [] (require "fixtures/require/invalid-syntax.lisp")) "unexpected end of input"))
