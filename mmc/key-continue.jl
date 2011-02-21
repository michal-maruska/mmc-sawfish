
(define-structure mmc.key-continue
    (export
      call-for-next-key-events
      call-for-next-key-events*
      )
    (open
     rep
     rep.system
     rep.mmsystem
     
     sawfish.wm.events
     )

  
;; is this sufficient?
  (define (throw-event-to-our-tag)
    (throw 'our-tag
           (cons (event-name (current-event))
                 (current-event-string))))

  (define (call-for-next-key-events waiting-hook function) ;TAG
    "run FUNCTION on the next key event. "
    (let ((old-unbound-hook (mm-hook-under-symbol 'unbound-key-hook 'key-processor)))
      (unwind-protect
          (let ((override-keymap '(keymap))) ;; Switch-off keymap.
            ;; iswitch-read-event
            (add-hook-under-symbol 'unbound-key-hook throw-event-to-our-tag 'key-processor) ;fixme: should be at the end? it's an OR-hook
            ;;(add-hook 'unbound-key-hook iswitch-read-event) ; throw the keys
            (while t
              (if waiting-hook
                  (waiting-hook))
              (let ((event (catch 'our-tag ;
                             (allow-events 'sync-keyboard); fixme!
                             (recursive-edit)))) ;   something like   invoking a continuation !!!
                (function event))))
        (if old-unbound-hook
            ;; This implicitely removes ours!
            (add-hook-under-symbol 'unbound-key-hook old-unbound-hook 'key-processor)
          (progn
            (mm-remove-hook-symbol 'unbound-key-hook 'key-processor))))))


  ;; This hides the lack of using continuations.
  (defmacro call-for-next-key-events* (variable hook #!rest body)
    `(call-for-next-key-events
      ,hook
      (lambda (,variable)
        ,@body)))
)