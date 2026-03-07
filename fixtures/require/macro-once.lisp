(def require_macro_count (+ require_macro_count 1))

(defmacroonce macro/inc2 [x]
  (quasiquote (+ (unquote x) 2)))

"require-macro-once-loaded"
