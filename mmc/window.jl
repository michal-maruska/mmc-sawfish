
(define-structure mmc.window
    (export
      send-string-to-window
      window-live?
      
      get-window-by-class-re
      window-put-many
      xprop

      window=
      window-leader
      ;;  themes
      set-theme
      prompt-for-theme
      )
    (open
     rep
     rep.system
     rep.mmsystem
     rep.regexp
     sawfish.wm.util.prompt
     sawfish.wm.events                  ;send-
     sawfish.wm.commands
     sawfish.wm.windows
     sawfish.wm.state.maximize
                                        ;sawfish.wm.misc
     sawfish.wm                         ;x-kill-client

     sawfish.wm.frames
     mmc.display
     mmc.simple
     mmc.xterm
     )

  (define (send-string-to-window s w)
    (let ((i 0))
      (while (< i (length s))
        (let* ((ch (substring s i (setq i (1+ i))))
               (e (cond ((equal ch "\n") "RET")
                        (t ch))))
          (synthesize-event e w)))))

  (define (window-live? win)
    (and (windowp win)
         (window-id win)))


  ;; mmc: why do i need the scripts?  b/c i put the output to pager, 
  (define-command 'xprop
    (lambda (w)
      ;; sawfish-exec-directory
      (my-xterm #:program (format #f "%s/my-xprop %d -len 80" sawfish-exec-directory (window-id (input-focus)))))
    #:spec "%W")


  (define-command 'xwininfo
    (lambda (w)
      ;; sawfish-exec-directory
      (my-xterm #:program (format #f "%s/my-xwininfo %d -all" sawfish-exec-directory (window-id (input-focus)))))
    #:spec "%W")



(define-command 'xprop-root
    (lambda ()
      ;; sawfish-exec-directory
      (my-xterm #:program (format #f "%s/my-xprop %d -len 80" sawfish-exec-directory (root-window-id)))))




  (define-command 'xev
    (lambda (w)
      (my-xterm #:program (format #f "xev -id %d" (window-id w))
                #:title  (format #f "xev -id %s" ;fixme! quote
                                 (window-name w))))
    #:spec "%W")

  (define-command 'kill-client-warning
    ;; ask for confirmation
    (lambda (window)
      (if (string= "y" (my-read-event (format #f "really kill %s? " (window-name window))))
          (x-kill-client window)))
    #:spec "%W")


  (define-command 'window-name
    (lambda (window)
      (display-message (window-name window)))
    #:spec "%W")

  (define-command 'window-class
    (lambda (window)
      (display-message (window-class window)))
    #:spec "%W")



;; fixme: bad !!
;;   (define (get-window-by-class-re re)
;;     "Get a window by matching against its class"
;;     (let ((windows (window-order))
;;           w done match)
;;       (while (and windows (not done))
;;         (setq w (car windows))
;;         (setq windows (cdr windows))
;;         (when (string-match re (window-class w))
;;           (setq done t)
;;           (setq match w)))
;;       (when match match)))


                                        ; 2004-01-06
  (define (get-window-by-class-re re)
    "Get a window by matching against its class"
    (catch 'found
      (map-windows
       (lambda (w)
         (if (string-match re (window-class w))
             (throw 'found w))))
      #f))


;; Two functions for ~/.sawmillrc
;; The first will remove a window's frame
;;  and maximize it.
;; The second will unmaximize the window
;;  and reframe it.
;; Be sure to bind the second to a key
;;  since the theme's buttons will not
;;  be available after the first.

  (defun unframe-maximize (w)
    "Remove frame and maximize."
    (interactive "%W")
    ;(set-frame:unframed w)
    (maximize-window w))


  (defun unmaximize-frame (w)
    "Unmaximize and reframe."
    (interactive "%W")
    (unmaximize-window w)
    ;(set-frame:default w) ;; ??
    )


  (define (rename-window w)
    "Force the current window to have a unique title."
    (let ((new-name (prompt-for-string "new title:" (window-name w)))) ; (prompt-for-string "new title:" "ahoj")
      (set-x-text-property
       w 'WM_NAME
       (vector new-name))))

  (define-command 'rename-window rename-window #:spec "%W")


                                        ; (defun rename-window (w)
                                        ;   "Force the current window to have a unique title."
                                        ;   (interactive "%f")
                                        ;   (setq new-name (prompt-for-string "new title:" (window-name w)))
                                        ;   (set-x-text-property
                                        ;    w 'WM_NAME
                                        ;    (vector new-name)))


  (mm-add-hook 'window-depth-change-hook
    (lambda (w changes)
      (declare (unused changes))
      (display-information (format #f "depth: %d %s"
                                   (window-get w 'depth)
                                   (window-name w)))))


                                        ;(setq window-depth-change-hook '())


  (define-command 'window-lock-vertically
    (lambda (w)
      (window-put w 'window-locked-vertically 't))
    #:spec "%W")


  (define-command 'window-lock-horizontally
    (lambda (w)
      (window-put w 'window-locked-horizontally 't))
    #:spec "%W")



;;  ((key . value) ...)
  (define (window-put-many window properties)
    ;; someone on IRC wanted ...
    (unless (null properties)
      (window-put window
                  (car properties)
                  (nth 1 properties))
      (window-put-many window (cddr properties))))

  (when  #f
    (window-get (input-focus) 'a)
    (window-put-many (input-focus) '(a 1 b 2)))


  (define (window= win-1 win-2)
    (eq win-1 win-2))

  (define (window-leader win)
    (let ((leader-info  (get-x-property win 'WM_CLIENT_LEADER)))
      (when leader-info
        (get-window-by-id (aref (nth 2 leader-info) 0)))))


  (define (window-with-proper-leader? win)
                                        ;(format #t "window-with-proper-leader?: %s" (window-name win))
    (let ((leader (window-leader win)))
      (and (windowp leader)
           (not (window= win leader)))))



;; mmc: i need a macro to create such toggle commands !
;;  focus the newly-mapped windows?
  (define (toggle-focus-new)
                                        ;(interactive)
    (setq focus-windows-when-mapped
          (not focus-windows-when-mapped)))
  (define-command 'toggle-focus-new toggle-focus-new)



  (define (set-theme theme)
    ;; i shouls use (apply-frame-style 'microGUI)
    (let ((old-theme default-frame-style)
          )
      (unless (eq theme old-theme) 
        (setq default-frame-style theme)
        ;; fixme: w/ the currently 
                                        ;(reframe-all-windows)
        (reframe-windows-with-style old-theme))))

  (define (prompt-for-theme)
    (find-symbol 
     (prompt-from-list (mapcar symbol-name (find-all-frame-styles))
                       "theme: ")))

  (define-command 'set-theme set-theme #:spec '(list (prompt-for-theme)))
  )
; (require 'mmc.window)
