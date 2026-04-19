(test "defn defines named functions"
  (require "../../stdlib.lisp")
  (defn add1 [x] (+ x 1))
  (assert/equal (add1 4) 5)
  (assert/equal
    (print (macroexpand-1 (quote (defn add2 [x] (+ x 2)))))
    "(def add2 (fn [x] (+ x 2)))"))

(test "defn supports multi-form bodies"
  (require "../../stdlib.lisp")
  (defn bump2 [x]
    (+ x 1)
    (+ x 2))
  (assert/equal (bump2 10) 12))

(test "defn preserves fn docstrings"
  (require "../../stdlib.lisp")
  (assert/equal
    (print (macroexpand-1 (quote (defn greet2 [name] "Build a greeting string." name))))
    "(def greet2 (fn [name] \"Build a greeting string.\" name))")
  (defn greet [name]
    "Build a greeting string."
    (if name
      "hello"
      "hi"))
  (assert/equal (doc greet) "Build a greeting string."))
