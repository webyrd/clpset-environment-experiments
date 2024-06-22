(load "../lib/clpset-miniKanren/mk.scm")
(load "../lib/alternative-run-interface/alternative-run-interface.scm")
(load "../lib/clpset-miniKanren/test-check.scm")

(define empty-env ∅)
(define (ext-envo x v env env^)
  (fresh ()
    (symbolo x)
    ;; In this encoding we add to the `env` both `x` and the pair
    ;; binding `x` to `v`.  This allows us to use `(!ino x env)` to
    ;; ensure `x` is not already bound in `env`.
    (conde
      ((!ino x env)
       ;; Case 1: not shadowing `x`
       ;;
       ;; `x` isn't in `env`, so we are free to add the binding
       ;; between `x` and `v`, along with `x` so we can check
       ;; for shadowing in the future.
       (== (set env x `(,x . ,v)) env^))
      ((fresh (v^ env-minus-x-binding)
         ;; Case 2: shadowing `x`
         ;;
         ;; There is already a binding between `x` and `v^` in `env`,
         ;; so we must create a new environment `env-minus-x-binding`
         ;; that is identical to `env`, minus the `x`/`v^` binding.
         ;; We can safely extend `env-minus-x-binding` with the
         ;; `x`/`v` binding to produce `env^`.
         (ino x env)
         (ino `(,x . ,v^) env)
         (!ino `(,x . ,v^) env-minus-x-binding)
         (uniono (set ∅ `(,x . ,v^)) env-minus-x-binding env)
         (== (set env-minus-x-binding x `(,x . ,v)) env^))))))
(define (lookupo x env val)
  (fresh ()
    (symbolo x)
    (ino x env)
    (ino `(,x . ,val) env)))
(define (not-in-envo x env)
  (fresh ()
    (symbolo x)
    (!ino x env)))

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
       (symbolo x)))
    ((fresh (e*)
       (== `(list . ,e*) expr)
       (not-in-envo 'list env)
       (eval-listo e* env val)))
    ((fresh (e1 e2 x e env^ arg env^^)
       (== `(,e1 ,e2) expr)
       (eval-expro e1 env `(closure ,x ,e ,env^))
       (eval-expro e2 env arg)
       (ext-envo x arg env^ env^^)
       (eval-expro e env^^ val)))))

(define (eval-listo e* env v*)
  (conde
    ((== '() e*) (== '() v*))
    ((fresh (e e-rest v v-rest)
       (== `(,e . ,e-rest) e*)
       (== `(,v . ,v-rest) v*)
       (eval-expro e env v)
       (eval-listo e-rest env v-rest)))))



(test-check "ext-envo-1"
  (run-unique* (q)
    (fresh (env env^)
      (== (list env env^) q)
      (ext-envo 'z 4 empty-env env)
      (ext-envo 'w 3 env env^)))
  '(((set ∅ (z . 4) z) (set ∅ (w . 3) (z . 4) w z))))

(test-check "ext-envo-2"
  (run-unique* (q)
    (fresh (env env^)
      (== (list env env^) q)
      (ext-envo 'z 4 empty-env env)
      (ext-envo 'z 3 env env^)))
  '(((set ∅ (z . 4) z) (set ∅ (z . 3) z))))


(test-check "evalo-1"
  (run-unique* (q)
    (evalo '((lambda (y) y) (list 'cat 'dog)) q))
  '((cat dog)))

(test-check "evalo-2"
  (run-unique* (q)
    (evalo
     '((lambda (y) (((lambda (z) z) (lambda (w) w)) y))
       (list 'cat 'dog))
     q))
  '((cat dog)))

(test-check "evalo-3"
  (run-unique* (q)
    (evalo
     '((lambda (y) (((lambda (y) y) (lambda (y) y)) y))
       (list 'cat 'dog))
     q))
  '((cat dog)))

(test-check "evalo-4"
  (run-unique* (q)
    (evalo
     '(((lambda (list) (list list)) (lambda (list) list))
       (list 'cat 'dog))
     q))
  '((cat dog)))

(test-check "evalo-5"
  (run-unique* (q)
    (evalo
     '(((lambda (x) (lambda (y) (list x y)))
        'cat)
       'dog)
     q))
  '((cat dog)))

(test-check "evalo-6"
  (run-unique* (q)
    (evalo
     '(((lambda (x) (lambda (x) (list x x)))
        'cat)
       'dog)
     q))
  '((dog dog)))


(test-check "eval-expro-1"
  (run-unique* (env)
    (eval-expro 'z env 'cat))
  '(((set _.0
          (z . cat)
          z)
     :
     (set _.0))))

(test-check "eval-expro-2a"
  (run-unique* (env)
    (!ino 'quote env)
    (eval-expro '(quote cat) env 'cat))
  '((_.0
     :
     (set _.0)
     (!in (quote _.0)))))

(test-check "eval-expro-2ab"
  (run-unique 2 (env)
    (ino 'quote env)
    (eval-expro '(quote cat) env 'cat))
  '(((set _.0
          (cat . _.1)
          (quote . (closure _.2 (quote cat) _.3))
          cat
          quote)
     :
     (sym _.2)
     (set _.0 _.3)
     (=/= (_.2 quote))
     (!in (quote _.3)
          (_.2 _.3)))
    ((set _.0
          (cat . cat)
          (quote . (closure _.1 _.1 _.2))
          cat
          quote)
     :
     (sym _.1)
     (set _.0 _.2)
     (!in (_.1 _.2)))))

(test-check "eval-expro-2b"
  (run-unique 3 (env)
    (!ino 'lambda env)
    (!ino 'quote env)
    (eval-expro `((lambda (y) y) 'cat) env 'cat))
  '((_.0
     :
     (set _.0)
     (!in (quote _.0)
          (lambda _.0)
          (y _.0)))
    ((set _.0 (y . cat))
     :
     (set _.0)
     (!in (quote _.0)
          (lambda _.0)
          (y _.0)))
    ((set _.0
          (y . _.1) y)
     :
     (set _.0)
     (!in (quote _.0)
          ((y . _.1) _.0)
          (lambda _.0)
          (y _.0)))))

