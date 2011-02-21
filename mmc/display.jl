;; display temporarily a text (after a certain time it's cleared)

(define-structure mmc.display
    (export
      display-with-timer
      display-information
      ;;
      ;; message-format
      )
    (open
     rep
     rep.system
     rep.io.timers
     sawfish.wm.misc
     mmc.x-message
     )
                                        ;(define (call-with-timer function time name)
                                        ; call FUNCTION, after TIME, unless NAME... 
                                        ;  )

  ;; (display-message-timeout 1 "message")
  ;; (set-timer clear-timer 5)


  (define the-timer ()
    ;; fixme: This should be per-window!
    "timer used for cleaning message area")
  
;; for now:
  (defvar information-message-window #f "")


  (define (clean-message-timer-action timer window)
    (declare (unused timer))
    (setq the-timer #f)
                                        ;(display-message)
    (when (message-window? window)
      (x-message-hide window)
      ;; window shall be GC-ed!
                                        ;(setq information-message-window #f)
      ))


  (define (display-with-timer message-text sec args #!key (window information-message-window)) ; ;; #!optional
    "display for SEC seconds MESSAGE"
    ;; bug! i don't want to clean, if something else has appeared in between. For now, i cannot detect it.
    
    ;; i have to push!
    '(when (message-window? window)
      ;(message "hiding...")
      (x-message-hide window))
                                        ;(setq information-message-window #f)
    (setq information-message-window
          (let ((window
                 (if window
                     (x-message-display
                      (split-nl message-text)
                      args
                      #:window window)
                   (x-message-display
                    (split-nl message-text)
                    args))))
            (setq the-timer (make-timer
                             (lambda (timer)
                                        ;(beep)
                               (clean-message-timer-action timer window)
                               (setq information-message-window '()))
                             sec))
            window)))


;; On reload this might leak?  better defvar ?
  (define display-windows '())

  (define (display-information message
                               #!optional
                               args
                               #!key
                               (tag 'info)
                               (seconds 2)
                               )  ;#!optional
    ;; tag identifies a window --- we can reuse the same window, i.e. one message (automatically) hides, or excludes, the other.
    (let ((window-pair (assoc tag display-windows)))
      
    ;; in a corner
    (unless (assq 'position args)
      (setq args (cons (cons 'position '(1600 . 1200)) args)))
    (let ((new-window
           (if window-pair
               ;; I might have to change it!
               (display-with-timer message seconds args
                                   #:window (cdr window-pair)))))
      (if window-pair
          (setcdr window-pair new-window)
        ;; push
        (setq display-windows
              (cons (cons tag new-window)
                     display-windows))
        )))))

