
(require 'sawfish.wm.commands.x-cycle)
(require 'mmc.cycle)


;; everything here: must be even in the cycle-keymap
(bind-keys global-keymap
  "H-C-p" 'cycle-group
  "H-Button4-click" 'cycle-windows
  "H-Button5-click" 'cycle-windows-backwards
  "H-Return" 'cycle-windows

  "H-C-M" 'cycle-windows

  "H-C-h" 'cycle-windows-backwards
                                        ; "H-C-n" 'cycle-windows
  "H-C-g" 'cycle-class
  "H-C-b" 'cycle-class-backwards
  ;;"H-C-N" 'cycle-windows-backwards


  "H-C-n" 'global-cycle-windows
  "H-C-m" 'cycle-windows
  "H-C-o" 'cycle-modulo-ws
  "H-C--" 'cycle-search-start
  ;;-start
  )

                                        ; "H-C-." 'global-cycle-windows

;;; once entered:

(bind-keys cycle-keymap
  "H-C-n" 'cycle-windows
  "H-C-m" 'cycle-windows
                                        ;(unbind-keys cycle-keymap "H-j") 'cycle-group
  "H-C-j" 'cycle-group
  
  "H-h" 'cycle-windows-backwards
  "H-n" 'cycle-windows
  "H-C-." 'cycle-windows

  "H- " 'cycle-set-global               ;i ignore that !!

  "H-g" 'cycle-class
  "H-b" 'cycle-class-backwards

  "H-o" 'cycle-modulo-ws

  ;; ???
  ;"H-u" 'cycle-next-ws
                                        ;  "H-i" 'cycle-next-ws-backwards

  "H-C--" 'cycle-search

  "H-Button4-click" 'cycle-windows
  "H-Button5-click" 'cycle-windows-backwards
  )



