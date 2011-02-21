
;; many commands, which didn't make it to the global keymap.
;; these commands are not used often, and usually require some more interaction.

;; When followed by right hand keys, some non-repeatable commands on 1 window.

(require 'mmc.extremes)

;;(define (require-cautiously symbol)
(my-require 'mmc.resize)


(bind-keys hc-keymap

  " " 'my-add-to-group
  "v" 'describe-key-to-screen
  "w" 'where-is-command

  "H-v" 'describe-key-to-screen
  "r"   'my-resize-window
  "M-m" 'customize:match-window



                                        ; conferma, che xallowevents is bad
  "j" 'extreme-window-w
  "k" 'extreme-window-s
  "l" 'extreme-window-e
  "i" 'extreme-window-n

  "u" 'extreme-window-nw
  "o" 'extreme-window-ne
  "m" 'extreme-window-sw
  "." 'extreme-window-se

  )