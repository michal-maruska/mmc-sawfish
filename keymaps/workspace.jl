(require 'mmc.workspace)



(bind-keys my-workspace-map
  ;"n" 'next-workspace
  "p" 'reparent-windows-in-workspace
  "n" 'new-workspace


  "g" 'activate-workspace
                                        ;"w" 'activate-workspace

  "c" 'create-workspace

  "w" 'popup-window-list
;  "s" 'popup-workspace-list
  "s" 'ww-mapping-store

  "j" 'previous-workspace
  "l" 'next-workspace
  "." 'display-ws-name

                                        ; new
  "a" 'wid-goto-workspace
  "m" 'wid-assign-wid-to-workspace

  "r" 'rename-ws
                                        ; old
  "M-;" 'wid-assign-wid-to-workspace
  "H-A-i" 'wid-remove-wid-from-window
  "H-M-;" 'wid-assign-wid-to-workspace
  ";" 'wid-goto-workspace
  "H-;" 'wid-goto-workspace


  "e"  'display-ws-name
  )
