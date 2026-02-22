; Example of naming convention for organization
; No actual namespaces, just prefixes in symbol names

(def email/pattern (re "^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$"))
(defn email/validate [s] (email/pattern s))

(def user/min-age 18)
(defn user/valid-age? [age] (>= age user/min-age))
