(test "macro style: bind expression once"
  (require "stdlib.lisp")
  (defmacro when-some [expr then else]
    (let [v (gensym "value")]
      (quasiquote
        (let [(unquote v) (unquote expr)]
          (if (unquote v)
            (unquote then)
            (unquote else))))))
  (assert/equal (when-some (:name {:name "Ada"}) "yes" "no") "yes")
  (assert/equal (when-some (:email {:name "Ada"}) "yes" "no") "no"))

(test "macro style: use gensym for introduced locals"
  (require "stdlib.lisp")
  (defmacro or-else [a b]
    (let [g (gensym "or")]
      (quasiquote
        (let [(unquote g) (unquote a)]
          (if (unquote g)
            (unquote g)
            (unquote b))))))
  (assert/equal
    (let [or 99]
      (or-else false or))
    99))

(test "macro style: keep expansions simple"
  (defmacro unless [pred then else]
    (quasiquote
      (if (unquote pred)
        (unquote else)
        (unquote then))))
  (assert/equal (unless false 1 2) 1)
  (assert/equal (unless true 1 2) 2))
