(test "defmacroonce defines macro when unbound"
  (require "stdlib.lisp")
  (defmacroonce twice [x]
    (quasiquote (+ (unquote x) (unquote x))))
  (assert/equal (twice 4) 8)
  (assert/equal
    (print (macroexpand-1 (quote (twice 3))))
    "(+ 3 3)"))

(test "defmacroonce does not overwrite existing macro"
  (require "stdlib.lisp")
  (defmacroonce pick-left [a b]
    (quasiquote (unquote a)))
  (assert/equal (pick-left 1 2) 1)
  (defmacroonce pick-left [a b]
    (quasiquote (unquote b)))
  (assert/equal (pick-left 1 2) 1))

(test "defmacroonce does not evaluate body when symbol is already bound"
  (require "stdlib.lisp")
  (defmacroonce stable/m [x]
    (quasiquote (unquote x)))
  (defmacroonce stable/m [x]
    (not-defined)
    (quasiquote (unquote x)))
  (assert/equal (stable/m 9) 9))

(test "defmacroonce treats any existing binding as bound"
  (require "stdlib.lisp")
  (defonce occupied/value 12)
  (assert/equal
    (defmacroonce occupied/value [x]
      (quasiquote (unquote x)))
    12)
  (assert/equal occupied/value 12))

(test "defmacroonce treats nil binding as already bound"
  (require "stdlib.lisp")
  (defonce maybe/macro nil)
  (assert/equal
    (defmacroonce maybe/macro [x]
      (quasiquote (unquote x)))
    nil)
  (assert/equal maybe/macro nil))