(test-check "eval-expro-2c"
  (run-unique 3 (q)
    (fresh (e env)
      (== (list e env) q)
      (symbolo e)
      (!ino 'lambda env)
      (!ino 'quote env)
      (eval-expro `((lambda (y) ,e) 'cat) env 'cat)))
  '(((y _.0)
     :
     (set _.0)
     (!in (quote _.0)
          (lambda _.0)
          (y _.0)))
    ((y (set _.0 (y . cat)))
     :
     (set _.0)
     (!in (quote _.0)
          (lambda _.0)
          (y _.0)))
    ((_.0 (set _.1 (_.0 . cat) _.0))
     :
     (sym _.0)
     (set _.1)
     (=/= (_.0 lambda)
          (_.0 quote)
          (_.0 y))
     (!in (quote _.1)
          (lambda _.1)
          (y _.1)))))

(test-check "eval-expro-3"
  (run-unique 3 (q)
    (fresh (e env)
      (== (list e env) q)
      (symbolo e)
      (!ino 'lambda env)
      (!ino 'list env)
      (!ino 'quote env)
      (eval-expro
       `((lambda (y) ,e) (list 'cat 'dog))
       env
       '(cat dog))))
  '(((y _.0)
     :
     (set _.0)
     (!in (quote _.0)
          (lambda _.0)
          (list _.0)
          (y _.0)))
    ((y (set _.0 (y cat dog)))
     :
     (set _.0)
     (!in (quote _.0)
          (lambda _.0)
          (list _.0)
          (y _.0)))
    ((_.0 (set _.1 (_.0 cat dog) _.0))
     :
     (sym _.0)
     (set _.1)
     (=/= (_.0 lambda)
          (_.0 list)
          (_.0 quote)
          (_.0 y))
     (!in (quote _.1)
          (lambda _.1)
          (list _.1)
          (y _.1)))))

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
