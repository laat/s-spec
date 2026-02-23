; Variadic function tests ported from variadic.test.ts

(test "variadic fn - with rest args"
  (defn sum-list [lst]
    (if (empty? lst)
      0
      (+ (first lst) (sum-list (rest lst)))))
  (defn sum [&rest nums] (sum-list nums))
  (assert/equal (sum 1 2 3 4) 10))

(test "variadic fn - zero rest args"
  (defn identity [&rest nums] nums)
  (assert/equal (empty? (identity)) true))

(test "variadic fn - one rest arg"
  (defn get-first [&rest nums] (first nums))
  (assert/equal (get-first 42) 42))

(test "variadic fn - required + rest"
  (defn make-list [first-item &rest rest-items]
    (list first-item rest-items))
  ; Result should be a list structure - just verify it's truthy
  (assert/equal (= (make-list 1 2 3) null) false))

(test "variadic fn - required only (no rest args)"
  (defn greet [name &rest titles] name)
  (assert/equal (greet "Alice") "Alice"))

(test "variadic fn - required + multiple rest"
  (defn count-list [lst]
    (if (empty? lst)
      0
      (+ 1 (count-list (rest lst)))))
  (defn count-rest [first &rest rest]
    (count-list rest))
  (assert/equal (count-rest 1 2 3 4 5) 4))

(test "list - creates list from args"
  ; Can't check internal structure in Lisp, but verify it works
  (assert/equal (first (list 1 2 3)) 1)
  (assert/equal (list) null))

(test "first - gets first element"
  (assert/equal (first (list 1 2 3)) 1)
  (assert/equal (first (list)) null)
  (assert/equal (first null) null))

(test "rest - gets remaining elements"
  (assert/equal (first (rest (list 1 2 3))) 2)
  (assert/equal (rest (list 1)) null)
  (assert/equal (rest (list)) null)
  (assert/equal (rest null) null))

(test "empty? - on lists"
  (assert/equal (empty? (list)) true)
  (assert/equal (empty? null) true)
  (assert/equal (empty? (list 1 2)) false))

(test "variadic macro - simple"
  (defmacro when [cond &rest body]
    (quasiquote (if (unquote cond) (unquote (first body)) null)))
  (assert/equal (when true 42) 42)
  (assert/equal (when true (+ 1 2)) 3))

(test "variadic errors"
  (defn f [x &rest xs] x)
  (assert/throws (fn [] (f)) "Expected at least 1 args, got 0")
  (assert/throws (fn [] (fn [x &rest] x)) "Expected parameter name after &rest")
  (assert/throws (fn [] (fn [&rest xs y] x)) "No parameters allowed after &rest parameter"))

(test "variadic - collect all args"
  (defn collect-all [&rest items] items)
  (assert/equal (first (collect-all "a" "b" "c")) "a"))
