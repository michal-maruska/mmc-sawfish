
;; additional functions:
;; should i integrate it?

(define-structure mmc.my-viewport
    (export
      move-viewport-possibly
      ;move-to-viewport-possibly
      move-group-possibly-to
      viewport-windows)

    (open
     rep
     rep.mmsystem
     rep.io.files
     
     sawfish.wm.misc
     rep.data.tables
     sawfish.wm.commands
     sawfish.wm.workspace
     sawfish.wm.viewport
     sawfish.wm.viewport-hi
     sawfish.wm.windows.subrs           ;managed-windows
     mmc.display
					;sawfish.wm.util.prompt
     mmc.simple
     sawfish.wm.commands.groups)

  ;; 1-d/line interval: 
  (define (outside x min max)
    (or (> x max)
	(< x min)))

  (define (viewport-possibly x y)
    ;; try to move in the directions: 
    (let ((now-x (car (screen-viewport)))
	  (now-y (cdr (screen-viewport))))
      (if (outside (+ now-x x) 0 (- (car viewport-dimensions) 1))
	  (setq x 0))

      (if (outside (+ now-y y) 0 (- (cdr viewport-dimensions) 1))
          (setq y 0))
                                        ;(message-format "viewport-possibly: %d %d" x y)
      (cons x y)))


  (define (move-viewport-possibly x y)
    (let ((vp  (viewport-possibly x y)))
      (move-viewport (car vp) (cdr vp))))

  (define (move-group-possibly-to window x y)
    (let ((vp  (viewport-possibly x y)))
      (move-group-viewport window (car vp) (cdr vp))))


;;; copied form `sawfish.wm.util.window-order'
  (define (viewport-windows)
    (let ((windows (managed-windows))
          (workspace current-workspace))
      (setq windows (delete-if (lambda (w)
                                 (or (not (window-mapped-p w))
                                     (window-get w 'ignored)
					;(and (not allow-iconified)
                                     (window-get w 'iconified)
                                     (not (window-appears-in-workspace-p
                                           w workspace))))
                      windows))
      (setq windows (delete-if window-outside-viewport-p windows)))))
