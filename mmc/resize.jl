
;;resizing via mouse & keyboard mouse emulation.
;; needs xkb SUBRs (C code)

;; This defines 2 commands, to resize by dragging the upper/left  or bottom/right corner.
;; They also switch on the mouse-emulation by XKB, so i can have the mouse acceleration (non-linear) applied to keyboard.

;; `last-position-warped' is a variable i had to insert into the `sawfish.wm.commands.move-resize' code:
;;  where i use:    move-resize-last-ptr ..... (or last-position-warped (query-pointer t))

(define-structure mmc.resize
    (export
      my-resize-window
      my-resize-right-bottom
      )
    (open
     rep
     rep.system
     rep.mmsystem
     sawfish.wm.windows
     sawfish.wm.events
     sawfish.wm.misc
     sawfish.wm.commands.move-resize
     sawfish.wm.commands
     )
                                        ;(setq resize-outline-mode 'box)
                                        ;(setq move-outline-mode 'box)
  (define (resize-window-interactively-box window)
    "do it as BOX"
                                        ;(interactive "%W")
    (let ((original-mode resize-outline-mode))
      (unwind-protect
          (progn
            (setq resize-outline-mode 'box)
            (resize-window-interactively window))
        (setq resize-outline-mode original-mode))))


  (define (my-resize-window w)
    ;; resize w/ kbd in mouse emulation
    (let ((warp-to-window-enabled 't))
      (set-key-mouse-params 10 40 50 60 10)
      (warp-cursor-to-window w 0 0)     ; who knows what to resize ....
      (setq last-position-warped (window-position w))
                                        ;(allow-events 'async-pointer)
                                        ;(query-pointer 't)
                                        ;(warp-to-selected-windows
      (display-message (format #f "ppointer: %s %s"
                               (query-button-press-pointer)
                               (query-pointer t)))
      (enable-key-mouse 1)
      (resize-window-interactively w)
      (enable-key-mouse 0)))



  (define (my-resize-right-bottom w)
    (let ((warp-to-window-enabled 't)
          (dim (window-dimensions w))
          (pos (window-position w)))
      (with-key-repeat-rate 180 25
        (set-key-mouse-params 10 40 50 60 10)
        (warp-cursor-to-window w (car dim) (cdr dim))
        (setq last-position-warped
              (cons (+ (car pos) (car dim))
                    (+ (cdr pos) (cdr dim))))
        (message (format #f "last-position-warped: %s" last-position-warped))
        (window-position w)
        (window-dimensions w)
      
      
                                        ;(allow-events 'async-pointer)
                                        ;(message (format #f "after allow-events: %s" (query-pointer t)))
        ;;(warp-cursor-to-window w 0 0)    ; who knows what to resize ....
                                        ;(warp-to-selected-windows
        (display-message (format #f "ppointer: %s %s"
                                 (query-button-press-pointer)
                                 (query-pointer t)))
        (enable-key-mouse 1)
        (resize-window-interactively w)
        (enable-key-mouse 0))))
       
  (define-command 'my-resize-right-bottom  my-resize-right-bottom
                  #:spec "%W")
                
  (define (my-move-window w)
    ;; resize w/ kbd in mouse emulation
    (let ((warp-to-window-enabled 't))
      (set-key-mouse-params 10 40 50 60 10)
                                        ;(warp-cursor-to-window w 0 0)
                                        ;(warp-to-selected-windows
      (display-message (format #f "ppointer: %s %s"
                               (query-button-press-pointer)
                               (query-pointer t)))
      (enable-key-mouse 1)
      (move-window-interactively w)
      (enable-key-mouse 0)))


  (define-command 'my-resize-window my-resize-window #:spec "%W")
  (define-command 'resize-window-interactively-box
    resize-window-interactively-box #:spec "%W")

  (define-command 'my-move-window my-move-window #:spec "%W")
  )


(when #f
  (defun mmy-resize-window (w)
    (interactive "%W")
    (let ((warp-to-window-enabled 't))
      (setq warp-to-window-enabled 't)
      (warp-cursor-to-window w 1 1)
      (display-message (format #f "pointer: %s %s"
                               (query-button-press-pointer)
                               (query-pointer t)))))

                                        ;(resize-window-interactively w)

  (warp-cursor-to-window (input-focus) 0 0)
  (require 'sawfish.wm.commands)
  (define-command 'mmy-resize-window mmy-resize-window #:spec "%W")
  )
