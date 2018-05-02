;; iswitch-window.jl  (mmc's version) v1.5 -- incremental search for windows



;; Copyright (C) 2000 Topi Paavola <tjp@iki.fi>
;; Modifications and enhancements by Jens-Ulrik Petersen
;; <jens-ulrik.petersen@nokia.com>


;; Copyright (C) 2003-2005  Michal Maruska   <mmc@maruska.dyndns.org>
;; http://maruska.dyndns.org/comp/activity/darcs/sawfish/lisp/mmc/iswitch-window.jl

;; This file is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.


;;; mmc: NEW FEATURES [14 giu 05]

;; - current-search   after i make an isearch, the list of matching window is rememebered, and can by x-cycled. (command `cycle-search-start')
;; - display          integrated w/ x-message: since 13/6/2005  W/O flickering!!  (when you cycle the window list)
;; - [18 dic 04]   ADT to contain the restrictions,  it's a (a)list
;;     then i can make some specific calls (with partial restriction)..
;;     iswitch-window-on-viewport  for example  .. [18 dic 04] in fact i can.
;;
;;  call-for-next-key-events*


;; [11 gen 06]  serializing the query: as a list of nested conditions.





;;; Commentary:

;; Incremental window search, similar to iswitchb.el in emacs.
;;
;; Default keys (change in iswitch-get-window; ideally we should have an
;; iswitch-keymap):
;;
;; C-s,A-s,TAB    find next matching window
;; C-r,A-r,M-TAB  find previous matching window
;; C-g,ESC        quit iswitch
;; C-u            clear input buffer
;; backspace      delete previous character
;; C-z,A-z        iconify window
;; C-h,A-h        shade window
;; RET            select window
;;
;; Other keys insert themselves. A-s (or H-s, depending on your
;; modifiers) would be a good key to bind iswitch-window to; for example,
;;
;;   (bind-keys global-keymap "A-s" 'iswitch-window)
;;
;; The iswitch-window-with function also does something to the current
;; window. For example,
;;
;;   (bind-keys global-keymap "A-s" '(iswitch-window-with
;;                                    (lambda (w) (iconify-window w))))
;;
;; would iconify the currently focused window and focus the newly
;; selected window.
;;
;; This file is available at
;;   http://aton.co.jyu.fi/~tjp/sawfish/iswitch-window.jl
;; and can also be found in the sawfish software map:
;;   http://adraken.themes.org/map.php
;;
;; 1.3:
;; * Updated URL.
;; * Added iswitch-show-window-class variable.
;; * Fixed problem with undefined classes, thanks to Matt Tucker.
;; 1.2:
;; * Added patches, A-z, A-h, reverse cycling (A-r) and
;;   iswitch-window-with from Jens.
;; * TAB and M-TAB now do the same as A-s and A-r.
;;


(define-structure mmc.iswitch-window
    (export
      iswitch-window
      iswitch-get-window
      iswitch-window-line
      ;;
      replay-criterions)
    (open
     rep
     rep.regexp
     rep.system                         ;beep !
     ;rep.mmsystem ;; not used here

     ;;[17 dic 04]
     rep.data.records

     rep.trace

     rep.io.timers
     sawfish.wm.windows
     sawfish.wm.misc                    ;grab!
     sawfish.wm.events
     sawfish.wm.commands
     sawfish.wm.custom
     sawfish.wm.util.window-order
     sawfish.wm.workspace
     sawfish.wm.viewport
     sawfish.wm.util.display-window
     sawfish.wm.state.iconify
     sawfish.wm.state.shading

     mmc.x-message                      ; i want colored lines!
     mmc.my-apps
     mmc.adt.list
     mmc.simple
                                        ;sawfish.wm.commands.x-cycle
     mmc.key-continue
     mmc.browser
     )

  (define debug #t)

  ;; no polymophism!

  ;; types:
  ;;   substring
  ;;    workspace
  ;;    state
  ;;    viewport
  ;;   host
  ;;   user
  ;;   application   ; win-type  role ?
  ;;   ?
  ;; `unused'!!!
  (define-record-type :iswitch-criterion
    (make-criterion) criterion?
    (type type-of set-type!)
    (model model-of model-y!))

;; so i could use a 2-list  ( (type model) .....) !
  (defvar current-criterion '()
    "keep the structured contstraints of the last iswitch.")

;;; my fix-search  hack  .. todo: replay the current-criterion to avoid killed windows
  (defvar current-search nil
    "a list of windows, last selected w/ some selecting tool: iswitch-window, wid ..., used by x-cycle")


;; customize

  (defvar iswitch-show-window-class nil
    "Display WM_CLASS of windows in the iswitch menu.")

  ;;(setq iswitch-show-window-class #t)



;;; Display

;; Use the following to customize the look of the menu.

  (defvar iswitch-font default-font
    "Font for iswitch-window popup")

  (defvar iswitch-background-color "white"
    "Background color for iswitch-window popup")

  (defvar iswitch-foreground-color "black"
    "Foreground color for iswitch-window popup")


  (define iswitch-visibility-alist
    (if #f
        '((unobscured . "+")
          (partially-obscured . "%")
          (fully-obscured . "@"))

      '((unobscured . "+")
        (partially-obscured . "po")
        (fully-obscured . "fo"))
      ))

  (define iswitch-viewport-direction-alist
    '(((1 . 0) . ">")
      ((-1 . 0) . "<")
      ((0 . 1) . "v")
      ((0 . -1) . "^")
      ((1 . 1) . ".")
      ((-1 . 1) . ",")
      ((-1 . -1) . "`")
      ((1 . -1) . "'")))

