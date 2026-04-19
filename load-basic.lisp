(test "load evaluates a file and returns nil"
  (assert/equal (load "fixtures/load/basic-module.lisp") nil)
  (assert/equal loaded_value 41)
  (assert/equal (loaded_add1 2) 3))

(test "load resolves paths relative to caller file"
  (assert/equal (load "fixtures/load/nested/parent.lisp") nil)
  (assert/equal nested_child_value 7)
  (assert/equal nested_parent_flag true))
