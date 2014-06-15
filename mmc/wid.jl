;;; wid.jl -- simple window identifiers

;; original idea & original code:
;; Copyright (C) 2001 Nikita Danilov <NikitaDanilov.Yahoo.COM>

;; complete rewrite, and many enhancements:
;;  Copyright (C) 2002-5 Michal Maruska <mmc@maruska.dyndns.org>



;; INSTALLATION:
;; Put this file into load-path and add (require 'wid) to .sawfishrc
;; sawfish-1.4-mmc is needed!

;; How to use it:

;; TERMINOLOGY:
;;  `key-event'    is Keypress of a non-modifier key  + the current modifiers down
;;              that's the usual key-event in Emacs, something like  "C-M-y"

;;  `wid'  (window identifier)   is a key-event which identifies a set of windows.


;;  This module is about an (n->m) mapping of wids to windows.

;;  OPERATIONS with wids:
;;  `wid-assign-wid-to-window' promts for a wid, reads it,
;;  and puts the current window
;;  to the set of windows associated w/ the wid

;; `wid-goto-window'   prompts for a wid, and  actives the first window from the set associated w/ the wid

;; `wid-remove-wid-from-window'   prompts for a wid, and  removes the current window from the set associated w/ that wid.


;;  FAQ:
;;  Q:   How to cycle through the windows associated w/ a given wid?
;;  A: go to the wid, an implicit `search' is formed, and you can x-cycle through it.
;;     This `search' is formed by iswitch-window as well.


;; CHANGELOG


;;; mmc: todo
;; window & viewport
;; multi-key  wids.  xterm  host|user|app
;; reading & filtering by a wid should be a `plugin' for iswitch-window
;; * if the current window has the wid, go to a different window!
;; * keep the windows in a lru (heap) order.
;; on restart (of SF) reconstruct the hash from info at windows!   ... done

(define-structure mmc.wid
    (export
      wid-assign-wid-to-window
      wid-read-key-and-get-window
                                        ;wid-read-key-and-get-workspace
      get-wid->window
      get-wid->windows
                                        ;get-wid->workspace
      bind-wid-to-window

      ;; saving to files
      wid-restore
      wn-wid-restore
      wid-store

      ;; setting programmatically for the next new window
      wid-for-new-window
      )

    (open
     rep
     rep.system
     rep.io.files
     rep.mmsystem
     rep.data.tables
                                        ;rep.mmsystem not used here
     sawfish.wm                         ;, sawfish.wm.misc.
     sawfish.wm.windows

     sawfish.wm.misc                    ;call-with-keyboard-grabbed
     sawfish.wm.events
     sawfish.wm.commands
                                        ;sawfish.wm.custom
                                        ;sawfish.wm.util.window-order
     sawfish.wm.util.keymap
                                        ;sawfish.wm.workspace
                                        ;sawfish.wm.viewport
     sawfish.wm.util.display-window
     sawfish.wm.windows.subrs           ; the after-add-window-hook

     sawfish.wm.commands.groups         ; fixme: we should not do it here! start of new feature?
     rep.io.timers

     mmc.simple                         ;fixme:   read-and-run
     mmc.display
     mmc.window
     mmc.iswitch-window                 ; unfortunately  `current-search' is there
     rep.trace
     mmc.saving
     mmc.adt.list
     )

  (define wait #f)
  (define debug #f "used by rep.trace macros")
;; class  widable-object/hashable-object
;; methods:  suggest-wid, save



;; global, since we want to survive a reload
;; the value is a weak pointer to the window.
  (defvar wid->window-table (make-table string-hash equal-hash)
    "List of used wids.  The mapping")
;; (setq wid->window-table (make-table string-hash equal-hash))


  (define (weak->window item)
    "`item' is a weak pointer to a window. If all is ok, return the window."
    (let ((window (weak-ref item)))
      (and window
           (windowp window)
           (window-live? window)
           window)))

;;  We test:   a-> a A
;;             B-> B b
;;
  (define (items-under-wid table wid)   ;should be items-under-window-wid
    ;; invalid weak reference !!!
    ;; todo:  remove other modifiers....
    (or (table-ref table wid)
        (unless (string-upper-case-p wid)
          (table-ref table (string-upcase wid)))
        (unless (string-lower-case-p wid)
          (table-ref table (string-downcase wid)))))

;;; SETTER & GETTER:
  (define (get-wid->window wid)
    (let ((stack (items-under-wid wid->window-table wid))) ;
      (if stack
          ;; fixme:  i want  the first in order!!
          ;; and maybe not the current window.
          (find-first weak->window stack)))) ;first live

  (define (sort-windows-by-order windows)
    (sort windows (lambda (x y)
                    (setq x (window-get x 'order))
                    (setq y (window-get y 'order))
                    (cond ((and x y)
                           (> x y))
                          (x t)
                          (t nil)))))



  (define (get-wid->windows wid)
    ;; list of windows
    (let ((stack (items-under-wid wid->window-table wid)))
      (if stack
          (sort-windows-by-order
           (filter-morphing weak->window stack))
        '())))

;; setter:
  (define (bind-wid-to-window wid window)
    ;; if already there, put at the beginning ?
    (let ((current (table-ref wid->window-table wid)))
      (unless (consp current)
        (setq current '()))
      ;; if
      (setq current
	    (delete-if
		(lambda (item)
		  ;; or invalid ?
		  (equal
		   (weak->window item)
		   window))
	      current))
      (push! current (make-weak-ref window))
      (table-set wid->window-table wid current)
      (set-x-property window 'WM_WID wid 'STRING 8))) ;fixme: if it's a list of Wids ?

  (define (wid-remove window wid)       ; only the last!!
    (table-set wid->window-table wid
               (delete-if
                   (lambda (item)
                     ;; or invalid ?
                     (equal
                      (weak->window item)
                      window))
                 (table-ref wid->window-table wid))))


                                        ;(define wid-wid-property nil "Symbol used to store wids as window properties")

;;should be command exit !!!!
;; returns the NAME !
  (define (wid-read #!optional (prompt "wid: "))
    (let* ((event (read-event prompt))
           (ev (event-name event)))
      (DB "wid-read: %s\n" ev)
      (if (or (string= ev "C-g")
              (string= ev "H-g"))
          (progn
            (throw 'wid-abort #f))
        ev)))

;; this is a pure command, not needed otherwise ?
  (define (wid-read-key-and-get-window)
    "get an event/wid and skip to the wid-assigned window"
    (DB "wid-read-key-and-get-window +++++++++++++++++\n")
    (let ((event #f))
      (catch 'wid-abort
        (setq event (wid-read "window wid")))
      (if (not event)
          (throw 'command-canceled #f)

        ;; and-let !!!!
        (let* ((windows (get-wid->windows event))) ;(event-name
          (if (not (null windows))
              (let ((window (car windows)))
                (setq current-search windows)
                                        ;(display-information )

                (display-information
                 (format #f "%s"
                         (mapconcat window-name current-search "\n"))) ;windows
                (DB "%s\n" windows)
                                        ; (windowp ))
                (list window))
            (progn                      ;otherwise bug ?
              (display-message (format #f "(%s) window is gone!" event)) ; sawfish.wm, sawfish.wm.misc
              (throw 'command-canceled #f)))
          ;; throw
          ))))




;;;   persistence

;; fixme:    the display-name hm.  host:0   is the same as :0  if ....
  (define wid-file (concat (user-home-directory) "/.sawfish/wid.store." display-name))

  (define (wid-store)
    (let ((stream (make-string-output-stream)))
      (table-walk (lambda (key value)
                    (let ((windows (filter-morphing weak->window value)))
                      (format stream "(\"%s\" %s)\n" key (mapcar window-id windows)
                                        ;(window-name value)
                              )))
                  wid->window-table)
      (string>file wid-file (get-output-stream-string stream))
      (display-information "wid stored")))

  (define-command 'wid-store wid-store)
;;(define wid-timer (make-timer wid-store 100))

  (define (wid-restore)
    ;; get from the file:
    (read-and-run wid-file
      (lambda (binding)
        (message "wid-restore")
        (let ((wid (car binding))
              (windows (nth 1 binding)))
          (format #t "%s -> %s" wid windows)
          (if (table-ref wid->window-table wid) ; should test...
              (message "wid already assigned")
            (mapc
             (lambda (window)
               (message "wid-restore: window")
               (bind-wid-to-window wid (get-window-by-id window)))
             windows))))))

  (define (wn-wid-restore)
    (map-windows
     (lambda (w)
       (let ((prop (get-x-property w 'WM_WID)))
         (when prop
           (bind-wid-to-window (nth 2 prop) w))))))


  (define-command 'wid-restore wid-restore)



;;; #spec !!
  (define (wid-assign-wid-to-window window)
    (let ((prompt (format #f "wid to assign to %s" (window-name window))))
      ;; I will try it later:
      (let ((wid (wid-read prompt)))
        (bind-wid-to-window wid window))
      (wid-store)))                     ; should i make a hook ??
  (define-command 'wid-assign-wid-to-window wid-assign-wid-to-window #:spec "%W")


  (define-command  'wid-remove-wid-from-window
    (lambda (window)
      (let ((wid (wid-read (format #f "wid to remove from %s" (window-name window)))))
        (wid-remove window wid)))
    #:spec "%W")

                                        ; (run-hooks wid-change-hook)
                                        ; (defvar wid-change-hook "")
                                        ; (mm-add-hook 'wid-change-hook  wid-store)


;; [13 ott 03]
;; i want to:  display-window  AND  set as last search ....

  (define-command 'wid-goto-window
    (lambda ()
      (if wait (sleep-for 2 500))

      ;; i have to grab, b/c after we 1/ release the passive-key  we lose
      ;; and                          2/ wid-read cleans its grab too.
      (call-with-keyboard-grabbed       ;'(#f #f #t) ; hm ??
       (lambda ()
         (let* ((windows (wid-read-key-and-get-window))
                (window (car windows)))
                                        ;(display-message (format #f "new-wid-goto-window: " (window-name window)))
           (DB "new wid-goto-window: %s\n" (window-name window))
           ;; for testing  (provoking problems)
           (if wait (sleep-for 0 500))
                                        ;(uniconify-group window)
           (display-window  window))))))


;;; This is the hack to assign wids to winows before they're created.
;; todo: match on class ?

  (define wid-4-new-window #f)          ; holds the WID for the to-be-created window

  (define (wid-for-new-window wid)
    ;; called before running an external process, which will map/open a new window
    (setq wid-4-new-window wid))

  (define (add-wid-to-new-window window)
    (DB "add-wid-to-new-window\n")
    (if wid-4-new-window
        (bind-wid-to-window wid-4-new-window window))
    (setq wid-4-new-window #f))


;;; this only if you have mmsystem.jl
  (mm-add-hook 'after-add-window-hook add-wid-to-new-window #f 'add-wid)

;; [05 nov 04] i don't need it now!
                                        ;(add-hook-s 'before-exit-hook wid-store)
  (add-hook-s 'after-initialization-hook wn-wid-restore)
  )



;(set-x-property (input-focus) 'WM_WID (event-name wid) 'STRING 8)
;(get-x-property (input-focus) 'WM_WID)




;; iconify removes the window-order !!
