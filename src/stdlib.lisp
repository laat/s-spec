; s-spec standard library
; Core macros and functions defined in Lisp instead of hardcoded in the interpreter

; defn - Define a named function
; Expands (defn name [params] body) to (def name (fn [params] body))
(defmacro defn [name params &rest body]
  (quasiquote (def (unquote name) (fn (unquote params) (unquote (car body))))))

; Helper functions
(defn not [x] (if x false true))
(defn empty? [x] (eq x nil))

; Arithmetic macros - provide familiar multi-arity syntax while keeping host impl simple
; These expand multi-argument arithmetic into nested binary operations

; + macro - variadic addition
(defmacro + [&rest args]
  (if (eq args nil)
    (quote 0)
    (if (eq (cdr args) nil)
      (car args)
      (if (eq (cdr (cdr args)) nil)
        (quasiquote (add (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (add (unquote (car args)) (+ (unquote-splicing (cdr args)))))))))

; - macro - variadic subtraction (left-to-right)
(defmacro - [&rest args]
  (if (eq args nil)
    (quote 0)
    (if (eq (cdr args) nil)
      (quasiquote (sub 0 (unquote (car args))))
      (if (eq (cdr (cdr args)) nil)
        (quasiquote (sub (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (- (sub (unquote (car args)) (unquote (car (cdr args)))) (unquote-splicing (cdr (cdr args)))))))))

; * macro - variadic multiplication
(defmacro * [&rest args]
  (if (eq args nil)
    (quote 1)
    (if (eq (cdr args) nil)
      (car args)
      (if (eq (cdr (cdr args)) nil)
        (quasiquote (mul (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (mul (unquote (car args)) (* (unquote-splicing (cdr args)))))))))

; / macro - variadic division (left-to-right)
(defmacro / [&rest args]
  (if (eq args nil)
    (quote 1)
    (if (eq (cdr args) nil)
      (quasiquote (div 1 (unquote (car args))))
      (if (eq (cdr (cdr args)) nil)
        (quasiquote (div (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (/ (div (unquote (car args)) (unquote (car (cdr args)))) (unquote-splicing (cdr (cdr args)))))))))

; Chained comparison macros - provide familiar syntax while keeping host impl simple
; These expand multi-argument comparisons into chained 'and' expressions

; = macro - chained equality
(defmacro = [&rest args]
  (if (eq args nil)
    (quote true)
    (if (eq (cdr args) nil)
      (quote true)
      (if (eq (cdr (cdr args)) nil)
        (quasiquote (eq (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (and (eq (unquote (car args)) (unquote (car (cdr args))))
                         (= (unquote-splicing (cdr args)))))))))

; < macro - chained less-than
(defmacro < [&rest args]
  (if (eq (cdr args) nil)
    (quote true)
    (if (eq (cdr (cdr args)) nil)
      (quasiquote (lt (unquote (car args)) (unquote (car (cdr args)))))
      (quasiquote (and (lt (unquote (car args)) (unquote (car (cdr args))))
                       (< (unquote-splicing (cdr args))))))))

; > macro - chained greater-than
(defmacro > [&rest args]
  (if (eq (cdr args) nil)
    (quote true)
    (if (eq (cdr (cdr args)) nil)
      (quasiquote (gt (unquote (car args)) (unquote (car (cdr args)))))
      (quasiquote (and (gt (unquote (car args)) (unquote (car (cdr args))))
                       (> (unquote-splicing (cdr args))))))))

; <= macro - chained less-than-or-equal
(defmacro <= [&rest args]
  (if (eq (cdr args) nil)
    (quote true)
    (if (eq (cdr (cdr args)) nil)
      (quasiquote (lte (unquote (car args)) (unquote (car (cdr args)))))
      (quasiquote (and (lte (unquote (car args)) (unquote (car (cdr args))))
                       (<= (unquote-splicing (cdr args))))))))

; >= macro - chained greater-than-or-equal
(defmacro >= [&rest args]
  (if (eq (cdr args) nil)
    (quote true)
    (if (eq (cdr (cdr args)) nil)
      (quasiquote (gte (unquote (car args)) (unquote (car (cdr args)))))
      (quasiquote (and (gte (unquote (car args)) (unquote (car (cdr args))))
                       (>= (unquote-splicing (cdr args))))))))
