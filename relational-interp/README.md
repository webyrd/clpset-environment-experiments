# TODO

* once the faster-miniKanren impl of CLP(Set) is available, replace
  the quote clauses with a single generic quote clause.

* improve reification of set constraints.  One issue is shown in this test:

```
;; WEB -- Reification complaint!
;;
;; My complaint is that in a reified answer, `set` means different
;; things on the left and right of the `:`, which makes the answers
;; harder to read, and easily leads to confusion.
;;
;; In this example, on the left-hand side of the `:`,
;;
;; (set _.0 _.1)
;;
;; means that the value of the query variable `q` is a set that is the
;; union of the set `a` and the singleton set containing `b`.
;;
;; On the right-hand side of the `:`,
;;
;; (set _.0 _.1)
;;
;; means that both `a` and `b` are sets.  (That is, this use of `set`
;; is as a reified type constraint, similar to reified lists of
;; variables contrained by `symbolo` or `numbero`.)
(test-check "reification-complaint 3"
  (run* (q)
    (fresh (a b)
      (seto b)
      (== (set a b) q)))
  '(((set _.0 _.1) : (set _.0 _.1))))
```

Another issue is that run-unique doesn't handle reified answers that
subsume other answers.  One possible approach would be to try to
simplify each answer produced to see if there is a simpler answer that
subsumes it, for which the computation should also succeed.

* implement an interpreter with a non-empty initial environment
  containing `cons`, `list`, etc.

* implement `letrec`

* implement a call-by-name and/or call-by-value version of the
  interpreter, and explore how lazy we can be at the language
  semantics level when combined with lazy constraints such as
  CLP(Set).  Should be able to generate more generic answers in some
  cases involving application: for example, `((lambda (x) 5) ,e)
  should leave `e` fresh instead of enumerating all possible
  expressions.  Is there a way to use the lazy evaluator to synthesize
  the Y combinator?  How to represent forall?  Eigen variables?

* implement co-routining between "serious" conjuncts, ideally based on
  the Extended Andorra Model.  The two recursive eval-expro calls in
  the cons case seems perfect for experimentation.