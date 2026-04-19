(test "gensym returns a symbol"
  (assert/equal (symbol? (gensym)) true)
  (assert/equal (symbol? (gensym "tmp")) true))

(test "gensym supports optional string prefix"
  (assert/equal
    (symbol? (gensym "user"))
    true)
  (assert/throws
    (fn [] (gensym 123))
    "gensym prefix must be a string"))

(test "gensym requires zero or one argument"
  (assert/throws (fn [] (gensym "a" "b")) "gensym requires zero or one argument"))

(test "gensym output format is prefix__N starting at 1"
  (assert/equal (print (gensym)) "G__1")
  (assert/equal (print (gensym)) "G__2")
  (assert/equal (print (gensym "tmp")) "tmp__3"))

(test "gensym helps avoid macro capture"
  (require "stdlib.lisp")
  (defmacro first-or-safe [a b]
    (let [g (gensym)]
      (quasiquote (let [(unquote g) (unquote a)]
                   (if (unquote g)
                     (unquote g)
                     (unquote b))))))
  (assert/equal
    (let [g 99]
      (first-or-safe false g))
    99))
