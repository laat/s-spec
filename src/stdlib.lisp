; s-spec standard library
; Core macros and functions defined in Lisp instead of hardcoded in the interpreter

; defn - Define a named function
; Expands (defn name [params] body) to (def name (fn [params] body))
(defmacro defn [name params &rest body]
  (quasiquote (def (unquote name) (fn (unquote params) (unquote (first body))))))

; cond - Multi-branch conditional
; Expands (cond test1 result1 test2 result2 :else default) to nested if statements
(defmacro cond [&rest clauses]
  (__cond-helper clauses))

(defn __cond-helper [clauses]
  (if (null? clauses)
    null
    (let [test (first clauses)
          rest (rest clauses)]
      (if (null? rest)
        null
        (let [result (first rest)
              remaining (rest rest)]
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
  (if (not (primitive-eq (count a) (count b)))
    false
    (__array-eq-iter (seq a) (seq b))))

(defn __array-eq-iter [seq-a seq-b]
  (if (null? seq-a)
    true
    (if (eq (first seq-a) (first seq-b))
      (__array-eq-iter (rest seq-a) (rest seq-b))
      false)))

; Helper: Deep equality for objects
(defn __object-eq [a b]
  (let [keys-a (seq (keys a))
        keys-b (seq (keys b))]
    (if (not (primitive-eq (count keys-a) (count keys-b)))
      false
      (__object-eq-iter a b keys-a))))

(defn __object-eq-iter [obj-a obj-b key-list]
  (if (null? key-list)
    true
    (let [k (first key-list)]
      (if (eq (get obj-a k) (get obj-b k))
        (__object-eq-iter obj-a obj-b (rest key-list))
        false))))

(defn empty? [x] (eq x null))

; Arithmetic macros - provide familiar multi-arity syntax while keeping host impl simple
; These expand multi-argument arithmetic into nested binary operations

; + macro - variadic addition
(defmacro + [&rest args]
  (if (eq args null)
    (quote 0)
    (if (eq (rest args) null)
      (first args)
      (if (eq (rest (rest args)) null)
        (quasiquote (add (unquote (first args)) (unquote (first (rest args)))))
        (quasiquote (add (unquote (first args)) (+ (unquote-splicing (rest args)))))))))

; - macro - variadic subtraction (left-to-right)
(defmacro - [&rest args]
  (if (eq args null)
    (quote 0)
    (if (eq (rest args) null)
      (quasiquote (sub 0 (unquote (first args))))
      (if (eq (rest (rest args)) null)
        (quasiquote (sub (unquote (first args)) (unquote (first (rest args)))))
        (quasiquote (- (sub (unquote (first args)) (unquote (first (rest args)))) (unquote-splicing (rest (rest args)))))))))

; * macro - variadic multiplication
(defmacro * [&rest args]
  (if (eq args null)
    (quote 1)
    (if (eq (rest args) null)
      (first args)
      (if (eq (rest (rest args)) null)
        (quasiquote (mul (unquote (first args)) (unquote (first (rest args)))))
        (quasiquote (mul (unquote (first args)) (* (unquote-splicing (rest args)))))))))

; / macro - variadic division (left-to-right)
(defmacro / [&rest args]
  (if (eq args null)
    (quote 1)
    (if (eq (rest args) null)
      (quasiquote (div 1 (unquote (first args))))
      (if (eq (rest (rest args)) null)
        (quasiquote (div (unquote (first args)) (unquote (first (rest args)))))
        (quasiquote (/ (div (unquote (first args)) (unquote (first (rest args)))) (unquote-splicing (rest (rest args)))))))))

; Chained comparison macros - provide familiar syntax while keeping host impl simple
; These expand multi-argument comparisons into chained 'and' expressions

; = macro - chained equality
(defmacro = [&rest args]
  (if (eq args null)
    (quote true)
    (if (eq (rest args) null)
      (quote true)
      (if (eq (rest (rest args)) null)
        (quasiquote (eq (unquote (first args)) (unquote (first (rest args)))))
        (quasiquote (and (eq (unquote (first args)) (unquote (first (rest args))))
                         (= (unquote-splicing (rest args)))))))))

; < macro - chained less-than
(defmacro < [&rest args]
  (if (eq (rest args) null)
    (quote true)
    (if (eq (rest (rest args)) null)
      (quasiquote (lt (unquote (first args)) (unquote (first (rest args)))))
      (quasiquote (and (lt (unquote (first args)) (unquote (first (rest args))))
                       (< (unquote-splicing (rest args))))))))

; > macro - chained greater-than
(defmacro > [&rest args]
  (if (eq (rest args) null)
    (quote true)
    (if (eq (rest (rest args)) null)
      (quasiquote (gt (unquote (first args)) (unquote (first (rest args)))))
      (quasiquote (and (gt (unquote (first args)) (unquote (first (rest args))))
                       (> (unquote-splicing (rest args))))))))

; <= macro - chained less-than-or-equal
(defmacro <= [&rest args]
  (if (eq (rest args) null)
    (quote true)
    (if (eq (rest (rest args)) null)
      (quasiquote (lte (unquote (first args)) (unquote (first (rest args)))))
      (quasiquote (and (lte (unquote (first args)) (unquote (first (rest args))))
                       (<= (unquote-splicing (rest args))))))))

; >= macro - chained greater-than-or-equal
(defmacro >= [&rest args]
  (if (eq (rest args) null)
    (quote true)
    (if (eq (rest (rest args)) null)
      (quasiquote (gte (unquote (first args)) (unquote (first (rest args)))))
      (quasiquote (and (gte (unquote (first args)) (unquote (first (rest args))))
                       (>= (unquote-splicing (rest args))))))))
