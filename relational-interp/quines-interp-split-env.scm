(load "../lib/clpset-miniKanren/mk.scm")
(load "../lib/alternative-run-interface/alternative-run-interface.scm")
(load "../lib/clpset-miniKanren/test-check.scm")

;; Use a pair of sets to represent the environment: the car contains
;; symbols by themselves, while the cdr contains the pairs with the
;; actual mappings.  Raffi Sanna suggested this representation as
;; being more efficient, since the CLP(Set) operations can be
;; quadratic in the size of the sets.
;;
;; Raffi also suggested that we could implement a map data structure
;; rather than a set data structure, to make environments and
;; substitutions easier to encode.
(define empty-env `(,∅ . ,∅))
(define (ext-envo x v env env^)
  (fresh (vars bindings)
    (symbolo x)
    (== `(,vars . ,bindings) env)
    ;; In this encoding we add to the `env` both `x` and the pair
    ;; binding `x` to `v`.  This allows us to use `(!ino x env)` to
    ;; ensure `x` is not already bound in `env`.
    (conde
      ((!ino x vars)
       ;; Case 1: not shadowing `x`
       ;;
       ;; `x` isn't in `vars`, so we are free to add the binding
       ;; between `x` and `v`, along with `x` so we can check
       ;; for shadowing in the future.
       (== `(,(set vars x) . ,(set bindings `(,x . ,v))) env^))
      ((fresh (v^ bindings-minus-x-binding)
         ;; Case 2: shadowing `x`
         ;;
         ;; There is already a binding between `x` and `v^` in `bindings`,
         ;; so we must create a new environment `env-minus-x-binding`
         ;; that is identical to `bindings`, minus the `x`/`v^` binding.
         ;; We can safely extend `env-minus-x-binding` with the
         ;; `x`/`v` binding to produce `env^`.
         (ino x vars)
         (ino `(,x . ,v^) bindings)
         (!ino `(,x . ,v^) bindings-minus-x-binding)
         (uniono (set ∅ `(,x . ,v^)) bindings-minus-x-binding bindings)
         (== `(,vars . ,(set bindings-minus-x-binding `(,x . ,v))) env^))))))
(define (lookupo x env val)
  (fresh (vars bindings)
    (symbolo x)
    (== `(,vars . ,bindings) env)
    (ino x vars)
    (ino `(,x . ,val) bindings)))
(define (not-in-envo x env)
  (fresh (vars bindings)
    (symbolo x)
    (== `(,vars . ,bindings) env)
    (!ino x vars)))

(define (evalo expr val)
  (eval-expro expr empty-env val))

(define (eval-expro expr env val)
  (conde
    ;; We don't have `absento` in this version of mk, so punt by
    ;; breaking `quote` into cases, using `=/=`, and avoiding `car`,
    ;; `cdr`, or other destructors.
    ((== '(quote ()) expr)
     (== '() val)
     (not-in-envo 'quote env))
    ((== `(quote ,val) expr)
     (symbolo val)
     (=/= 'closure val)
     (not-in-envo 'quote env))
    ((fresh (a d)
       (== `(quote (,a . ,d)) expr)
       (== `(,a . ,d) val)
       (=/= 'closure a)
       (=/= 'closure d)
       (not-in-envo 'quote env)))    
    ((symbolo expr)
     (lookupo expr env val))
    ((fresh (x e)
       (== `(lambda (,x) ,e) expr)
       (== `(closure ,x ,e ,env) val)
       (symbolo x)
       (not-in-envo 'lambda env)))
    ((fresh (e*)
       (== `(list . ,e*) expr)
       (not-in-envo 'list env)
       (eval-listo e* env val)))
    ((fresh (e1 e2 x e env^ arg env^^)
       (== `(,e1 ,e2) expr)
       (symbolo x)
       (eval-expro e1 env `(closure ,x ,e ,env^))
       (ext-envo x arg env^ env^^)
       (eval-expro e2 env arg)
       (eval-expro e env^^ val)))))

(define (eval-listo e* env v*)
  (conde
    ((== '() e*) (== '() v*))
    ((fresh (e e-rest v v-rest)
       (== `(,e . ,e-rest) e*)
       (== `(,v . ,v-rest) v*)
       (eval-expro e env v)
       (eval-listo e-rest env v-rest)))))





(test-check "eval-expro-w1"
  (run* (q)
    (eval-expro
     '(f (quote dog))
     `(,(set ∅ 'f)
       .
       ,(set ∅ `(f . (closure z z (,(set ∅ 'y) . ,(set ∅ '(y . cat)))))))
     q))
  '(dog))



(test-check "try-to-break-it-1"
  (run* (q)
    (fresh (t1 t2 a b)
      (== (list t1 t2) q)
      (== `(,a . ,b) t1)
      (seto a)
      (seto b)
      (== `(,(set ∅ 'y) . ,(set ∅ '(y . cat))) t2)
      (== t1 t2)))
  '((((set ∅ y) . (set ∅ (y . cat))) ((set ∅ y) . (set ∅ (y . cat))))))

(test-check "try-to-break-it-2"
  (run* (q)
    (fresh (t1 t2 a b)
      (== (list t1 t2) q)
      (== `(,(set ∅ 'y) . ,(set ∅ '(y . cat))) t2)
      (== `(,a . ,b) t1)
      (seto a)
      (seto b)
      (== t1 t2)))
  '((((set ∅ y) . (set ∅ (y . cat))) ((set ∅ y) . (set ∅ (y . cat))))))

(test-check "try-to-break-it-3"
  (run* (q)
    (fresh (t1 t2 a b)
      (== (list t1 t2) q)
      (== `(,(set ∅ 'y) . ,(set ∅ '(y . cat))) t2)
      (== `(,a . ,b) t1)
      (== t1 t2)
      (seto a)
      (seto b)))
  '((((set ∅ y) . (set ∅ (y . cat))) ((set ∅ y) . (set ∅ (y . cat))))))


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

(test-check "reification-complaint 1"
  (run* (q)
    (fresh (a b env)
      (== (list env a b) q)
      (== (set a b) env)))
  '((((set _.0 _.1) _.0 _.1)
     :
     (set _.0))))

(test-check "reification-complaint 2"
  (run* (q)
    (fresh (a b env)
      (== (list env a b) q)
      (seto b)
      (== (set a b) env)))
  '((((set _.0 _.1) _.0 _.1)
     :
     (set _.0 _.1))))

(test-check "ext-envo-split-sets-1"
  (run-unique* (q)
    (fresh (x v env env^)
      (== (list x v env env^) q)
      (ext-envo x v env env^)))
  '(((_.0
      _.1
      (_.2 . _.3)
      ((set _.2 _.0) . (set _.3 (_.0 . _.1))))
     :
     (sym _.0)
     (set _.2 _.3) ;; sus
     (!in (_.0 _.2)))
    ((_.0
      _.1
      ((set _.2 _.0) . (set _.3 (_.0 . _.4)))
      ((set _.2 _.0) . (set _.3 (_.0 . _.1))))
     :
     (sym _.0)
     (set _.2 _.3) ;; sus
     (!in ((_.0 . _.4) _.3)))))

(test-check "lookupo-w1"
  (run 1 (q)
    (lookupo
     'f
     `(,(set ∅ 'f)
       .
       ,(set ∅ `(f . (closure z z (,(set ∅ 'y) . ,(set ∅ '(y . cat)))))))
     q))
  '((closure z z ((set ∅ y) . (set ∅ (y . cat))))))

(test-check "lookupo-split-sets-1"
  (run-unique* (q) (lookupo 'z empty-env q))
  '())

(test-check "lookupo-split-sets-2"
  (run-unique* (q) (lookupo 'z `(,(set ∅ 'z) . ,(set ∅ '(z . 5))) q))
  '(5))

(test-check "lookupo-split-sets-3"
  (run-unique* (q) (lookupo 'w `(,(set ∅ 'w 'z) . ,(set ∅ '(w . 3) '(z . 4))) q))
  '(3))

(test-check "lookupo-split-sets-4"
  (run-unique* (q) (lookupo 'z `(,(set ∅ 'w 'z) . ,(set ∅ '(w . 3) '(z . 4))) q))
  '(4))

(test-check "lookupo-split-sets-5"
  (run-unique* (q) (lookupo 'x `(,(set ∅ 'w 'z) . ,(set ∅ '(w . 3) '(z . 4))) q))
  '())


(test-check "not-in-envo-split-sets-1"
  (run-unique* (q) (not-in-envo 'z `(,(set ∅ 'z) . ,(set ∅ '(z . 5)))))
  '())

(test-check "not-in-envo-split-sets-2"
  (run-unique* (q) (not-in-envo 'w `(,(set ∅ 'z) . ,(set ∅ '(z . 5)))))
  '(_.0))

(test-check "ext-envo-split-sets-1"
  (run-unique 1 (q)
    (fresh (x v env env^)
      (== (list x v env env^) q)
      (ext-envo x v env env^)))
  '(((_.0
      _.1
      (_.2 . _.3)
      ((set _.2 _.0) . (set _.3 (_.0 . _.1))))
     :
     (sym _.0)
     (set _.2 _.3)
     (!in (_.0 _.2)))))

(test-check "ext-envo-split-sets-2"
  (run-unique 1 (q)
    (fresh (x v env^)
      (== (list x v env^) q)
      (ext-envo x v empty-env env^)))
  '(((_.0
      _.1
      ((set ∅ _.0) . (set ∅ (_.0 . _.1))))
     :
     (sym _.0))))

(test-check "ext-envo-split-sets-3"
  (run-unique* (q)
    (fresh (x v env^)
      (== (list x v env^) q)
      (ext-envo x v `(,(set ∅ 'w 'z) . ,(set ∅ '(w . 3) '(z . 4))) env^)))
  '(((_.0
      _.1
      ((set ∅ _.0 w z) . (set ∅ (_.0 . _.1) (w . 3) (z . 4))))
     :
     (sym _.0)
     (=/= (_.0 w) (_.0 z)))
    (w _.0 ((set ∅ w z) . (set ∅ (w . _.0) (z . 4))))
    (z _.0 ((set ∅ w z) . (set ∅ (w . 3) (z . _.0))))))

(test-check "ext-envo-1"
  (run-unique* (q)
    (fresh (env env^)
      (== (list env env^) q)
      (ext-envo 'z 4 empty-env env)
      (ext-envo 'w 3 env env^)))
  '((((set ∅ z) . (set ∅ (z . 4)))
     ((set ∅ w z) . (set ∅ (w . 3) (z . 4))))))

(test-check "ext-envo-2"
  (run-unique* (q)
    (fresh (env env^)
      (== (list env env^) q)
      (ext-envo 'z 4 empty-env env)
      (ext-envo 'z 3 env env^)))
  '((((set ∅ z) . (set ∅ (z . 4)))
     ((set ∅ z) . (set ∅ (z . 3))))))

(test-check "evalo-1"
  (run-unique* (q)
    (evalo '((lambda (y) y) (list 'cat 'dog)) q))
  '((cat dog)))

(test-check "ext-envo-a"
  (run* (q)
    (ext-envo 'f `(closure z z (,(set ∅ 'y) . ,(set ∅ '(y . cat)))) empty-env q))
  '(((set ∅ f) . (set ∅ (f . (closure z z ((set ∅ y) . (set ∅ (y . cat)))))))))

(test-check "ext-envo-b"
  (run* (q)
    (ext-envo 'z 'dog `(,(set ∅ 'y) . ,(set ∅ '(y . cat))) q))
  '(((set ∅ y z) . (set ∅ (y . cat) (z . dog)))))


(test-check "ext-envo-u1"
  (run* (q)
    (eval-expro
     'f
     `(,(set ∅ 'f)
       .
       ,(set ∅ `(f . (closure z z (,(set ∅ 'y) . ,(set ∅ '(y . cat)))))))
     q))
  '((closure z z ((set ∅ y) . (set ∅ (y . cat))))))

(test-check "eval-expro-w0"
  (run* (q)
    (eval-expro
     'z
     `(,(set ∅ 'y 'z) . ,(set ∅ '(y . cat) '(z . dog)))
     q))
  '(dog))



(test-check "ino-1"
  (run* (q)
    (fresh (x e vars bindings)
      (== (list x e vars bindings) q)
      (ino `(f . (closure ,x ,e (,vars . ,bindings)))
           (set ∅ `(f . (closure z z (,(set ∅ 'y) . ,(set ∅ '(y . cat)))))))))
  '((z z (set ∅ y) (set ∅ (y . cat)))))

#|
(ino (f . (closure _.0 _.1 (_.2 . _.3)))
     (set ∅ (f . (closure z z ((set ∅ y) . (set ∅ (y . cat)))))))

"lookupo 4"
x: f
env: (#(#() (f)) . #(#() ((f closure z z (#(#() (y)) . #(#() ((y . cat))))))))
val: (closure #(x) #(e) (#(vars) . #(bindings)))
vars: #(#() (f))
bindings: #(#() ((f closure z z (#(#() (y)) . #(#() ((y . cat)))))))

(ino (f closure #(x) #(e) (#(vars) . #(bindings)))
     #(#() ((f closure z z (#(#() (y)) . #(#() ((y . cat))))))))

((ino (f . (closure _.0 _.1 (_.2 . _.3)))
      (set ∅ (f . (closure z z ((set ∅ y) . (set ∅ (y . cat)))))))
 :
 (sym _.0)
 (set _.2 _.3)
 (!in (_.0 _.2)))

Exception in car: #<procedure at mk.scm:9714> is not a pair
Type (debug) to enter the debugger.
|#


(test-check "eval-expro-w2"
  (run* (q)
    (fresh (env)
      (ext-envo 'f `(closure z z (,(set ∅ 'y) . ,(set ∅ '(y . cat)))) empty-env env)
      (eval-expro '(f 'dog) env q)))
  '(dog))

(test-check "eval-expro-w3"
  (run-unique* (q)
    (fresh (env)
      (ext-envo 'f `(closure z z (,(set ∅ 'y) . ,(set ∅ '(y . cat)))) empty-env env)
      (eval-expro '(f 'dog) env q)))
  '(dog))

(test-check "evalo-2"
  (run-unique* (q)
    (evalo '((lambda (y) (((lambda (z) z) (lambda (w) w)) y))
             (list 'cat 'dog)) q))
  '((cat dog)))

(test-check "evalo-3"
  (run-unique* (q)
    (evalo '((lambda (y) (((lambda (y) y) (lambda (y) y)) y))
             (list 'cat 'dog)) q))
  '((cat dog)))

(test-check "evalo-4"
  (run-unique* (q)
    (evalo '(((lambda (list) (list list)) (lambda (list) list))
             (list 'cat 'dog)) q))
  '((cat dog)))

(test-check "evalo-5"
  (run-unique* (q)
    (evalo '(((lambda (x) (lambda (y) (list x y))) 'cat) 'dog) q))
  '((cat dog)))

(test-check "evalo-6"
  (run-unique* (q)
    (evalo '(((lambda (x) (lambda (x) (list x x))) 'cat) 'dog) q))
  '((dog dog)))

(test-check "eval-expro-1"
  (run-unique* (env)
    (eval-expro 'z env 'cat))
  '((((set _.0 z) . (set _.1 (z . cat)))
     :
     (set _.0 _.1))))

;; hmm--because I was missing absento, I ended up being too strict on
;; quoting, so I no longer allow quoting pairs.
(test-check "quine-0"
  (run-unique 1 (q)
    (== '((lambda (x) (list x (list 'quote x)))
          (quote (lambda (x) (list x (list 'quote x)))))
        q)
    (evalo q q))
  '(((lambda (x) (list x (list 'quote x)))
     '(lambda (x) (list x (list 'quote x))))))

(test-check "quine-1"
  (run-unique 1 (q)
    (evalo q q))
  '((((lambda (_.0) (list _.0 (list 'quote _.0)))
      '(lambda (_.0) (list _.0 (list 'quote _.0))))
     :
     (sym _.0)
     (=/= (_.0 list)
          (_.0 quote)))))

(test-check "twine-1"
  (run-unique 1 (ans)
    (fresh (p q)
      (== (list p q) ans)
      (=/= p q)
      (evalo p q)
      (evalo q p)))
  '((('((lambda (_.0)
          (list 'quote (list _.0 (list 'quote _.0))))
        '(lambda (_.0)
           (list 'quote (list _.0 (list 'quote _.0)))))
      ((lambda (_.0)
         (list 'quote (list _.0 (list 'quote _.0))))
       '(lambda (_.0)
          (list 'quote (list _.0 (list 'quote _.0))))))
     :
     (sym _.0)
     (=/= (_.0 list)
          (_.0 quote)))))
