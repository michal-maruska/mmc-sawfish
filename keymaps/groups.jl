



(bind-keys groups-keymap
  " " 'my-add-to-group
  "a" 'my-add-to-current-group
  "s" 'send-group-to-workspace

  )


;(bind-keys  hc-keymap "g" groups-keymap)


(bind-keys groups-keymap
  "i" 'move-group-up
  "k" 'move-group-down
  "j" 'move-group-left
  "l" 'move-group-right)

