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
