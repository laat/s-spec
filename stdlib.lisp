(defmacro defonce [& args]
  "Define name only when it is not already bound."
  (if (/= (length args) 2)
    (error "defonce requires exactly two arguments")
    ((fn [name value]
       (if (symbol? name)
         (quasiquote
           (if (bound? (quote (unquote name)))
             (unquote name)
             (def (unquote name) (unquote value))))
         (error "defonce name must be a symbol")))
     (first args) (first (rest args)))))

(defmacro defmacroonce [& args]
  "Define macro only when name is not already bound."
  (if (= (length args) 0)
    (error "defmacroonce requires a name, params, and body")
    (if (= (length args) 1)
      (error "defmacroonce requires a name, params, and body")
      ((fn [name params body-forms]
         (if (= (length body-forms) 0)
           (if (array? params)
             (error "defmacroonce requires a body")
             (error "defmacroonce params must be a vector"))
           (if (symbol? name)
             (if (array? params)
               (quasiquote
                 (if (bound? (quote (unquote name)))
                   (unquote name)
                   (defmacro (unquote name) (unquote params)
                     (splice-unquote body-forms))))
               (error "defmacroonce params must be a vector"))
             (error "defmacroonce name must be a symbol"))))
       (first args) (first (rest args)) (rest (rest args))))))

(defonce let/expand
  (fn [bindings idx body-forms]
    (if (= idx (length bindings))
      (quasiquote (do (splice-unquote body-forms)))
      (if (= (+ idx 1) (length bindings))
        (error "let requires an even number of binding forms")
        (if (symbol? (get bindings idx))
          (quasiquote
            ((fn [(unquote (get bindings idx))]
               (unquote (let/expand bindings (+ idx 2) body-forms)))
             (unquote (get bindings (+ idx 1)))))
          (error "let binding name must be a symbol"))))))

(defmacroonce let [bindings & body]
  "Sequential local bindings with arbitrary length and multi-form bodies."
  (if (array? bindings)
    (if (nil? body)
      (error "let requires a body")
      (let/expand bindings 0 body))
    (error "let bindings must be a vector")))

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
