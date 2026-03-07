(defonce let/expand
  (fn [bindings idx body-forms]
    (if (= idx (length bindings))
      (quasiquote (do (splice-unquote body-forms)))
      (quasiquote
        ((fn [(unquote (get bindings idx))]
           (unquote (let/expand bindings (+ idx 2) body-forms)))
         (unquote (get bindings (+ idx 1))))))))

(defmacroonce let [bindings & body]
  "Sequential local bindings with arbitrary length and multi-form bodies."
  (let/expand bindings 0 body))

(defmacroonce when [pred then]
  "Evaluate then when pred is truthy."
  (quasiquote
    (if (unquote pred)
      (unquote then)
      nil)))

(defmacroonce when-not [pred then]
  "Evaluate then when pred is falsey."
  (quasiquote
    (if (unquote pred)
      nil
      (unquote then))))

(defmacroonce unless [pred then else]
  "Evaluate then when pred is falsey, else evaluate else."
  (quasiquote
    (if (unquote pred)
      (unquote else)
      (unquote then))))

(defmacroonce if-not [pred then else]
  "Inverse of if."
  (quasiquote
    (if (unquote pred)
      (unquote else)
      (unquote then))))

(defmacroonce or-else [a b]
  "Evaluate a once; return it when truthy, else b."
  (let [g (gensym "or")]
    (quasiquote
      (let [(unquote g) (unquote a)]
        (if (unquote g)
          (unquote g)
          (unquote b))))))

(defmacroonce and-then [a b]
  "Evaluate a once; return b when a is truthy, else return a."
  (let [g (gensym "and")]
    (quasiquote
      (let [(unquote g) (unquote a)]
        (if (unquote g)
          (unquote b)
          (unquote g))))))

(defmacroonce defn [name params & body]
  "Define a named function; expands to def + fn."
  (quasiquote
    (def (unquote name)
      (fn (unquote params)
        (splice-unquote body)))))
