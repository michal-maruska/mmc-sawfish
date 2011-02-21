
;;; Command/keybinding  for `moving'

;; hack:
(unbind-keys window-keymap "W-Up")
(unbind-keys window-keymap "W-Down")

(unbind-keys window-keymap "H-Up")
(unbind-keys window-keymap "H-Down")

(unbind-keys global-keymap "H-Up")
(unbind-keys global-keymap "H-Down")

(require 'mmc.animate-move)


;; this is quite hacky:
;; b/c i know better.
;;   prefix-of-command     key-prefix  suffixes
(define (bind-directions cmd-prefix key-prefix suffix-list #!key (keymap global-keymap))
  "Bind a set of directional versions of the same command to keys:
keys are given by KEY-PREFIX + arrow key
and the commands are given by CMD-PREFIX followed by up/down/left/right"
  (let ((my-bind-one (lambda (suffix-pair)
                       (let* ((key-suff (cdr suffix-pair))
                              (cmd-suff (car suffix-pair))
                              (symbol (intern (concat cmd-prefix cmd-suff))))
                         (bind-keys keymap
                           (concat key-prefix key-suff) symbol)))))
    (mapcar my-bind-one suffix-list)))


(let ((standard
       ;; arrow-keys
       '(("right". "Right")
         ("left". "Left")
         ("up". "Up")
         ("down". "Down") ))
      ;; used in ghostview ?
;;       (ghostview
;;        '(("right". "j")
;;          ("left". "h")
;;          ("up". "k")
;;          ("down". "l") ))
;;       ;; 
;;       (bad
;;        '(("right". "s")
;;          ("left". "a")
;;          ("up". "f")
;;          ("down". "d") ))
;;       ;;  right hand:
      (test
       '(("right". "l")
         ("left". "j")
                                        ;("right". ";")
                                        ;("up". "p")
                                        ;("down". "m")
         ("up". "i")
         ("down". "k")
         ))
      ;; bad, because hyper is not reached by "thumb in normal position"
;;       (emacs
;;        '(("right". "f")
;;          ("left". "b")
;;          ("up". "p")
;;          ("down". "n")))
      )

  (bind-directions "move-viewport-"  "H-" test)
  (bind-directions "move-viewport-"  "H-" standard)

  (if #f
      (bind-directions "animate-move-window-"  "H-M-" test)
    (bind-directions "slide-window-"  "H-M-" test))
    
  (bind-directions "move-window-"  "H-S-" test)

  ;; this is for newcommers:
  (bind-directions "move-viewport-"  "H-" standard)
  (bind-directions "slide-window-"  "H-S-" standard)
  (bind-directions "move-window-"  "H-S-" standard)

  ;;(bind-directions "move-group-"  "H-S-" test #:group groups-keymap)
  ;;  (bind-directions "move-window-" "S-H-M-" standard)
  )





(bind-keys global-keymap 
  "H-C-l" 'size-window-add-column
  "H-C-j" 'size-window-subtract-column
  "H-C-i" 'size-window-subtract-row
  "H-C-k" 'size-window-add-row)



(require 'mmc.my-viewport)


;; inconsistency!  i move groups in diagonal!
(let ((make (lambda (i j)
              (lambda (win)
                (interactive "%W")
                (move-group-possibly-to win i j)))))
  (bind-keys global-keymap
    "H-U" (make -1 -1)
    "H-O" (make 1 -1)
    "H-M" (make -1 1)
    "H-," (make 1 1)))


;;