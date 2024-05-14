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

(test-check "d1"
  (run-unique* (q)
    (=/= ∅ ∅))
  '())

(test-check "d2"
  (run-unique* (q)
    (=/= (set ∅ 1 2 1) (set ∅ 2 2 1)))
  '())

(test-check "d3a"
  (run-unique* (q)
    (fresh (s1 s2)
      (== (list s1 s2) q)
      (seto s1)
      (seto s2)
      (== s1 s2)
      (=/= s1 s2)))
  '())

(test-check "d3b"
  (run-unique* (q)
    (fresh (s1 s2)
      (== (list s1 s2) q)
      (seto s1)
      (seto s2)
      (=/= s1 s2)
      (== s1 s2)))
  '())

(test-check "d3c"
  (run-unique* (q)
    (fresh (s1 s2)
      (== (list s1 s2) q)
      (=/= s1 s2)
      (seto s1)
      (seto s2)
      (== s1 s2)))
  '())

(test-check "d4"
  (run-unique* (q)
    (fresh (x y)
      (== (list x y) q)
      (=/= (set ∅ x 2) (set ∅ 1 2))))
  '(((_.0 _.1) : (=/= (_.0 1) (_.0 2)))
    ;; The first answer is subsumed by the second answer; ideally
    ;; `run-unique` would only return the second answer.
    ((_.0 _.1) : (=/= (_.0 1)))))

(test-check "s1a"
  (run-unique* (q)
    (== ∅ (set ∅ ∅)))
  '())

(test-check "s1b"
  (run-unique* (q)
    (== (set ∅ ∅) ∅))
  '())

(test-check "s2"
  (run-unique* (q)
    (fresh (s1 s2)
      (== (list s1 s2) q)
      (seto s1)
      (seto s2)
      (== (set s1 s2) s2)))
  '())

(test-check "s3"
  (run-unique* (q)
    (fresh (s1 s2 s3)
      (== (list s1 s2 s3) q)
      (seto s1)
      (seto s2)
      (seto s3)
      (== (set s1 s2) s3)))
  '(((_.0 _.1 (set _.0 _.1)) : (set _.0 _.1))))

(test-check "s4"
  (run-unique* (q)
    (== (set ∅ q) ∅))
  '())

(test-check "s5"
  (run-unique* (q)
    (seto q)
    (== (set ∅ q) q))
  '())

(test-check "s6"
  (run-unique* (q)
    (== (set ∅ q) q))
  '())
