(require 'mmc.my-viewport)
(require 'sawfish.wm.commands.slide-window)


(bind-keys global-keymap
  "H-M-u" (lambda (window)
            (interactive "%W")
            (slide-window window (- slide-window-increment)  (- slide-window-increment)))

  ;; 'slide-window-up-left

  ;;   (lambda ()
  ;;        (interactive)
  ;;        (call-command 'slide-window-up)
  ;;        (call-command 'slide-window-left))
  "H-m" (lambda ()
          (interactive)
          (move-viewport-possibly -1 1))

  "H-o" (lambda ()
          (interactive)
          (move-viewport-possibly 1 -1)
                                        ;(call-command 'slide-window-left)
          )

  "H-U" (lambda (win)
                                        ;#:spec "%W" #:class 'viewport)
          (interactive "%W")
          (move-group-possibly-to win -1 -1))

  "H-u" (lambda ()
          (interactive)
          (move-viewport-possibly -1 -1))

  "H-." (lambda ()
          (interactive)
          (move-viewport-possibly 1 1))

  "H-M-m" (lambda (window)
            (interactive "%W")
                                        ;(call-command 'slide-window-down)
                                        ;(call-command 'slide-window-left)
            (slide-window window (- slide-window-increment)  slide-window-increment)
            )
  "H-M-o" (lambda  (window)
            (interactive "%W")
            (interactive)
            (slide-window window  slide-window-increment  (- slide-window-increment))
                                        ;(call-command 'slide-window-up)
                                        ;(call-command 'slide-window-right)
            )
  "H-M-." (lambda  (window)
            (interactive "%W")
                                        ;(call-command 'slide-window-down)
                                        ;(call-command 'slide-window-right)
            (slide-window window slide-window-increment slide-window-increment)
            )

  "H-C-x" (lambda () (interactive) (backtrace (stderr-file))))


;; here i handle the problem of windows disappearing sometime:
(bind-keys my-recover-keymap
  "i" (lambda ()
        (setq viewport-y-offset
              (+ viewport-y-offset
                 (screen-height)))
        (move-viewport 0 -1))
  "j" (lambda ()
        (setq viewport-x-offset
              (+ viewport-x-offset
                 (screen-width)))
        (move-viewport -1 0))
  "l" (lambda ()
        (setq viewport-x-offset
              (- viewport-x-offset
                 (screen-width)))
        (move-viewport 1 0))

  "k" (lambda ()
        (setq viewport-y-offset
              (- viewport-y-offset
                 (screen-height)))
        (move-viewport 0 1))
  )
