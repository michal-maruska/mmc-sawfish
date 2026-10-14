;; (c) 2002 M. Maruska   mmc@maruska.dyndns.org
;; the same licence as the WM sawfish  (gpl)

;; todo:  in a dir

;; customize-   fonts!
;;

;;; Description:
;; This is a module for defining commands
;; to run programs inside xterm, even on remote hosts.

;; mmc.xterm  is used to open xterm logged (ssh) to different hosts as different users, possibly running different programs
;  and the window is marked (possibly) w/ a 'wid'


;; examples:  text browsers

; sawfish.wm.commands.xterm  exports XTERM. so i change the name !
(define-structure mmc.xterm
    (export
      my-xterm
      language->font                    ;  should take the size !!!
      define-xterm-command
      define-links-command
      links
                                        ;elinks-bookmarks
      read-url                          ;should move into my-apps
      )
    (open
     rep
     rep.system
     rep.regexp
     rep.mmsystem

     rep.io.files
     sawfish.wm.windows                 ;window-class
     sawfish.wm.util.prompt
     sawfish.wm.commands

     sawfish.wm.util.selection
     sawfish.wm.misc
     mmc.simple                         ; sytem-bg
     mmc.wid
     mmc.my-apps
     rep.trace
     sawfish.wm.custom
     )

  (define debug #f)
  (defgroup xterm "xterm related")
;;; standard xterm: Fonts
  (define (language->font language #!key size)
    "given a language code, return the font to use for the xterm. #f -> don't specify"
    (cond
     ((string= language "en")
      (if size
          "-*-lucidatypewriter-*-r-normal-*-14-*-*-*-*-*-*"
        #f)
      ;; use the default!  mine is  "-*-lucidatypewriter-medium-r-normal-*-20-*-*-*-*-*-*"   in ~/.Xdefaults
      )
     ((string= language "cz")
      #f                                ; fixme:
                                        ;"-*-lucidatypewriter-medium-r-*-20-*-*-*-*-*-*-2"
      )
     ((string= language "rus") "-*-*-*-r-normal--24-*-*-*-*-*-*-5")
                                        ; "-fn -etl-fixed-medium-r-normal-*-24-*-*-*-*-*-r "
                                        ; "-*-helvetica-medium-r-*-*-34-*-*-*-*-*-*-r"
     ((string= language "rus5") "-*-*-*-r-normal--24-*-*-*-*-*-*-5")
                                        ; "-fn -etl-fixed-medium-r-normal-*-24-*-*-*-*-*-r "
     ('t (language->font "en" size))))



  ;; this clashes w/ ...
  ;; nice
  (defcustom xterm-base-command
    ;; default:
    "wezterm"
    "doc: command to invoke to get terminal"
    :group xterm
    :type string
    :after-set (lambda (symbol value)
                 (custom-set-variable 'my-xterm-command
                                      (calculate-xterm-cmd)))
    )

  (define (cells-in-interval width cell-width percentage)
    (inexact->exact (round (* (/ width cell-width) percentage))))

  (define (calculate-xterm-cmd)
    (let ((font-width 13)
          (font-height 25)
          )
      ;; (setq my-xterm-command  "xterm +wf +sb -sl 500 -j -ls -tm 'rprnt ^-'")  "xterm  +sb -sl 500 -j -ls -bg black -fg white ")
      ;; (setq my-xterm-command "xterm +sb -sl 500 -j -ls  +dc -wc -u8 +vb")
      ;; "xterm +wf +sb -sl 500 -j -ls +dc -u8 +vb"

      (concat xterm-base-command " "
              (format #f  "-geometry %dx%d"
                      ;; fixme: not dynamic:
                                        ;(inexact->exact (round (/ (screen-width) 18 1.4)))
                      ;; the font-size  max 60% ?
                      (min 100
                           (cells-in-interval (car (head-dimensions 0)) font-width 0.6)
                           )
                      (min 40
                           (cells-in-interval (cdr (head-dimensions 0)) font-height 0.6))))))

  ;; (setq my-xterm-command (calculate-xterm-cmd))
  (defcustom my-xterm-command
    (calculate-xterm-cmd)
    "the default command & args"
    :group (xterm)
    :type string                        ;command
    )


  (define (host->rsh-program host)
    "different hosts accept different protocols"
    (declare (unused host))
    ;; i use ssh only, now. But unencrtypted might help, on lan.
    (if
        (member host '())		;"linux9"
        "rsh"
      "ssh -X"))


;;; The general function:
  (define (my-xterm #!key
                    (command my-xterm-command)
                    hostname            ; "localhost")
                    user
                    title
                    (geometry)
                    ;;                     (format nil "%2dx%d+100+100"
                    ;;                             100 ;(round (/ (* (screen-width) 0.7) 5))
                    ;;                             40 ;(round (/ (* (screen-height) 0.7) 20))
                    ;;                             )
                                        ;(position)
                    (background #f)     ;"black"
                    (foreground #f)     ;"white"
                                        ;(args "")
                    (font (language->font "en"))
                    (wid #f)
                    (program "")
                    (login #f)
                    (priority #f)
                    )
                                        ;(setq host-for-new-window #f)
    ;; do we have to run [rs]sh ?
    (if hostname
        (DB "%s vs. %s (%s), title %s.\n" hostname (localhost) program title))
    (if (and hostname (not (string= hostname (localhost))))
        (progn
          (DB "%s vs. %s.\n" hostname (localhost))
          (setq program (concat (or login (host->rsh-program hostname))
                                " "
                                (if user (concat "-l" user " ") "")
                                hostname " " program))
                                        ;(setq host-for-new-window hostname)
          ;; fixme: this should be solved by rxvt: use the all args string, instead of basename of $0 !
          (unless title
            (setq title program)))

      ;; local !!
      (when (and user (not (string= user (user-login-name))))
        (DB "%s vs. %s.\n" user (user-login-name))
        (setq program (concat "su - " user " " program))
        (unless title
          (setq title program))
                                        ;(or program )
        ))
    (let ((command-line
           (concat command
                   (if foreground (concat " -fg " foreground))
                   (if background (concat " -bg '" background "'"))
                   (if geometry (concat " -geometry " geometry)
                     "")
                   (if font (concat " -fn " font)
                     "")
                   (if title (concat " -title '" title "'") ; i should make a function  (argument "-title" title)
                     "")
                   (if (not (string= program "")) (concat " -e " program) ; quote the program!
                     ""))))
      (if wid
          (wid-for-new-window wid))


      (run-for-next-window
       (lambda (w)
         (string= (window-class w) "XTerm"))
       (lambda (w)
         (set-x-text-property w 'sf_host (vector hostname))
                                        ;(window-put w 'host hostname)
         (window-put w 'user user)))

      (if (boundp 'get-priority)
          (let ((our-priority (get-priority 0 0)) ;require !!!
                (nice 0))
            (if (and priority
                     (> priority our-priority))
                (setq nice (- priority our-priority)))


            ;;(message-format "system: %s\n" command-line)
            (system-bg (concat (if (zerop nice)
                                   ""
                                 (concat "nice -n " (number->string nice) " "))
                               command-line)))
        ;;
        (system-bg command-line)
        )))                             ; I renice SF to -10, so this


;;;
  (define new-window-actions '()
    "an alist: (predicate . function) FUNCTION is run on a new window if (PREDICATE window) is true.
Every one is run only on the first matching window!")


  (define (run-custom-hooks window)
    (setq new-window-actions
          (delq #f
                (mapcar (lambda (customization)
                          (if ((car customization) window)
                              (progn
                                ((cdr customization) window)
                                #f)
                            customization))
                        new-window-actions))))

  (add-hook-s 'after-add-window-hook run-custom-hooks)

  (define (run-for-next-window predicate function)
    (push! new-window-actions
           (cons predicate function)))



;;; handy command declaration:
  (define (define-xterm-command command-name . args)
    (define-command command-name
      (lambda ()
        (apply my-xterm args))))

  (define-xterm-command 'elinks-small
    #:font "-*-lucidatypewriter-medium-r-normal-*-14-*-*-*-*-*-*"
    #:program "elinks")


  (define-command 'rsh                  ; not necessarily RSH, but SSH !
    (lambda ()
      (let ((user (prompt-for-user))
            (host (prompt-for-host)))
        (my-xterm #:user user
                  ;; #:title "ssh to remote"
                  #:hostname host
                                        ; #:title (concat "ssh " user "@" host)
                  ))))

;;; THE stock xterm  and other
  (define-command 'my-xterm
    (lambda ()
      (my-xterm #:font (language->font "en")
                #:priority 0)))

  (define-command 'my-small-xterm
    (lambda ()
      (my-xterm #:font "-*-lucidatypewriter-*-r-normal-*-14-*-*-*-*-*-*"
                #:priority 0)))

  (defcustom access-log-host "linux2"
    "hostname where Apache is running & where access-log file is monitored"
    :group (xterm)
    ;; integer
    :type string)                       ;hostname!

  (define-command 'access-log
    (lambda ()
      (my-xterm
                                        ;#:background "dim gray"
                                        ;#:foreground "black"
       #:background "wheat"
       #:foreground "black"
                                        ;#:background "white"
                                        ; #:foreground "black"
       #:geometry "360x53+0+0"
       #:font "10x20"
       #:hostname access-log-host
       #:user "root"
       #:wid "S"
       ;;
                                        ;#:login "rsh"
       ;; args
       )))




  (define-xterm-command 'white-long
    #:background "white"
    #:foreground "black"
    #:geometry "360x53"
    #:font "10x20"
                                        ;#:hostname "linux1"
                                        ;#:user "root"
                                        ;#:wid "S"
    )



  (define-xterm-command 'access-log2
    #:background "white"
    #:foreground "black"
    #:geometry "360x53"
    #:font "10x20"
    #:hostname "linux2"
    #:user "root"
    #:wid "T"
    )


  '(define-xterm-command 'ebay
                                        ;#:hostname "linux10"
     #:wid "i"
                                        ;    #:program
     )

  (define-xterm-command 'postgres
    #:wid "p"
    #:hostname "linux2"
    #:user "postgres"
    )

  (define-xterm-command 'postgres2
    #:wid "P"
    #:hostname "linux11"
    #:user "postgres")


  ;; H-r        user
                                        ; (defcustom user-host
  (define-xterm-command 'beta
    #:wid "b"
    #:hostname "linux2"
    #:user "beta")

  (define-xterm-command 'mmc
    #:wid "m"
    #:hostname "linux11"
    #:user "mmc")

  '(define-xterm-command 'debian
     #:wid "d"
     #:hostname "linux5"
     #:user "root")


  (define-xterm-command 'root
    ;; "gksu /usr/bin/x-terminal-emulator"
    #:wid "r"
    #:user "root")


  (define-xterm-command '2xterm
    ;;"Start a new WIDE xterm."
    ;;rxvt -bg Wheat -fg black
    #:background "wheat"
    #:foreground "black"
    #:geometry "360x53"
    #:font "10x20")


  ;; multilingual xterms:
  (define-xterm-command 'xtermrus
    #:font (language->font "rus"))

  (define-xterm-command 'xtermrus5
    #:font (language->font "rus5"))


  (define-xterm-command 'xtermcz
    #:font (language->font "cz"))





;;; Some real programs:
  (define-xterm-command 'alsamixer
    #:program "alsamixer")

  (define-xterm-command 'mempeak
    #:program "mempeak")

  (define-xterm-command 'rxvt
    #:command "rxvt -sb +ls")           ;  -bg white  -tn xterm

  (define-xterm-command 'lynx
    #:program "lynx -prettysrc")





;;; links
  ;; todo: i need to edit numeric parameters:  links-session
                                        ;(define-custom
  (defcustom links-session 0
    "elinks session to connect to."
    :group (xterm)
    ;; integer
    :type number)

  (defcustom links-program
    "elinks -session-ring 1"            ;  -no-connect
    "Command to invoke links ... not used by `elinks-maybe-selection' "
    :group (xterm)
    :type string)
                                        ; (setq links-program "elinks  -session-ring 0")  -no-connect
  ;; session-ring
  (define-xterm-command 'links
    ;; [05 ott 05]   -u8 but no color!
    ;; [05 ott 05]  was:  #:command "/usr/X11R6/bin/xterm +wf +sb -sl 500 -j -ls +dc -u8"
                                        ;#:command  "rxvt -geometry 100x60 +sb +ls" ;; no scrollbar needed!          ; -tn xterm
    #:program links-program)

;;; Links
  (define (links language url
                 #!key
                 (size #f)
                 (options "")
                 #!rest rest)
    "open an xterm/elinks ready for LANGUAGE, at URL"
    (apply my-xterm
           #:command "rxvt -geometry 100x60 +ls" ;; no scrollbar needed!          ; -tn xterm
           #:program (concat
                      (format #f "%s" links-program) ;-base-session=1  -no-connect
                      (if url
                          (format #f "%s '%s'" options url)
                        ""))
           #:font (language->font language #:size size)
           rest))

  (define-command 'elinks-maybe-selection
    ;; Fixme: When i forgot (lambda()    I was getting freezes:
    ;; SF was requesting selection, but nobody was answering: What does that mean?
    (lambda ()
      (let ((selection-atom 'PRIMARY))
        (if (not (x-selection-active-p selection-atom))
            (links #f #f)
          (let ((selection (x-get-selection selection-atom)))
            (if (and (stringp selection)
                     (or (string-match "^https?:" selection)
                         (string-match "^[-a-z0-9A-Z.]*\\.(org|net|com|us|it|cz)$" selection) ;"mike-west.org"
                         ))
                (links #f selection)
              (links #f #f)))))))

  (define-command 'google-maybe-selection
    (lambda ()
      (let ((selection-atom 'PRIMARY))
        (if (not (x-selection-active-p selection-atom))
            (links #f #f))
        (let ((selection (x-get-selection selection-atom)))
          (if (stringp selection)
              ;; a couple of words on 1 line!
                                        ;(string-match "^http:" selection))
              (progn
                (setq selection (string-replace " " "+" selection))
                ;; string-replace regexp template string
                (links #f (concat "http://www.google.com/search?q=" selection)
                       (options "-no-connect")
                       ))
            (links #f #f))))))


  ;; mmc: what is this?
  (define-xterm-command 'elinks
    #:command  "rxvt -geometry 100x60 -sb +ls" ; -tn xterm
    ;;  "/usr/X11R6/bin/xterm +wf +sb -sl 500 -j -ls +dc -u8"
    #:program (concat links-program " -no-connect www.wsws.org/mobile"))



  (define (define-links-command command-name . args)
    (define-command command-name
      (lambda ()
        (apply links args)))
    command-name)



  ;; Use alist ... or better, a file?
  (define-links-command 'google "en" "https://www.google.com/")

  (define-links-command 'wikinews "en" "http://en.wikinews.org/wiki/Main_Page")
  (define-links-command 'links-cz "cz" "http://www.linux.cz/index.old.html")
  (define-links-command 'wsws "en" "http://www.wsws.org/") ;; mobile

  (define-links-command 'maruska "en" "http://maruska.dyndns.org")
  (define-links-command 'maruska2 "en" "http://maruska.gotdns.org")

  (define-links-command 'wikipedia "en" "http://www.wikipedia.org")
  (define-links-command 'lwn "en" "http://lwn.net/Archives/")

                                        ;(define-links-command 'chl "en" "http://www.chl.it")




;;; Bookmarks is a hash  string -> url. In a file, as sexp to be `read'

  (define (elinks-bookmarks)
    (let ((stream (open-file "~/.bookmarks.sexp" 'read)))
      (read stream)))


  (define (read-url)
    "use for interactive #:spec    read (completing) my bookmarks"
    (let* ((bookmark-list (elinks-bookmarks))
           (tags (mapcar car bookmark-list))
           (selected (prompt-from-list tags "bookmark")))
      (nth 1 (assoc selected bookmark-list))))

  (define-command 'elinks-url
    (lambda (url)
      (links "en" url))
    #:spec
    '(list (read-url)))

  (define-command 'elinks-small-url
    (lambda (url)
      (links "en" url
             #:size 'small))
    #:spec
    '(list (read-url)))

  (define-command 'srfi
    (lambda (number)
      (links "en" (format #f "http://srfi.schemers.org/srfi-%d/srfi-%d.html" number number)))
    #:spec
    '(list (prompt-for-number)))



;;;  ssh &

  (define (rsh-to host)
    ;; (wid-assign-wid-to-window "S")
    (my-xterm #:hostname host))

  (define-command 'rsh-to rsh-to
                  ;;"Start a new WIDE xterm."
                  #:spec '(list (prompt-for-host))
                  ;;(interactive "nNumber: ")
                  )

  (define-command 'urxvt
    ;;"Start a new WIDE xterm."
    (lambda ()
      (my-xterm
       #:command "urxvt -fn \"xft:Bitstream Vera Sans Mono:pixelsize=20\""
       ;;(interactive "nNumber: ")
       )))

  (define (su-to host)
    ;; (wid-assign-wid-to-window "S")
    (my-xterm #:user "root" #:hostname host))

  (define-command 'su-to su-to
                  ;;"Start a new WIDE xterm."
                  #:spec '(list (prompt-for-host))
                  ;;(interactive "nNumber: ")
                  ))


;; Customize:

;;  Beta -> host
;;  michal -> ..
;;

;; access-log !

;; Keys -> user

;; Keys -> host ??


;; todo:
