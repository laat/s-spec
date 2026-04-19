(def harness-counter 0)
(def harness-counter (+ harness-counter 1))

(test "top-level def is visible inside a test"
  (assert/equal harness-counter 1))

(test "in-test def does not leak, but prelude re-runs — counter is 1 again"
  (def harness-counter (+ harness-counter 100))
  (assert/equal harness-counter 101))

(test "prior test's in-test mutation did not leak into this test"
  (assert/equal harness-counter 1))
