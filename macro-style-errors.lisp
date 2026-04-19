(test "macro style error: expansion can violate let contract"
  (require "stdlib.lisp")
  (defmacro bad-let [x]
    (quasiquote (let [123 (unquote x)] 0)))
  (assert/throws (fn [] (bad-let 1)) "let binding name must be a symbol"))

(test "macro style error: nested unquote in splice-unquote"
  (defmacro bad-splice [x]
    (quasiquote [1 (splice-unquote (unquote x)) 3]))
  (assert/throws (fn [] (bad-splice 2)) "unquote outside quasiquote"))

(test "macro style error: generated code can fail by wrong assumptions"
  (defmacro key-access [k obj]
    (quasiquote ((unquote k) (unquote obj))))
  (assert/throws (fn [] (key-access :name null)) "requires an object"))
