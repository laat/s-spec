(test "parse number literals"
  (assert/equal (print (parse "1")) "1")
  (assert/equal (print (parse "0")) "0")
  (assert/equal (print (parse "-3")) "-3")
  (assert/equal (print (parse "4.2")) "4.2")
  (assert/equal (print (parse "1e2")) "100")
  (assert/equal (print (parse "1E10")) "10000000000")
  (assert/equal (print (parse "-1e2")) "-100"))

(test "parse number-like tokens that are symbols"
  (assert/equal (print (parse "+1")) "+1")
  (assert/equal (print (parse "-")) "-")
  (assert/equal (print (parse ".5")) ".5")
  (assert/equal (print (parse "-x")) "-x"))

(test "parse string literals"
  (assert/equal (print (parse "\"hello\"")) "\"hello\"")
  (assert/equal (print (parse "\"a\\\"b\"")) "\"a\\\"b\"")
  (assert/equal (print (parse "\"path\\\\file\"")) "\"path\\\\file\""))

(test "parse null literal"
  (assert/equal (print (parse "null")) "null"))

(test "parse nil literal"
  (assert/equal (print (parse "nil")) "nil"))

(test "parse boolean literals"
  (assert/equal (print (parse "true")) "true")
  (assert/equal (print (parse "false")) "false"))

(test "parse keeps null and nil distinct"
  (assert/equal (print (parse "(list null nil)")) "(list null nil)"))

(test "parse simple list form"
  (assert/equal (print (parse "(+ 1 2)")) "(+ 1 2)")
  (assert/equal (print (parse "(+ 1 (+ 2 3))")) "(+ 1 (+ 2 3))"))

(test "parse array literals"
  (assert/equal (print (parse "[]")) "[]")
  (assert/equal (print (parse "[1 2 3]")) "[1 2 3]")
  (assert/equal (print (parse "[1 [2 3] 4]")) "[1 [2 3] 4]"))

(test "parse mixed list and array forms"
  (assert/equal (print (parse "(list [1 2] null nil)"))
                "(list [1 2] null nil)")
  (assert/equal (print (parse "[+ 1 2]")) "[+ 1 2]"))

(test "parse object literals"
  (assert/equal (print (parse "{}")) "{}")
  (assert/equal (print (parse "{:a 1}")) "{:a 1}")
  (assert/equal (print (parse "{:a 1 :b [2 3]}")) "{:a 1 :b [2 3]}"))

(test "parse object keyword key forms"
  (assert/equal (print (parse "{:foo 1}")) "{:foo 1}")
  (assert/equal (print (parse "{:\"foo\" 1}")) "{:foo 1}")
  (assert/equal (print (parse "{:\"foo bar\" 2}")) "{:\"foo bar\" 2}"))

(test "parse does not validate object keys — eval/quote does"
  (assert/equal (print (parse "{\"a\" 1}")) "{\"a\" 1}")
  (assert/equal (print (parse "{1 2}")) "{1 2}"))

(test "parsed object-literal form equals runtime Object when keys are keywords"
  (assert/equal (= (parse "{:a 1}") {:a 1}) true)
  (assert/equal (= (parse "{:a 1 :b 2}") {:a 1 :b 2}) true)
  (assert/equal (= (parse "{}") {}) true)
  (assert/equal (= (parse "{:a [1 2]}") {:a [1 2]}) true))

(test "print keyword with simple name uses unquoted form"
  (assert/equal (print :foo) ":foo")
  (assert/equal (print :cfg/port) ":cfg/port")
  (assert/equal (print :a-b) ":a-b")
  (assert/equal (print :<=) ":<=")
  (assert/equal (print :+) ":+"))

(test "print keyword with digit-first body uses unquoted form"
  (assert/equal (print :"2023") ":2023")
  (assert/equal (print (parse ":\"2023\"")) ":2023"))

(test "print keyword with special characters uses quoted form"
  (assert/equal (print :"foo bar") ":\"foo bar\"")
  (assert/equal (print :"a,b") ":\"a,b\"")
  (assert/equal (print :"a:b") ":\"a:b\"")
  (assert/equal (print :"a;b") ":\"a;b\""))

(test "parse canonicalizes object whitespace"
  (assert/equal (print (parse " { :a   1   :b   [ 2  3 ] } ")) "{:a 1 :b [2 3]}")
  (assert/equal (print (parse "{ :\"foo bar\"   2  :z  9 }")) "{:\"foo bar\" 2 :z 9}"))

(test "parse preserves object insertion order"
  (assert/equal (print (parse "{:z 1 :a 2 :m 3}")) "{:z 1 :a 2 :m 3}"))

(test "parse fn with vector params"
  (assert/equal (print (parse "(fn [] 42)")) "(fn [] 42)")
  (assert/equal (print (parse "(fn [x y] (+ x y))")) "(fn [x y] (+ x y))"))

(test "parse fn docstring form"
  (assert/equal
    (print (parse "(fn [x] \"Add one.\" (+ x 1))"))
    "(fn [x] \"Add one.\" (+ x 1))"))

