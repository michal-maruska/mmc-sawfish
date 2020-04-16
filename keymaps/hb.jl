(my-require 'mmc.my-move)


(bind-keys my-resize-map
  "j" 'resize-medium
  "k" 'resize-block
  "l" 'resize-half
  ";" 'resize-a4
  "r" 'my-resize-window)
