(define-structure mmc.adt.list
    (export
      pop! push!
      append!
      set-nth!
      delete-nth-from-list!
      filter-morphing
      safe-car
      safe-cdr
      )

    (open
     rep
     rep.system
     rep.io.files
     rep.mmsystem
     rep.data.tables
     rep.trace
     )

  (defmacro pop! (symbol)
    `(setq ,symbol (cdr ,symbol)))


  (defmacro push! (symbol item)
    `(setq ,symbol (cons ,item ,symbol)))



  (define (set-nth! list n value)
    (rplaca (nthcdr n list) value))
  

  (define (delete-nth-from-list! list n)
    (if (> n 0)
        (progn
          (setcdr (nthcdr (1- n) list) (nthcdr (1+ n) list))
          list)
      (error "cannot delete the 0-th element. use cdr")))



;; compiler need to know, that function accepts 1 arg!
;; (declare function ...)
  (define (filter-morphing function list)
    ;; make a list, which is composed
    ;; of those elements of LIST, for which FUNCTION returns #t, if the function returns
    ;; a non #f, that _result_ is taken as a substitute,  #f -> nothing is included in the result list
    ;; and we want it  tail-recursive !
    (letrec ((filter-morphing-collect
              (lambda (so-far rest)
                (if (null rest)         ; we have finished, return the collected list:
                    so-far
                  (let* ((item (car rest))
                         (result (funcall function item)))
                    ;; here lies the definition:
                    (cond ((eq result #t)
                           (filter-morphing-collect (cons item so-far) (cdr rest)))
                          ((eq result #f)
                           (filter-morphing-collect so-far (cdr rest)))
                          ('t (filter-morphing-collect (cons result so-far) (cdr rest)))))))))
      (reverse (filter-morphing-collect '() list))))


;; fails for non list!
  (define (safe-car a #!optional default)
    (if (null a)
        (or default '())
      (car a)))

  (define (safe-cdr a)
    (if (null a)
        a
      (cdr a)))


  (define (append! a b)
    (if (not (listp b))
        (error "append!: wrong argument, 2"))
    (if (null b)
        a)
    (let step ((a a))
         (if (not (consp a))
             (error "append!: wrong argument, 1"))
         (if (null (cdr a))
             (setcdr a b)
           (step (cdr a) b))))
  )
