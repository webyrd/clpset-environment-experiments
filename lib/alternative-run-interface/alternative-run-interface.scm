;; `run-unique <n>` and `run-unique*` act like their normal `run <n>`
;; and `run*`, except that only unique answers are returned.
;;
;; `run-unique 2` returns up to 2 unique answers, if they exist; if 2
;; answers don't exist, `run-unique 2` may return a list of 0 or 1
;; answers, or may diverge (loop forever).

(define (take-unique n f)
  (let ((seen (make-hashtable equal-hash equal?)))
    (letrec ((take-unique
              (lambda (n f)
                (if (and n (zero? n))
                    '()
                    (case-inf (f)
                      (() '())
                      ((f) (take-unique n f))
                      ((a)
                       (let ((ans (car a)))
                         (let ((prev (hashtable-ref seen ans #f)))
                           (if prev '() (cons ans '())))))
                      ((a f)
                       (let ((ans (car a)))
                         (let ((prev (hashtable-ref seen ans #f)))
                           (if prev
                               (take-unique n f)
                               (begin
                                 (hashtable-set! seen ans #t)
                                 (cons ans
                                       (take-unique (and n (- n 1)) f))))))))))))
      (take-unique n f))))

(define-syntax run-unique
  (syntax-rules ()
    ((_ n (x) g0 g ...)
     (take-unique n
       (lambdaf@ ()
         ((fresh (x) g0 g ...
                 run-constraints
                 (lambdag@ (s)
                   (cons (reify x s) '())))
          empty-s))))))

(define-syntax run-unique*
  (syntax-rules ()
    ((_ (x) g ...) (run-unique #f (x) g ...))))