;; the SGN function  -1 0 1
  (define (sign num)
    (cond ((> num 0)
           1)
          ((zerop num)
           0)
          ((< num 0)
           -1)))

  (define (iswitch-viewport-direction wv cv)
    (let ((wvx (car wv))
          (wvy (cdr wv))
          (cvx (car cv))
          (cvy (cdr cv)))
      (cdr (assoc (cons (sign (- wvx cvx)) (sign (- wvy cvy)))
                  iswitch-viewport-direction-alist))))



  (define (pad-to string needed-len)
    (let ((len (length string)))
      (cond
       ((= len needed-len) string)
       ((< len needed-len)
        (concat string (make-string (- needed-len len) " ")))
       (#t
        (substring string 0 needed-len)))))

                                        ;(pad-to "michal" 13)
                                        ;(make-string 2 " ")

;; ???
  (define (iswitch-window-line w)
    (concat
     (pad-to
      (cond ((window-get w 'iconified)
             "i")
            ((window-get w 'sticky)
             "=")
            ((not (window-in-workspace-p w current-workspace))
             "X")
            ((window-outside-viewport-p w)
             (iswitch-viewport-direction (window-viewport w) (screen-viewport)))
            ((window-get w 'shaded)
             "s")
            ((cdr (assoc (window-visibility w)
                         iswitch-visibility-alist))))
      3)

     (if iswitch-show-window-class
         (let ((class-name (get-x-text-property w 'WM_CLASS)))
           (if class-name
               (pad-to                  ;fixme:  make it a minimum but w/o maximum !!!
                (concat "  <"
                        (aref class-name 1)
                        ">")
                12))))

     (window-name w)))


  (define (dispatch-condition-format condition)
    ;; condition is a list
    (let ((type (condition-type condition)))
      (symbol-name type)))


   (define iswitch-display-window #f  "x-message ")


;; format user input and window list for display-message
  (define (iswitch-display criterions input wlist)
    ;(DB "iswitch-display: we have already a window: %s\n" (if iswitch-display-window "yes" "no"))
    ;(DB "%s->%s\n" criterions (mapconcat dispatch-condition-format criterions " : "))

    ;; [12 giu 05]
    ;; (if iswitch-display-window (x-message-hide iswitch-display-window))

    (setq iswitch-display-window
          (apply
           x-message-display
           (append ;nconc
            (list
             '(border-color . "red")
             '(border-width . 5)
             '(foreground . "yellow")
             (mapconcat dispatch-condition-format criterions " : ")
             '(foreground . "red")
             (concat "  " input)
             '(foreground . "green")
             (format #f "total: %d" (length wlist))
             '(foreground . "gray")
             ;(mapconcat dispatch-condition-format criterions " : ")
             )
            (mapcar iswitch-window-line wlist))

           '((background . "black")
             (foreground . "gray"))
           (if iswitch-display-window
               `(#:mwindow ,iswitch-display-window)
             '()))))


;;; Tab cycling:
 ;; find next window matching input string
  (define (iswitch-rotate-to-next-match input wlist #!optional previous) ; fixme
    (setq wlist
          (rotate-list-from!
           (catch 'iswitch-found
             (mapc (lambda (w)
                     (when (string-match input (window-name w) 0 t)
                       (throw 'iswitch-found w)))
                   (if previous
                       (reverse (cdr wlist))
                     (cdr wlist))))
           wlist)))

;;; filtering:

  (define (iswitch-update-match string wlist)
    "return the WLIST limited to windows w/ name which matches the INPUT"
    ;;(message (format #f "match: 1: %s" (car input)))
    (filter (lambda (w)
              (let ((name (window-name w)))
                (string-match string name 0 'ignore-case)))
            wlist))

  (define (iswitch-update-by-name names wlist)
    (filter
     (lambda (w)
       (string-match-string-list-p names (window-name w)))
     wlist))

                                        ; we need functions !!

  (define (iswitch-update-match-class input wlist)
    "return the WLIST limited to windows whose class (name) matches the input"
    ;;(message (format #f "match: 1: %s" (car input)))
    (filter (lambda (w)
              (let ((class (window-class w)))
                (string-match-string-list-p input class)))
            wlist))

  (define (iswitch-update-workspace wlist workspace)
    "limit WLIST to those (windows) which are/are NOT on the current ws."
    (DB "iswitch-update-workspace: %s\n" workspace)
    (let ((condition
           (if (consp workspace) ;; (- . 1)
               (lambda (w)
                 (not (window-in-workspace-p w (cdr workspace))))

             (lambda (w)
               (window-in-workspace-p w workspace)))))
    (filter (lambda (w)
              (and
               (condition w)
               (not (window-iconified-p w))))
            wlist)))



  (define (iswitch-update-class wlist types)
    "the class of window must be one of TYPES (a list of strings)"
    (filter (lambda (w)
                                        ;;(string= type (window-class w)))
              (member  (window-class w) types))
            wlist))


  (define (iswitch-constraint-by wlist predicate)
    (filter predicate
            wlist))


  (define (iswitch-update-viewport wlist info) ;fixme: could it be a boolean value? and i want out of this viewport ??
    (declare (unused info))
    "limit WLIST to those (windows) which are on the current ws & vieport.   sorry, we need to test ws too."
    (let ((workspace current-workspace))
      (filter (lambda (w)
                (and
                 (not (window-iconified-p w))
                 (not (window-outside-viewport-p w))
                 (window-in-workspace-p w workspace)))
              wlist)))


  (define (x-property= window prop-name model)
    "is the PROP-NAME X property on WINDOW a string MODEL?"
    (let ((prop (get-x-text-property window prop-name)))
      (and
       prop
       (string= (aref prop 0) model))))

  (define (windows-on-host wlist hostname)
    "use standard & SF specific criterions to find windows `running' on the host HOSTNAME"
    (filter ;;-windows
     (lambda (window)
       (or
        (x-property= window 'WM_CLIENT_MACHINE hostname)
        (x-property= window 'sf_host hostname)))
     wlist))

  (define (condition-type condition)
    (car condition))

   ;;
  (define (dispatch-condition wlist condition)
    "interpret the (car CONDITION), and dispatch/apply the right function w/ the the (cdr codition)  on WLIST. Return the result."
    ;; condition is a list
    (let ((type (condition-type condition)))
      (case type
        ((name)
         (iswitch-update-by-name (cdr condition) wlist) ;fixme! order
         )
        ((class)                        ;classes !!
         (iswitch-update-class wlist (cdr condition)))
        ((host)
         (windows-on-host wlist (cadr condition)))

        ((user)
         4)
        ((application)                  ;
         5)

        ((workspace)
         (iswitch-update-workspace wlist (cadr condition))) ;fixme!

        ((viewport)
         (iswitch-update-viewport wlist (cadr condition))
         )
        ((predicate)
         ;; fixme: name!
         (iswitch-constraint-by wlist (cadr condition)))
        )))

                                        ;(dispatch-condition (managed-windows) (list 'class "Emacs"))
                                        ;(dispatch-condition (managed-windows) (list 'workspace 0))


  (define (iswitch-add-condition wlist condition)
    (setq current-criterion (cons condition current-criterion))
    (dispatch-condition wlist condition))

  (define (replay-criterions criterion-list #!optional wlist) ;todo: take an optional wlist argument
    "apply the CRITERION-LIST to WLIST (by default `window-order'). See `dispatch-condition' for the list of supported criterions."
    (unless wlist
      (setq wlist (window-order nil t t))) ;; (managed-windows)
    (mapc
     (lambda (condition)
       (setq wlist (dispatch-condition wlist condition)))
     criterion-list)
    wlist)



  (defmacro iswitch-add-condition! (wlist condition)
    "VARIABLE codition"
    `(setq ,wlist
           (iswitch-add-condition ,wlist ,condition)))


;;; Main
  (define (iswitch-get-windows #!optional criterions)
    "Let user pick a window with incremental search and return that window."
    (unless criterions
      (setq criterions '()))
    (call-with-keyboard-grabbed
     (lambda ()
       (let ((display-timer #f))
         ;; mmc:  this is when i want to press more keys at once, skipping the initial  all-windows display
         ;; fixme: make it a fluid!
         (setq current-criterion criterions)
         (unwind-protect
             (let* ((input "")          ;  current string to be matched
                    ;(constraints ())    ;  other (non textual) constraints  (workspace, viewport, state, ...)
                    (init-wlist
                     (replay-criterions current-criterion))
                    (focused-window (car init-wlist))
                    (use-timer #f)

                    wlist               ; matching windows ?
                    (display-function
                     (lambda ()
                       (when (< (length wlist) 2)
                         ;; bug: this will raise the window too! But C code wil
                         ;; then focus & raise (possibly) another window!
                         (display-window (car wlist))) ;-without-focusing
                       (iswitch-display current-criterion input wlist))))
               ;; put the current at the end:
                  (setq init-wlist (append (cdr init-wlist) (list focused-window))
                        wlist init-wlist)

;;; how we make a recursive event loop:

               ;; we tell the C core, that the keymap is void.
               ;; then we get all the keys via `unbound-key-hook'
               ;; and can invoke ourselves the functions.

               ;; we control  allow-events, ungrab-keyboard through  grab-counter
               ;; make a copy.
               (catch 'exit-iswitch
                 (call-for-next-key-events
                  (lambda ()
                    (if use-timer
                        (if display-timer
                            (set-timer display-timer)
                          (setq  display-timer (make-timer display-function 0 100))) ;we should see other keys first !!
                      (display-function)) ;initial list
                    (setq use-timer #t)) ; hm??

                  (lambda (event-info)
                    (let ((key (car event-info))
                          (event-string (cdr event-info)))
                ;;; the big `cond':
                      (cond ((or (equal key "A-g")
                                 (equal key "C-g")
                                 (equal key "ESC")) ;fixme: we just lost  the `current-criterion'
                             ;; Exit
                             (throw 'exit-iswitch nil))

                            ((or (equal key "C-u")
                                 (equal key "A-u"))
                             ;; Reset
                             (setq input ""
                                   ;;  ???
                                   wlist (replay-criterions current-criterion)))
                            ;;(iswitch-update-match (cons input constraints) init-wlist)))

                            ((or (equal key "BS")
                                 (equal key "C-h"))
                             (if (> (length input) 0)
                                 (progn
                                   (setq input (substring input 0 (1- (length input))))
                                   (setq wlist (replay-criterions current-criterion))
                                   (iswitch-update-match input init-wlist))
                               (progn
                                 (setq current-criterion (safe-cdr current-criterion))
                                 (setq wlist (replay-criterions current-criterion)) ;init-wlist is recomputed! that's good.
                                 )))

                            ;; should be a common ...
                                        ; (setq wlist (iswitch-update-match (cons input constraints) init-wlist)))
                            ((equal key "M-e")
                             (iswitch-add-condition! wlist '(class "Emacs")))


                            ((equal key "M-s")
                             (iswitch-add-condition! wlist '(class "Skype")))



                            ;; do i want alist ??
                            ;; should be a common ...
                            ((or (equal key "C-w") ; limit to the current workspace:
                                 (equal key "H-w"))
                             ;; should be a common ...
                             (iswitch-add-condition! wlist (list 'workspace current-workspace)))

                            ((equal key "M-f")
                                        ;(setq wlist (iswitch-update-class wlist '("Emacs")))
                             (setq wlist
                                   (iswitch-add-condition
                                    (iswitch-add-condition wlist '(class "Emacs" "xemacs"))
                                    '(name "xemacs"))))


                            ((equal key "M-t")
                             (iswitch-add-condition! wlist '(class "XTerm")))

                            ;((equal key "M-g")
                            ; (setq wlist (iswitch-update-class wlist '("galeon_browser"))))

                            ((equal key "M-g")
                             (iswitch-add-condition! wlist '(class "gauche" "eog"))
                             ;(setq wlist (iswitch-update-class wlist '("gauche")))
                             )

                            ((equal key "C-k")
                             (iswitch-add-condition! wlist `(predicate ,window-iconified-p)))

                            ((equal key "M-c")
                             (setq wlist (iswitch-update-class wlist '("X-Chat"))))



                            ((equal key "M-u")
                             ;;(setq wlist (iswitch-update-class wlist '("X-Chat")))
                             ;; prompt-for-user
                             )

                            ((equal key "M-r")
                                        ;(setq wlist (iswitch-update-class wlist '("X-Chat")))
                             ;; prompt-for-user
                             )

                            ((equal key "M-l")
                             ;;
                             (iswitch-add-condition! wlist '(class "XTerm"))
                             (iswitch-add-condition! wlist '(name "Elinks")))

                            ;;"navigator:browser"
                            ;;"Mozilla-bin"
                            ((equal key "M-m")
                             ;; fixme: see browser.jl
                             (iswitch-add-condition!
                              wlist
                              `(predicate
                                ,mozilla-window?)
                              ))
                                        ;"galeon_browser"

                            ((equal key "M-p")
                             ;; fixme: see browser.jl
                             (iswitch-add-condition!
                              wlist
                              `(predicate
                                ,git-browser-window?)
                              ))
                            ((equal key "C-v") ; limit to the current viewport
                             ;; fixme!
                             (iswitch-add-condition!
                              wlist
                              `(viewport ,current-workspace)))


                            ((equal key "C-o") ; limit to the current viewport
                             ;; fixme!
                             (iswitch-add-condition!
                              wlist
                              `(workspace (not . ,current-workspace))))


                            ((equal key "C-s")
                             (setq current-search wlist))
                            ;; Rotations:
                            ((or
                              (equal key "A-s")
                              (equal key "C-i")
                              (equal key "C-p")
                              (equal key "Down")
                              (equal key "TAB"))
                             (setq use-timer #f)
                             (setq wlist (iswitch-rotate-to-next-match input wlist)))
                            ((or (equal key "C-r")
                                 (equal key "A-r")
                                 (equal key "M-i")
                                 (equal key "Up")
                                 (equal key "C-n")
                                 (equal key "M-TAB"))
                             (setq use-timer #f)
                             (setq wlist (iswitch-rotate-to-next-match input wlist t)))
                            ;; Go
                            ((or (equal key "RET")
                                 (equal key "C-m"))

                             (unless (string= input "")
                               (push! current-criterion `(name ,input)))
                             (setq current-search wlist)
                             (throw 'exit-iswitch wlist))

                            ((or (equal key "C-j")) ; push this constraint
                             (iswitch-add-condition! wlist `(name ,input))
                             (setq input ""))

                            ((or (equal key "M-h")) ; push this constraint
                                        ;(get-x-text-property (input-focus) 'WM_CLIENT_MACHINE)
                             (if display-timer
                                 (delete-timer display-timer))
                             (let ((host (prompt-for-host)))
                               ;(display-message host)
                               (iswitch-add-condition! wlist `(host ,host))))


                         ;;; These don't `modify' the wlist:

                            ;; Some handy ops, once we are there why not to ... toggle some
                            ((or (equal key "C-z")
                                 (equal key "A-z"))
                             (let ((w (car wlist)))
                               (if (window-get w 'iconified)
                                   (uniconify-window w)
                                 (iconify-window w))))

                            ((or        ;(equal key "C-h")
                                        ;(equal key "A-h")
                              (equal key "M-s"))
                             (toggle-window-shaded (car wlist)))


                            ;; "C-f" "C-b" ??


                            ;; append ... `chars' only !
                            ((or        ;(equal key "SPC")
                              (= 1 (length event-string))) ; sawfish.wm.events
                             (setq input (concat input event-string)
                                   wlist (iswitch-update-match input wlist))))

                      (when (= 1 (length wlist))
                        (beep)
                                        ;(throw 'exit-iswitch wlist)
                        (display-window (car wlist))))))))

           ;; unwind-protect:
           (display-message nil)
           (x-message-hide iswitch-display-window)
           (if display-timer
               (delete-timer display-timer)))))))


;; Enter iswitch, but at first limit by host:
(define (iswitch-start-host)
  (let ((host (prompt-for-host)))
    (display-window
     (safe-car (iswitch-get-windows
                                        ;(display-message host)
                `((host ,host))))
    )))

(define-command 'iswitch-start-host iswitch-start-host)

                                        ; (ungrab-keyboard-soft)
(define (iswitch-get-window)
    (safe-car (iswitch-get-windows '())))

;;; hi level
  (define (iswitch-window)
    "Pick a window by incremental search and select it." ;(interactive)
    (display-window (iswitch-get-window)))




;; maybe it's useful to just fix a search/set of windows ?
;; Note, that the set-of-windows is not updated!!!
  (define (make-search)
    (setq current-search (iswitch-get-windows '())))

;; But i would like to have such named searches ??



;;; Commands:
  (define-command 'make-search make-search) ; Is it used?

  (define-command 'iswitch-window iswitch-window)

  (define-command 'iswitch-window-continue
    (lambda ()
      (display-window
       (safe-car (iswitch-get-windows current-criterion)))))


  (define-command 'iswitch-window-here	;in this `workspace'!
    (lambda ()
      ;; move-window-to-workspace w old new
      (let ((window (safe-car (iswitch-get-windows '()
                                      ;`((workspace ,current-workspace))

                                      )))
            )
        (when window
        ;(display-window
          (move-window-to-workspace window 0 current-workspace)
          (display-window window)
       ))))

;; ??? this should be an interactive  #:spec   !
  (define (iswitch-window-with act)
    "Pick a window by incremental search, select it and ACT on previous."
                                        ;(interactive)
    (let ((old (car (window-order)))
          (new (iswitch-get-window)))
      (when new
        (unless (or (eq new old)
                    (window-get old 'sticky)
                    (window-outside-viewport-p new))
          (act old))
        (display-window new)))))

;; todo:  colored display.
;(window-class (get-window-by-name-re "X-Chat"))
