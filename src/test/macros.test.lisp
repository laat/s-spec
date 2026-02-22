; Macro tests ported from macros.test.ts

(test "quote - literals"
  (assert/equal (quote 42) 42))

(test "quote - symbol returns symbol"
  ; Can't check internal structure, but verify it doesn't evaluate
  (assert/equal (= (quote x) (quote x)) true))

(test "quote - list structure"
  ; Quote returns unevaluated structure
  ; We can verify it's not evaluated by checking it's not 3
  (assert/equal (= (quote (+ 1 2)) 3) false))

(test "quote - wrong arity"
  (assert/throws (fn [] (quote)) "quote requires 1 argument")
  (assert/throws (fn [] (quote 1 2)) "quote requires 1 argument"))

(test "quasiquote - without unquote acts like quote"
  ; Verify it's not evaluated
  (assert/equal (= (quasiquote (+ 1 2)) 3) false))

(test "quasiquote with unquote - evaluates unquoted expression"
  (def x 5)
  ; We can't check internal structure in Lisp, but we can verify behavior
  ; by using it in a macro
  (defmacro test-qq [val] (quasiquote (+ 1 (unquote val))))
  (assert/equal (test-qq x) 6))

(test "quasiquote - multiple unquotes"
  (def x 10)
  (def y 20)
  (defmacro test-multi [a b] (quasiquote (+ (unquote a) (unquote b))))
  (assert/equal (test-multi x y) 30))

(test "unquote-splicing - splices list elements"
  ; Macro receives unevaluated arguments, so we pass the literal list directly
  (defmacro test-splice [items] (quasiquote (+ (unquote-splicing items))))
  (assert/equal (test-splice (1 2 3)) 6))

(test "unquote errors outside quasiquote"
  (assert/throws (fn [] (unquote x)) "unquote outside quasiquote")
  (assert/throws (fn [] (unquote-splicing xs)) "unquote-splicing outside quasiquote"))

(test "defmacro - when macro"
  (defmacro when [cond body]
    (quasiquote (if (unquote cond) (unquote body) nil)))
  (assert/equal (when true 42) 42)
  (assert/equal (when false 42) nil))

(test "defmacro - unless macro"
  (defmacro unless [cond body]
    (quasiquote (if (unquote cond) nil (unquote body))))
  (assert/equal (unless false 42) 42)
  (assert/equal (unless true 42) nil))

(test "defn macro from stdlib"
  (defn triple [x] (* x 3))
  (assert/equal (triple 4) 12)
  (defn add [a b] (+ a b))
  (assert/equal (add 3 7) 10))

(test "defn macro - closure"
  (def multiplier 5)
  (defn times-n [x] (* multiplier x))
  (assert/equal (times-n 4) 20))

(test "defn macro - recursive function"
  (defn factorial [n]
    (if (= n 0)
      1
      (* n (factorial (- n 1)))))
  (assert/equal (factorial 5) 120))

(test "macro expansion - happens before evaluation"
  (defmacro defconst [name value]
    (quasiquote (def (unquote name) (unquote value))))
  (defconst pi 3.14)
  (assert/equal pi 3.14))

(test "macro expansion - recursive expansion"
  (defmacro when [cond body]
    (quasiquote (if (unquote cond) (unquote body) nil)))
  (defmacro unless [cond body]
    (quasiquote (when (not (unquote cond)) (unquote body))))
  (assert/equal (unless false 100) 100))

(test "macro - wrong arity"
  (defmacro foo [x] x)
  (assert/throws (fn [] (foo 1 2)) "Macro expected 1 args, got 2"))

(test "macro receives unevaluated arguments"
  (defmacro first-arg-is-symbol [arg]
    (quasiquote (quote (unquote arg))))
  ; Should return the symbol x, not try to evaluate it
  (assert/equal (= (first-arg-is-symbol x) (quote x)) true))

(test "macro - can generate def forms"
  (defmacro defvar [name]
    (quasiquote (def (unquote name) nil)))
  (defvar foo)
  (assert/equal foo nil))

(test "complex macro - cond-style conditional"
  (defmacro cond2 [test1 result1 test2 result2]
    (quasiquote (if (unquote test1)
                    (unquote result1)
                    (if (unquote test2)
                        (unquote result2)
                        nil))))
  (assert/equal (cond2 false 1 true 2) 2))

(test "macros compose with functions"
  (defmacro when [cond body]
    (quasiquote (if (unquote cond) (unquote body) nil)))
  (defn check [x]
    (when (> x 10) (* x 2)))
  (assert/equal (check 15) 30))

(test "macros can use builtin functions in templates"
  (defmacro double-if-positive [x]
    (quasiquote (if (> (unquote x) 0) (* (unquote x) 2) 0)))
  (assert/equal (double-if-positive 5) 10))

; Note: The following tests use debug mode functions (expand, to-sexpr)
; These are NOT available in production builds, but ARE available
; when running tests since the test harness uses debug mode

