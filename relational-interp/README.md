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

? Can `normalize-set`, which is used in normalization tests in
../lib/clpset-miniKanren/clpset-tests.scm, be useful in reification or
the fancier run interfaces, especially for removing duplicate answers
or for subsumption detection or answer simplification/canonicalization?

* implement an interpreter with a non-empty initial environment
  containing `cons`, `list`, etc.

* implement `letrec`

* implement enough of a language to synthesize `append`

* revisit `match` in the relational interpreter, using this
  representation for the pattern matching environment

* try this environment representation with a relational type
  inferencer

* revisit mk-in-mk using this representation for environments and
  substitutions.  For a deep embedding of mk-in-mk, may be able to
  remove multiple sources of recursive generate-and-test behavior.
  Revisit my experiments combining shallow and deep mk-in-mk
  embeddings.

* revisit NBE using this representation of environments

* revisit relational abstract interpretation, since CLP(Set) also
  seems handy for simulating gensym

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

* explore as many ways as possible of "finitizing" infinite sets or
  behaviors: De Bruijn representation of lambda calculus terms,
  canonicalized terms such as in nominal logic programming and NBE,
  lazy evaluation, streams, tabling, abstract domains, CLP(X),
  Skolemization/Eigen variables, for all and implication (as in Lambda
  Prolog/lambdaKanren), techniques from program synthesis and
  constraint solving, e-unification, terminating rewrite systems, etc.
  Collect a big list of these techniques.

* revisit work on termination analysis, decreasing bounds, static
  analysis, using DFS when possible, etc.
