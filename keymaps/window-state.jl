


(if (locate-file "window-info.jl"  load-path)
    (my-require 'window-info))

(require 'sawfish.wm.state.ignored)



(bind-keys my-change-window-status-keymap
  "i" 'iconify-window
  "I" 'iconify-group
  
  "s" 'toggle-window-shaded
  "u" 'raise-window-depth		;raise-single-window
  "l" 'lower-window-depth		;raise-single-window
  "?" 'show-window-props		;raise-single-window
  "a" 'show-window-props		;raise-single-window

  "t" 'toggle-window-sticky		;raise-single-window
  "." 'toggle-window-sticky		;raise-single-window

  "q" 'toggle-window-ignored

  "c" 'toggle-window-cycle-skip

  "b" 'bury-window
  "m" 'popup-window-menu

  "p" 'xprop

  ;; ignored ?
  )