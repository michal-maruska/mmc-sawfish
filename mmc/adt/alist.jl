
(define-structure mmc.adt.alist
    (export
      assqd
      agetd
      aget
      )

    (open
     rep
     rep.system
     rep.io.files
     rep.mmsystem
     rep.data.tables
     rep.trace
     )


  ;; Accessing alists
  (define (assqd key alist default)
    (or
     (assq key alist)
     (cons key default)))

  (define (agetd key alist default)
    (let ((found (assq key alist)))
      (if found 
          (cdr found)
        default)))

  (define (aget key list)
    (agetd key alist nil))
  )