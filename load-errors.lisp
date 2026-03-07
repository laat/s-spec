(test "load requires a string path"
  (assert/throws (fn [] (load 123)) "load requires a string path")
  (assert/throws (fn [] (load nil)) "load requires a string path")
  (assert/throws (fn [] (load {:path "x"})) "load requires a string path"))

(test "load fails for missing file"
  (assert/throws (fn [] (load "fixtures/load/does-not-exist.lisp")) "file not found"))

(test "load surfaces parser errors from loaded file"
  (assert/throws (fn [] (load "fixtures/load/invalid-syntax.lisp")) "unexpected end of input"))
