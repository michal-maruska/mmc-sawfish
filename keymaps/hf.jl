(require 'mmc.cycle)



(bind-keys my-window-keymap
  "n" 'window-name


  ;; use directional keys!

  "j" 'maximize-window-horizontally-toggle

  "C-i" 'maximize-fill-window-vertically-toggle
  "C-j" 'maximize-fill-window-horizontally-toggle

  "i" 'maximize-window-vertically-toggle ;fill
  "k" 'maximize-window-toggle
  "u" 'maximize-window-fullscreen-toggle
                                        ;"m" 'popup-window-menu


  "?" 'window-snooper
  "x" 'xprop
  "o" 'resize-window-interactively-box
  "m" 'my-move-window
  ;; "k" 'maximize-window-toggle
  ;; i'd need a warning !!

  "l" 'resize-window-interactively

  ;; fails!!
  "c" 'window-class
                                        ;center-mouse
  "q" 'destroy-window
  "w" 'delete-window-instance
  "q" 'kill-client-warning
  "." 'move-window-here
  "d" 'describe-window-to-log
  "a" 'wid-assign-wid-to-window
  "H-a" 'wid-assign-wid-to-window

  "H-f" 'my-resize-window
  "f" 'my-resize-window

  "v" 'my-resize-right-bottom
  ;; testing

  ;;   "H-f" (lambda ()
  ;;      (interactive)
  ;;      (message "double H-f"))

  "b" 'bury-window



  "M-j" 'extreme-window-w
  "M-k" 'extreme-window-s
  "M-l" 'extreme-window-e
  "M-i" 'extreme-window-n

  "M-u" 'extreme-window-nw
  "M-o" 'extreme-window-ne
  "M-m" 'extreme-window-sw
  "M-." 'extreme-window-se
  )
