(test "truthiness contract"
  (assert/equal (if false :then :else) :else)
  (assert/equal (if nil :then :else) :else)
  (assert/equal (if null :then :else) :then)
  (assert/equal (if 0 :then :else) :then)
  (assert/equal (if "" :then :else) :then)
  (assert/equal (if [] :then :else) :then)
  (assert/equal (if {} :then :else) :then)
  (assert/equal (if :k :then :else) :then)
  (assert/equal (if (quote x) :then :else) :then)
  (assert/equal (if (fn [] 1) :then :else) :then)
  (assert/equal (if + :then :else) :then))

(test "function arguments evaluate left to right"
  (require "stdlib.lisp")
  (def counter 0)
  (def tick
    (fn []
      (let [current counter]
        (def counter (+ counter 1))
        current)))
  (assert/equal [(tick) (tick) (tick)] [0 1 2]))

(test "def inside function updates global binding"
  (def global-value 1)
  ((fn [] (def global-value 2)))
  (assert/equal global-value 2))

(test "let bindings evaluate sequentially"
  (require "stdlib.lisp")
  (assert/equal
    (let [x 1
          y (+ x 1)
          z (+ y 1)]
      z)
    3))

(test "macro expansion contract"
  (defmacro literal-form [x]
    (quasiquote (quote (unquote x))))
  (assert/equal (print (literal-form (+ 1 2))) "(+ 1 2)")
  (assert/equal
    (print (macroexpand-1 (quote (literal-form (+ 1 2)))))
    "(quote (+ 1 2))")
  (assert/equal
    (print (macroexpand (quote (literal-form (+ 1 2)))))
    "(quote (+ 1 2))"))

(test "assert-throws matches substring"
  (assert/throws (fn [] (:key 123)) "requires an object"))

(test "test env can define local globals"
  (def contract-leak-check 42)
  (assert/equal contract-leak-check 42))

(test "test env does not leak definitions"
  (assert/throws (fn [] contract-leak-check) "undefined symbol"))
