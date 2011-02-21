
;;;  Problems:

;; WS are:
;;    records
;;    numbers
;;    logical numbers
;; extern:  name number.

;; Names are stored:
;; in X atoms
;; in the records
;; in a list `workspace-names'
;;
;;

(define-structure mmc.workspace
    (export
      reparent-windows-in-workspace
      new-workspace
      rename-ws
      
      ww-mapping-restore
      ww-mapping-store
      ws-restore
      ws-store
      )
    (open
     rep
     rep.system
     rep.mmsystem
     rep.io.files

     rep.io.timers
     sawfish.wm.misc
     rep.data.tables
     sawfish.wm.commands
     sawfish.wm.workspace
     sawfish.wm.viewport
     sawfish.wm.windows.subrs
     mmc.display
     sawfish.wm.util.prompt
     mmc.simple
     mmc.saving
     )

;;;  Reparent
  ;; fixme:  this works for the current WS only?
  (define (reparent-windows-in-workspace workspace); WORKSPACE is a number
    "Shift all windows, which belong in WORKSPACE, but are outside visible area, to the current view."
    (mapc
     (lambda (item)
       (when (window-outside-workspace-p item)
                                        ;(message (format #f "%s outside" (window-name item)))
         (move-window-to-current-viewport item)))
     (workspace-windows workspace)))

  (define-command 'reparent-windows-in-workspace reparent-windows-in-workspace
                  #:spec (lambda ()
                           (list current-workspace)))


;;; `new'
  (define (get-new-ws)
    (let ((set (sort (all-workspaces))))
      (not-in-numbers set)))

  (define (new-workspace name)
    "create a new workspace, and assign the NAME"
    (let ((ws (get-new-ws)))
      ;; create it:
      (select-workspace ws)
      (rename-ws ws name)))

  (define-command 'new-workspace new-workspace
                  #:spec (lambda ()
                           (list (prompt-for-workspace-name "name for the new WS: "))))


;; display an informative message about the `current-workspace'
  (define (display-ws-name)
    (let* ((number (format #f "%d" current-workspace))
           (logical (workspace-id-to-logical current-workspace))
           (name (or (nth logical workspace-names)
                     number))
           (x (car (screen-viewport)))
           (y (cdr (screen-viewport))))
      (display-information
       (format #f "%d/%d -> %s  %s" current-workspace logical name (screen-viewport))
       `((background . "red")
         (foreground . "white")
         (position . ;; my hack to show where is the center of the WS
                   ,(cons (if (= x 0)
                              (- (screen-width) 300) ; lenght of the text
                            0)
                          (if (= y 0)
                              (- (screen-height) 50) ; height of the text
                            0)))))))

  (define-command 'display-ws-name display-ws-name)
;;  the hook is globa ??
  (mm-add-hook 'enter-workspace-hook display-ws-name nil 'display-ws-name)
  (mm-add-hook 'viewport-moved-hook display-ws-name nil 'display-ws-name)
;; enter-workspace-hook


;;; Rename
  (define (rename-ws ws name)           ;  list 
    ;; (re)-name the current workspace
    (let ((number (workspace-id-to-logical ws))
          (already-assigned (length workspace-names)))
      ;; sometimes we have to add the inter   <last>  ... <current>
      (if (<= already-assigned number)
          (let ((complement (make-list (+ 1 (- number already-assigned)) nil)) ; the differenct
                )
            (setq workspace-names (nconc workspace-names complement))))
      ;; now set the
      (set-nth! workspace-names number name)
                                        ;(table-set workspace-name-hash number name)
      ;; update-workspace-hints
      (call-hook 'workspace-state-change-hook)
      (ws-store)
      (display-information (format #f "ws names: %s" workspace-names))))

  (define-command 'rename-ws  rename-ws
                  #:spec (lambda ()
                           (let ((name (workspace-name current-workspace))
                                 )
                             (list current-workspace
                                   (prompt-for-workspace-name "rename WS: "  #:default name
                                                              #:start name)))))


;; save window->WS mapping
;; `incomplete' 
  
  (define sawfish-custom-directory (compose-path (user-home-directory) ".sawfish"))
  (define ws-name-file (compose-path sawfish-custom-directory "wn.store"))
  (define win-ws-file (compose-path sawfish-custom-directory "ww.store"))


  (define (ws-store)
    ;; save the  WS # -> name mapping
    (let ((stream (make-string-output-stream)))
      (let ((wss (workspace-limits)))    ; receive ??
        (map-numbers (car wss) (cdr wss)
                     (lambda (n)
                       (format stream "(%d \"%s\")\n"  n (workspace-name n))))
        (string>file ws-name-file (get-output-stream-string stream))
        (display-information "ws->name stored")
        ;;(set-timer wid-timer)
        )))


  (define (ws-restore)
    ;;restore the NAMES of WSs
    (read-and-run ws-name-file
      (lambda (binding)
        (let ((ws-id (car binding))
              (ws-name (nth 1 binding)))
          (rename-ws ws-id ws-name)))))

;; 
;; (map-numbers 0 (length original-x-ws-names) (lambda (i) (rename-ws i (aref original-x-ws-names i))))
;; original-x-state
;; original-x-viewports

  (define-command 'ws-restore ws-restore)



  (define (ww-mapping-store)
    ;; window -> workspace
    (let ((stream (make-string-output-stream)))
      (map-windows
       (lambda (win)
         (format stream "(%S %d %s)\n"
                 (window-name win)
                 (window-id win)
                 (window-workspaces win))))
      (string>file win-ws-file (get-output-stream-string stream))
      (display-information "win -> ws stored")))

  (define-command 'ww-store ww-mapping-store)

  (define (ww-mapping-restore)
    (read-and-run win-ws-file
      (lambda (binding)
        (let ((w-name (nth 0 binding))
              (w-id (nth 1 binding))
              (wss (nth 2 binding)))
          (let ((window (get-window-by-id w-id)))
                                        ;(send-window-to-workspace-from-first
            (move-window-to-workspace window current-workspace (car wss))
                                        ;(display-information "win -> ws stored")
            (message (format #f "%s (%d): %s\n" w-name w-id wss))
            )))))

  (define ws-store-timer (make-timer (lambda ()
                                       (ws-store))
                                     30))
  

;; i don't want it!
;;(add-hook-s 'idle-hook ww-mapping-store)

  '(mm-add-hook 'idle-hook
    (lambda ()
      (set-timer ws-store-timer 30))
    #f
    'ws-store)

  (define-command 'ww-mapping-store ww-mapping-store)


;[05 nov 04]  i don't want it !
  ;(add-hook-s 'before-exit-hook ww-mapping-store)
  ;(add-hook-s 'before-exit-hook ws-store)

  ;(add-hook-s 'after-initialization-hook ww-mapping-restore)
  ;(add-hook-s 'after-initialization-hook ws-restore)
  )