(test "parse def forms"
  (assert/equal (print (parse "(def answer 42)")) "(def answer 42)")
  (assert/equal
    (print (parse "(def add1 (fn [x] \"Add one.\" (+ x 1)))"))
    "(def add1 (fn [x] \"Add one.\" (+ x 1)))"))

(test "parse defonce forms"
  (assert/equal (print (parse "(defonce cfg/port 8080)")) "(defonce cfg/port 8080)")
  (assert/equal
    (print (parse "(defonce init/fn (fn [] 1))"))
    "(defonce init/fn (fn [] 1))"))

(test "parse load and require forms"
  (assert/equal
    (print (parse "(load \"stdlib.lisp\")"))
    "(load \"stdlib.lisp\")")
  (assert/equal
    (print (parse "(require \"stdlib.lisp\")"))
    "(require \"stdlib.lisp\")"))

(test "parse defn forms"
  (assert/equal
    (print (parse "(defn add1 [x] (+ x 1))"))
    "(defn add1 [x] (+ x 1))")
  (assert/equal
    (print (parse "(defn greet [name] \"Greet name.\" name)"))
    "(defn greet [name] \"Greet name.\" name)"))

(test "parse let forms"
  (assert/equal (print (parse "(let [x 1 y 2] (+ x y))")) "(let [x 1 y 2] (+ x y))")
  (assert/equal
    (print (parse "(let [x 7 f (fn [y] (+ x y))] (f 5))"))
    "(let [x 7 f (fn [y] (+ x y))] (f 5))"))

(test "parse if forms"
  (assert/equal (print (parse "(if true 1 2)")) "(if true 1 2)")
  (assert/equal
    (print (parse "(if (:active {:active true}) \"on\" \"off\")"))
    "(if (:active {:active true}) \"on\" \"off\")"))

(test "parse do forms"
  (assert/equal (print (parse "(do)")) "(do)")
  (assert/equal (print (parse "(do 1 2 3)")) "(do 1 2 3)")
  (assert/equal
    (print (parse "(do (def x 1) (+ x 2))"))
    "(do (def x 1) (+ x 2))"))

(test "parse and/or forms"
  (assert/equal (print (parse "(and true false)")) "(and true false)")
  (assert/equal (print (parse "(or false nil \"x\")")) "(or false nil \"x\")")
  (assert/equal
    (print (parse "(and (:active {:active true}) (:name {:name \"Ada\"}))"))
    "(and (:active {:active true}) (:name {:name \"Ada\"}))"))

(test "parse equality forms"
  (assert/equal (print (parse "(= 1 1)")) "(= 1 1)")
  (assert/equal (print (parse "(/= nil \"\")")) "(/= nil \"\")")
  (assert/equal
    (print (parse "(= {:a 1 :b 2} {:b 2 :a 1})"))
    "(= {:a 1 :b 2} {:b 2 :a 1})"))

(test "parse quote and quasiquote forms"
  (assert/equal (print (parse "(quote (+ 1 2))")) "(quote (+ 1 2))")
  (assert/equal
    (print (parse "(quasiquote (if (unquote p) 1 2))"))
    "(quasiquote (if (unquote p) 1 2))")
  (assert/equal
    (print (parse "(quasiquote [1 (splice-unquote xs) 3])"))
    "(quasiquote [1 (splice-unquote xs) 3])"))

(test "parse defmacro and macroexpand forms"
  (assert/equal
    (print (parse "(defmacro unless [p t e] (quasiquote (if (unquote p) (unquote e) (unquote t))))"))
    "(defmacro unless [p t e] (quasiquote (if (unquote p) (unquote e) (unquote t))))")
  (assert/equal
    (print (parse "(defmacroonce unless [p t e] (quasiquote (if (unquote p) (unquote e) (unquote t))))"))
    "(defmacroonce unless [p t e] (quasiquote (if (unquote p) (unquote e) (unquote t))))")
  (assert/equal
    (print (parse "(macroexpand-1 (quote (unless false 1 2)))"))
    "(macroexpand-1 (quote (unless false 1 2)))"))

(test "parse ignores extra whitespace"
  (assert/equal (print (parse "   ( + 1   2 )   ")) "(+ 1 2)"))

(test "parse treats commas as whitespace"
  (assert/equal (print (parse "[1, 2, 3]")) "[1 2 3]")
  (assert/equal (print (parse "{:a 1, :b 2}")) "{:a 1 :b 2}")
  (assert/equal (print (parse "(+ 1, 2, 3)")) "(+ 1 2 3)"))

(test "parse canonicalizes array whitespace"
  (assert/equal (print (parse " [ 1   2  3 ] ")) "[1 2 3]")
  (assert/equal (print (parse "[ 1   [ 2  3 ]   4 ]")) "[1 [2 3] 4]"))

(test "parse canonicalizes mixed nested whitespace"
  (assert/equal (print (parse "(list  [ 1 2 ]   ( +  3  4 )  nil)"))
                "(list [1 2] (+ 3 4) nil)"))
