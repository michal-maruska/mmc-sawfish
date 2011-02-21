


(define-structure mmc.themes
    (export
      mapcar-frame-parts
      )
    
    (open
     rep
     rep.system
     mmc.simple
     sawfish.wm.windows.subrs
     sawfish.wm.frames.subrs
     )



  (define (mapcar-frame-parts function window)
    (let ((values '()))
      (map-frame-parts
       (lambda (fp)
         (push! values (function fp)))
       window)
      values))
  )
    