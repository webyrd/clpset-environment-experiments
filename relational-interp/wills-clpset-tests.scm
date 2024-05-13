(load "../lib/clpset-miniKanren/mk.scm")
(load "../lib/alternative-run-interface/alternative-run-interface.scm")
(load "../lib/clpset-miniKanren/test-check.scm")

;; Tests to ensure Will understands how the CLP(Set) set constraints work.

(test-check "w1a"
  (run-unique* (q)
    (== (set ∅ 1) (set ∅ 1 1 1 1 1)))
  '(_.0))

(test-check "w1b"
  (run-unique* (q)
    (== (set ∅ 1 1 1 1 1) (set ∅ 1)))
  '(_.0))

(test-check "w2"
  (run-unique* (q)
    (== ∅ ∅))
  '(_.0))

(test-check "w3"
  (run-unique* (q)
    (== (set ∅ 1 2) (set ∅ 2 1)))
  '(_.0))

(test-check "w4"
  (run-unique* (q)
    (== (set ∅ 1 2) (set ∅ q 1)))
  '(2))

(test-check "w5"
  (run-unique* (q)
    (== (set ∅ 2 1 2) (set ∅ 1 q 1)))
  '(2))

(test-check "w6"
  (run-unique* (q)
    (fresh (x y)
      (== (list x y) q)
      (== (set ∅ x 2) (set ∅ y 1))))
  '((1 2)))