(test "expansion - when macro expands to if"
  (defmacro when [cond body]
    (quasiquote (if (unquote cond) (unquote body) nil)))
  (assert/equal (to-sexpr (expand (quote (when test-cond result-expr)))) "(if test-cond result-expr nil)"))

(test "expansion - unless macro expands to if"
  (defmacro my-unless [cond body]
    (quasiquote (if (unquote cond) nil (unquote body))))
  (assert/equal (to-sexpr (expand (quote (my-unless test-cond result-expr)))) "(if test-cond nil result-expr)"))

(test "expansion - defn macro from stdlib"
  ; expand only does one level, so * won't be expanded yet
  (assert/equal (to-sexpr (expand (quote (defn double [x] (* x 2))))) "(def double (fn [x] (* x 2)))"))

(test "expansion - + variadic macro"
  ; expand only does one level, so nested + won't be expanded yet
  (assert/equal (to-sexpr (expand (quote (+ 1 2 3)))) "(add 1 (+ 2 3))"))

(test "expansion - + with two args"
  (assert/equal (to-sexpr (expand (quote (+ 1 2)))) "(add 1 2)"))

(test "expansion - = comparison chaining"
  ; = macro expands to eq builtin for first comparison, then nested = for rest
  (assert/equal (to-sexpr (expand (quote (= a b c)))) "(and (eq a b) (= b c))"))

(test "expansion - > comparison chaining"
  ; > macro expands to gt builtin for first comparison, then nested > for rest
  (assert/equal (to-sexpr (expand (quote (> x y z)))) "(and (gt x y) (> y z))"))

(test "expansion - nested macro calls"
  (defmacro my-when [cond body]
    (quasiquote (if (unquote cond) (unquote body) nil)))
  ; expand only does one level, so = won't be expanded yet
  (assert/equal (to-sexpr (expand (quote (my-when (= 1 2) result)))) "(if (= 1 2) result nil)"))

(test "expansion - recursive macro expansion"
  (defmacro my-when2 [cond body]
    (quasiquote (if (unquote cond) (unquote body) nil)))
  (defmacro my-unless2 [cond body]
    (quasiquote (my-when2 (not (unquote cond)) (unquote body))))
  ; expand only does one level, so it expands to my-when2, not all the way to if
  (assert/equal (to-sexpr (expand (quote (my-unless2 test-cond result-expr)))) "(my-when2 (not test-cond) result-expr)"))

(test "expansion - complex arithmetic"
  ; expand only does one level, so nested + won't be expanded yet
  (assert/equal (to-sexpr (expand (quote (+ 1 2 3 4)))) "(add 1 (+ 2 3 4))"))

(test "expansion - expand returns AST node"
  (def expanded (expand (quote (+ 1 2))))
  ; Can't check structure directly, but verify we can convert it back
  (assert/equal (to-sexpr expanded) "(add 1 2)"))

(test "expand-all - recursively expands all macros"
  ; expand-all does full recursive expansion
  (assert/equal (to-sexpr (expand-all (quote (+ 1 2 3)))) "(add 1 (add 2 3))"))

(test "expand-all - complex arithmetic fully expanded"
  (assert/equal (to-sexpr (expand-all (quote (+ 1 2 3 4)))) "(add 1 (add 2 (add 3 4)))"))

(test "expand-all - comparison chaining fully expanded"
  (assert/equal (to-sexpr (expand-all (quote (= a b c)))) "(and (eq a b) (eq b c))"))

(test "expand-all - nested comparison fully expanded"
  (assert/equal (to-sexpr (expand-all (quote (> x y z)))) "(and (gt x y) (gt y z))"))

(test "expand-all - defn with nested macros"
  ; defn expands to def/fn, and * also expands to mul
  (assert/equal (to-sexpr (expand-all (quote (defn double [x] (* x 2))))) "(def double (fn [x] (mul x 2)))"))

(test "expand-all vs expand - show difference"
  ; expand: single level
  (assert/equal (to-sexpr (expand (quote (+ 1 2 3)))) "(add 1 (+ 2 3))")
  ; expand-all: recursive
  (assert/equal (to-sexpr (expand-all (quote (+ 1 2 3)))) "(add 1 (add 2 3))"))

(test "expansion - to-sexpr works on values"
  (assert/equal (to-sexpr 42) "42")
  (assert/equal (to-sexpr "hello") "\"hello\"")
  (assert/equal (to-sexpr true) "true")
  (assert/equal (to-sexpr nil) "nil")
  (assert/equal (to-sexpr (quote x)) "x")
  (assert/equal (to-sexpr (quote :keyword)) ":keyword"))

(test "expansion - to-sexpr on arrays"
  (assert/equal (to-sexpr [1 2 3]) "[1 2 3]")
  (assert/equal (to-sexpr []) "[]"))

(test "expansion - to-sexpr on objects"
  (assert/equal (to-sexpr {:a 1 :b 2}) "{:a 1 :b 2}")
  (assert/equal (to-sexpr {}) "{}"))
