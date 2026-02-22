; Test utilities for s-spec
; This file is only loaded in test environments

; Convenience macro for defining tests
; Wraps the body in a function automatically
; Supports multiple assertions per test
;
; Usage:
;   (test "my test name"
;     (assert/equal (+ 1 2) 3 "addition works")
;     (assert/equal (+ 2 3) 5 "more addition"))
;
; Expands to:
;   (test/test "my test name" (fn []
;     (do
;       (assert/equal (+ 1 2) 3 "addition works")
;       (assert/equal (+ 2 3) 5 "more addition"))))

(defmacro test [name &rest body]
  (quasiquote (test/test (unquote name) (fn [] (do (unquote-splicing body))))))
