
;; space:

;;  host
;;  user
;;  session .. i need to have more emacs processes on my WS, b/c GNUS is too much consuming...

;; this session thing could be used for elinks ..

;; we need it, because the commands live in the ?? user ?? package,
;; so we need it here !
;; fixme:  is this ok?
(require 'sawfish.wm.util.prompt)

(define-structure mmc.emacs
    (export
      emacs-binary

      gemacs                            ; do we need it ?
      gemacs-nodesktop                  ; idem
      gemacs-gnus
      gemacs-erc
      ;;
      emacs-open
      ;;
      emacs-attach
                                        ; emacs-net
      emacs-remote
      ;; emacs-interactive                 ; we hide the Hash-tables/  from ,user module
      ;emacs-1
      ;emacs-2
      ;emacs-3
      emacs-beta
      emacs-mmc
      emacs-session-open

      ;; variables do it directly !
      )
    (open
     rep
     rep.system
     rep.regexp
     rep.data.ring
                                        ;rep.table
                                        ;rep.structures ; data.symbol-table
     rep.data.tables
     sawfish.wm.misc
     sawfish.wm.events
     sawfish.wm.custom
     sawfish.wm.commands
                                        ;my-prompt
     mmc.my-apps
     mmc.simple
     sawfish.wm.util.prompt)


  (defvar emacs-binary "/usr/bin/emacs"
					;;"/x/cvs/gnu/emacs/src/emacs"
    )
;;; New session:
  (define (gemacs)                      ; would be go-emacs
    "Start a new emacs."
    (system-bg (concat emacs-binary  " -desktop")))

  (define-command 'gemacs gemacs)


  (define (gemacs-nodesktop )
    "Start a new emacs."
    (system-bg (concat emacs-binary " -nodesktop")))
  (define (gemacs-gnus )
    "Start a new emacs."
    ;; -nodesktop
    (system-bg (concat emacs-binary " -gnus")))


(define (gemacs-erc )
    "Start a new emacs."
    ;; -nodesktop
    ;;  -wid C
    (system-bg (concat emacs-binary " -erc")))


  (define-command 'gemacs-nodesktop gemacs-nodesktop)
  (define-command 'gemacs-gnus gemacs-gnus)
(define-command 'gemacs-erc gemacs-erc)


;; the most-general opener:
;; fixme: we need the user-id universal (the same numeric value)
  (define (emacs-open
           #!key
           (hostname "localhost")       ; )
           (user )
           (session 0)
           (xemacs #f))
    (declare (unused hostname user))
    "open a new emacs frame"
    (let ((port (+ 21490 (user-uid)
                   (if xemacs 1000 0)
                   session))
                                        ;(destination (getenv "HOSTNAME")) ; where should the new window appear?
                                        ; display
          )
      (if (host-is-me emacs-host)       ; (system-name) (host-name) defvar mail-domain-name
	                                ;(system-bg (format nil "/usr/local/bin/emacs_net %s" (getenv "DISPLAY")))
          (system-bg
	   ;(format nil "gnuclient -h localhost -p %d" port)
	   ;; 2010: back to:
	   "emacsclient -e '(make-frame)'")

        (system-bg (format nil "ssh -l %s %s '/usr/local/bin/emacs_net %s'"
                           emacs-user emacs-host (display->remote display-name))))))




;;;  A hi-level


;; why global?
;; i want it persistent (over reload of this file)
  (defvar emacs-host (localhost))       ; default host (setq emacs-host (localhost))
  (defvar emacs-user (user-login-name) "") ;default user
  (defvar emacs-session 0 "")



  (define emacs-users-list '("mmc" "beta" "laura"))
  (define emacs-host-list
    '("linux1" "linux2" "linux3" "linux4" "linux5" "linux6" "linux7" "linux8" "linux9" "linux10" "linux11" "linux12" "localhost"))


;; fixme: this should be a function (make-history) ...
;; sorry, but define-command forces me to publish it ..
  (defvar prompt-user-history (make-ring 15) "") ;;   "")
  (defvar prompt-host-history (make-ring 15) "") ;;  "")


  (define (emacs-open-another)          ; w/ the current default values
    (emacs-open #:user emacs-user
                #:host emacs-host
                #:session emacs-session
                ))

  (define (emacs-net)
    "ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (let ((user (prompt-for-user))
          (host (prompt-for-host)))
      (emacs-open #:user user
                                        ;#:title "ssh to remote"
                  #:hostname host
                  #:session 0)))



  (define (emacs-beta)
    "ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (emacs-open
                                        ;(emacs-attach-user "beta")
     #:user "beta"
     #:hostname "linux6"))

  (define (emacs-mmc)
    "ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (emacs-open
     #:user "mmc"
     #:hostname "linux11"))



  (define (emacs)
    "ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (emacs-open))

  (define (emacs1)
    "ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (setq emacs-session 1)
    (emacs-open
     #:session emacs-session))

  (define (emacs2)
    "ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (setq emacs-session 2)
    (emacs-open
     #:session emacs-session))



  (define (emacs-session-open session)
    "ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (setq emacs-session session)
    (emacs-open #:session emacs-session))




  (define (emacs0)
    "ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (setq emacs-session 0)
    (emacs-open
     #:session emacs-session))



;; obsolete:
  (define (emacs-interactive)
    (let* ((user (my-prompt-from-list
                  emacs-users-list  "user: " "" 't ;fixme: should be _"user" ... translated !!
                  prompt-user-history emacs-user))
           (host (my-prompt-from-list
                  emacs-host-list
                  "host: " "" 't
                  prompt-host-history (table-ref emacs-user>host user))) ; was emacs-host
           ;; on which display:
           (destination (concat (getenv "HOSTNAME") (getenv "DISPLAY"))))
      (list user host)))                ; destination


  (define (emacs-attach)                ;destination
    "prepare for opening emacs frames. Ask for the HOST and open remote emacs (of USER) on this DISPLAY"
    (let ((user (prompt-for-user))
          (host (prompt-for-host))
          (session (prompt-for-number "session number:")))
      (setq emacs-host host
            emacs-user user
            emacs-session session)))

  (define-command 'emacs-attach emacs-attach)


                                        ;  (define-command 'emacs-attach emacs-attach
                                        ;    #:spec emacs-interactive)

  (define-command 'emacs-beta emacs-beta)
  (define-command 'emacs-mmc emacs-mmc)

  (define-command  'emacs emacs)
  (define-command 'emacs-open emacs-open-another)

  (define-command  'emacs-session-open emacs-session-open
                   #:spec '(list (prompt-for-number)))

  (define-command  'emacs2 emacs2)

  (define-command  'emacs3
    (lambda ()
      (setq emacs-session 3)
      (emacs-open
       #:session emacs-session)))

  (define-command  'emacs4
    (lambda ()
      (setq emacs-session 4)
      (emacs-open
       #:session emacs-session)))

  (define-command  'emacs1 emacs1)
  (define-command  'emacs0 emacs0)

  (define-command 'xemacs-open (lambda ()(emacs-open 't)))
  (define-command 'emacs-net emacs-net)
  )

