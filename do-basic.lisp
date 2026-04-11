(test "do returns nil with no forms"
  (assert/equal (do) nil))

(test "do returns the last value"
  (assert/equal (do 1) 1)
  (assert/equal (do 1 2 3) 3)
  (assert/equal (do "a" "b") "b"))

(test "do evaluates forms in order"
  (require "stdlib.lisp")
  (def do-counter 0)
  (def bump
    (fn []
      (let [current do-counter]
        (def do-counter (+ do-counter 1))
        current)))
  (assert/equal (do (bump) (bump) (bump)) 2)
  (assert/equal do-counter 3))

(test "do enables sequencing in expression position"
  (assert/equal
    (if true
      (do 1 2 3)
      0)
    3)
  (assert/equal
    ((fn []
       (do
         (def inner-value 10)
         (+ inner-value 5))))
    15))
