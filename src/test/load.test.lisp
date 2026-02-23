; Load tests ported from load.test.ts
; Note: These tests use relative paths to fixtures directory

(test "load - loads a file and makes definitions available"
  (load "src/test/fixtures/simple.lisp")
  (assert/equal loaded-value 42))

(test "load - loaded functions are callable"
  (load "src/test/fixtures/simple.lisp")
  (assert/equal (loaded-function 5) 10))

(test "load - returns null"
  (assert/equal (load "src/test/fixtures/simple.lisp") null))

(test "load - can load relative paths from loaded files"
  (load "src/test/fixtures/with-deps.lisp")
  (assert/equal combined-value 52))

(test "load - is idempotent (loads each file only once)"
  ; Load the same file multiple times
  (load "src/test/fixtures/counter.lisp")
  (load "src/test/fixtures/counter.lisp")
  (load "src/test/fixtures/counter.lisp")
  (assert/equal counter-loaded true))

(test "load - error on non-string argument"
  (assert/throws (fn [] (load 123)) "load requires a string"))

(test "load - error on missing file"
  (assert/throws (fn [] (load "/nonexistent/file.lisp")) "ENOENT"))

(test "load - error on wrong arity"
  (assert/throws (fn [] (load)) "load requires 1 argument")
  (assert/throws (fn [] (load "a.lisp" "b.lisp")) "load requires 1 argument"))

(test "load - naming convention for organization"
  (load "src/test/fixtures/validators.lisp")
  (assert/equal (email/validate "user@example.com") true))

(test "load - naming convention allows slashes in symbols"
  (load "src/test/fixtures/validators.lisp")
  (assert/equal (user/valid-age? 21) true))

(test "load - naming convention with false result"
  (load "src/test/fixtures/validators.lisp")
  (assert/equal (user/valid-age? 15) false))
