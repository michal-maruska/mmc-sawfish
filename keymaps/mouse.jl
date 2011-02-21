
;;; `mouse':

;;"M-Button1-Move" 'resize-window-interactively-box
(require 'sawfish.wm.focus)
(require 'sawfish.wm.commands.x-cycle)

(require 'sawfish.wm.commands.move-resize)

;; substitute-wm-modifier ?
(bind-keys window-keymap
  ;; 
  "H-Button1-Move" 'resize-window-interactively
;  "M-Button3-Move" 'resize-window-interactively
  "M-Button1-Move" 'move-window-interactively ; ???


  ;"H-Button1-click2" 'toggle-window-shaded
  "Button1-click1" 'raise-and-pass-through-click
					; focus-click
  "M-Button1-Click" 'raise-window
  ;;  "Button4-click" 'call-command-with-output-to-screen
  )


;(unbind-keys  window-keymap "Button1-Click")


(bind-keys global-keymap
  "H-Button1-click2" (lambda ()
		       (display-message "double click"))

  "H-Button1-click1" (lambda ()
		       ;(display-message "single click")
                       1
                       )

  ;; [11 apr 07]    no! annoying (by error)
  ; "H-Button4-click" 'cycle-modulo-ws
					;next-workspace
  ; "H-Button5-click" 'previous-workspace
  )
  

;(unbind-keys window-keymap "W-Button3-Click")
; "H-Button1-click2")
; (unbind-keys global-keymap "M-Right")

(bind-keys title-keymap
  "M-Button1-click" 'toggle-window-shaded
  "H-Button1-click" 'toggle-window-shaded

  "H-Button1-click2" 'iconify-window
  )

 ;(move-window-interactively 3 . 131328)
 ;(toggle-window-shaded 6 . 131328)
 ;(resize-window-interactively 3 . 131584)
 ;(raise-lower-window 4 . 132096)




'(bind-keys global-keymap
  ;;window-keymap
  ;; if i set this:   it won't work anymore ....GRAB ??
  ;;"Button1-Click" 'raise-and-pass-through-click-if-focused
                                        ;"H-Button1-Click" 'raise-and-pass-through-click
                                        ;"Button1-Click" 'raise-window-and-pass-through-click
  ;;'raise-or-pass-through-click
  ;'raise-transient-and-pass-through-click
  
					;"H-Button1-Click" 'raise-and-pass-through-click
					;"Button1-Click" 'raise-window-and-pass-through-click
   "M-Button1-Click" 'raise-window)



;(unbind-keys global-keymap "Button1-Click")
;(unbind-keys (lookup-event "H-Down") window-keymap)
'(unbind-keys window-keymap
					;"H-Button1-click"
					;"M-Button2-click"
   "W-Down"
   "W-Up"
   "Button4-click"
   )


(message "mouse.jl loaded")
(format #t "binding: %s\n" (lookup-event-binding (lookup-event "M-Button1-Move")))

