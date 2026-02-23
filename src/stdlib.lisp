; s-spec standard library
; Core macros and functions defined in Lisp instead of hardcoded in the interpreter

; defn - Define a named function
; Expands (defn name [params] body) to (def name (fn [params] body))
(defmacro defn [name params &rest body]
  (quasiquote (def (unquote name) (fn (unquote params) (unquote (car body))))))

; cond - Multi-branch conditional
; Expands (cond test1 result1 test2 result2 :else default) to nested if statements
(defmacro cond [&rest clauses]
  (__cond-helper clauses))

(defn __cond-helper [clauses]
  (if (null? clauses)
    null
    (let [test (car clauses)
          rest (cdr clauses)]
      (if (null? rest)
        null
        (let [result (car rest)
              remaining (cdr rest)]
          (if (and (keyword? test) (primitive-eq test :else))
            result
            (if (null? remaining)
              (quasiquote (if (unquote test) (unquote result) null))
              (quasiquote
                (if (unquote test)
                  (unquote result)
                  (unquote (__cond-helper remaining)))))))))))

; Helper functions
(defn not [x] (if x false true))

; Core equality - portable implementation using primitive builtins
; Deep/structural equality for all types
(defn eq [a b]
  (cond
    (and (null? a) (null? b))
      true
    (or (null? a) (null? b))
      false
    (or (number? a) (string? a) (boolean? a) (keyword? a) (symbol? a))
      (primitive-eq a b)
    (and (array? a) (array? b))
      (__array-eq a b)
    (array? a)
      false
    (and (object? a) (object? b))
      (__object-eq a b)
    (object? a)
      false
    :else
      (primitive-eq a b)))

; Helper: Deep equality for arrays
(defn __array-eq [a b]
  (if (not (primitive-eq (length a) (length b)))
    false
    (__array-eq-iter a b 0)))

(defn __array-eq-iter [a b i]
  (if (>= i (length a))
    true
    (if (eq (nth a i) (nth b i))
      (__array-eq-iter a b (+ i 1))
      false)))

; Helper: Deep equality for objects
(defn __object-eq [a b]
  (let [keys-a (keys a)
        keys-b (keys b)]
    (if (not (primitive-eq (length keys-a) (length keys-b)))
      false
      (__object-eq-iter a b keys-a))))

(defn __object-eq-iter [obj-a obj-b key-list]
  (if (null? key-list)
    true
    (let [k (car key-list)]
      (if (eq (get obj-a k) (get obj-b k))
        (__object-eq-iter obj-a obj-b (cdr key-list))
        false))))

(defn empty? [x] (eq x null))

; Arithmetic macros - provide familiar multi-arity syntax while keeping host impl simple
; These expand multi-argument arithmetic into nested binary operations

; + macro - variadic addition
(defmacro + [&rest args]
  (if (eq args null)
    (quote 0)
    (if (eq (cdr args) null)
      (car args)
      (if (eq (cdr (cdr args)) null)
        (quasiquote (add (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (add (unquote (car args)) (+ (unquote-splicing (cdr args)))))))))

; - macro - variadic subtraction (left-to-right)
(defmacro - [&rest args]
  (if (eq args null)
    (quote 0)
    (if (eq (cdr args) null)
      (quasiquote (sub 0 (unquote (car args))))
      (if (eq (cdr (cdr args)) null)
        (quasiquote (sub (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (- (sub (unquote (car args)) (unquote (car (cdr args)))) (unquote-splicing (cdr (cdr args)))))))))

; * macro - variadic multiplication
(defmacro * [&rest args]
  (if (eq args null)
    (quote 1)
    (if (eq (cdr args) null)
      (car args)
      (if (eq (cdr (cdr args)) null)
        (quasiquote (mul (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (mul (unquote (car args)) (* (unquote-splicing (cdr args)))))))))

; / macro - variadic division (left-to-right)
(defmacro / [&rest args]
  (if (eq args null)
    (quote 1)
    (if (eq (cdr args) null)
      (quasiquote (div 1 (unquote (car args))))
      (if (eq (cdr (cdr args)) null)
        (quasiquote (div (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (/ (div (unquote (car args)) (unquote (car (cdr args)))) (unquote-splicing (cdr (cdr args)))))))))

; Chained comparison macros - provide familiar syntax while keeping host impl simple
; These expand multi-argument comparisons into chained 'and' expressions

; = macro - chained equality
(defmacro = [&rest args]
  (if (eq args null)
    (quote true)
    (if (eq (cdr args) null)
      (quote true)
      (if (eq (cdr (cdr args)) null)
        (quasiquote (eq (unquote (car args)) (unquote (car (cdr args)))))
        (quasiquote (and (eq (unquote (car args)) (unquote (car (cdr args))))
                         (= (unquote-splicing (cdr args)))))))))

; < macro - chained less-than
(defmacro < [&rest args]
  (if (eq (cdr args) null)
    (quote true)
    (if (eq (cdr (cdr args)) null)
      (quasiquote (lt (unquote (car args)) (unquote (car (cdr args)))))
      (quasiquote (and (lt (unquote (car args)) (unquote (car (cdr args))))
                       (< (unquote-splicing (cdr args))))))))

; > macro - chained greater-than
(defmacro > [&rest args]
  (if (eq (cdr args) null)
    (quote true)
    (if (eq (cdr (cdr args)) null)
      (quasiquote (gt (unquote (car args)) (unquote (car (cdr args)))))
      (quasiquote (and (gt (unquote (car args)) (unquote (car (cdr args))))
                       (> (unquote-splicing (cdr args))))))))

; <= macro - chained less-than-or-equal
(defmacro <= [&rest args]
  (if (eq (cdr args) null)
    (quote true)
    (if (eq (cdr (cdr args)) null)
      (quasiquote (lte (unquote (car args)) (unquote (car (cdr args)))))
      (quasiquote (and (lte (unquote (car args)) (unquote (car (cdr args))))
                       (<= (unquote-splicing (cdr args))))))))

; >= macro - chained greater-than-or-equal
(defmacro >= [&rest args]
  (if (eq (cdr args) null)
    (quote true)
    (if (eq (cdr (cdr args)) null)
      (quasiquote (gte (unquote (car args)) (unquote (car (cdr args)))))
      (quasiquote (and (gte (unquote (car args)) (unquote (car (cdr args))))
                       (>= (unquote-splicing (cdr args))))))))
