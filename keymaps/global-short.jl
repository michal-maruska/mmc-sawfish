(require 'mmc.simple)



;;; The most-frequently used commands are placed directly in the globa keymap.
(bind-keys global-keymap
  "H-F1" 'select-workspace:1
  "H-F2" 'select-workspace:2
  "H-F3" 'select-workspace:3
  "H-F4" 'select-workspace:4
  "H-F5" 'select-workspace:5
  "H-F6" 'select-workspace:6
  "H-F7" 'select-workspace:7
  "H-F8" 'select-workspace:8
  "H-F9" 'select-workspace:9
  "H-F10" 'select-workspace:10
  "H-F11" 'select-workspace:11
  "H-F12" 'select-workspace:12
  )


(bind-keys global-keymap
  "XF86AudioMute" (lambda ()
                    (system "/home/michal/bin/speakers t")))


(bind-keys global-keymap

  ;; "H-7" 'resize-medium
  "H-8" 'resize-block
  "H-9" 'resize-half
  "H-6" 'resize-a4

  "H-4" 'move-1
  "H-5" 'move-2
  "H-6" 'move-3
  "H-7" 'move-4
                                        ; "H-b" 'center-mouse
                                        ; "H-o" 'spager-toggle
  "H-q" 'quote-event


  "H-e" 'emacs-open
  "H-BS"
  (lambda ()
    (let ((comment (prompt-for-string "tell me:")))
      (format (stderr-file) "------------------%s-----------\n" comment)))


  "H-t" 'my-xterm
  "H-T" 'my-small-xterm
  "H-C-t" 'rsh-to
  "H-C-r" 'su-to

  "H-d"  'send-to-workspace
  "H-C-d"  'move-to-workspace

                                        ;"XF86AudioMute" 'toggle-mute
  "XF86Mail" 'dump-stacking-list
  "XF86AudioLowerVolume" 'mixer-uniconify


  "Mod3-H-n" 'maximize-window-horizontally-toggle
  "Mod3-H-h" 'maximize-fill-window-vertically-toggle
  ;; 'volume-down
  "H-<" 'volume-up
  "H-=" 'ring
                                        ;           "H-u" 'undo
  "H-0" 'delete-window
  "Mod3-H-M-w"  'my-next-window-interactive
  ;; "H-C-l"  'my-next-window
  "Mod3-H-i"  'my-prev-window
  "H-Tab"    'exchange-windows
  "H-C-9"    'exchange-windows          ; 'my-next-window;

                                        ; "H-C-n"
  "H-C-;" 'exchange-windows
                                        ;"H-C--" 'exchange-windows
                                        ;"H-C--" 'cycle-search
  "H-g"  'my-clean
  "H-2"  'maximize-fill-window-vertically-toggle
  "H-1"  'maximize-window-horizontally-toggle
  "H-x" 'call-command-with-output-to-screen
  "H-C- " 'display-backtrace)


; some users use arrows !
(bind-keys global-keymap
  "s-h-Up" 'slide-window-up
  "s-h-Down" 'slide-window-down
  "s-h-Left" 'slide-window-left
  "s-h-Right" 'slide-window-right
  )


(bind-keys global-keymap
  "H-F11"
  '(call-process nil nil
                 ;;"gnome-screensaver-command" "-l"
                 "xlock"))
