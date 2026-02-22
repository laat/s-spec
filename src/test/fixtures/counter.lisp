; File that tracks how many times it's been loaded
; Used to test once-only loading
; We use a side effect (log) that we can observe
(log "counter.lisp loaded")
(def counter-loaded true)
