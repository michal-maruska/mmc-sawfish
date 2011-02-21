
;;; xterm `applications'  still unused

(require 'mmc.xterm)
(require 'mmc.simple)

(require 'sawfish.wm.util.prompt)

;; autoload!!
(require 'mmc.emacs)

(require 'sawfish.wm.util.selection)


(define (get-number-selection prompt)
  (let ((selection-atom 'PRIMARY))
    (if (not (x-selection-active-p selection-atom))
        (prompt-for-number prompt)
      ;;
      (let ((selection (x-get-selection selection-atom)))
	(if (and (stringp selection)
		 (string-match "^[0-9]+$" selection))
	    (string->number selection)
	  (prompt-for-number prompt))))))


;; Get the number from selection!
(define-command 'browse-person
  (lambda (numero)
    ;;  (lambda (numero)
    (system-bg (concat "run-browser.scm  " (number->string numero)))) ;(number->string numero)
  
                                        ;'(list (prompt-for-number "br: "))
  ;; 70732 
  #:spec (lambda ()
          (list (get-number-selection "br: "))))
    


(bind-keys my-application-map
  "e" 'gemacs
  "E" 'gemacs-nodesktop
  "G" 'gemacs-gnus

  "b" 'browse-person

  "d" (lambda ()
        (system-bg "mdb.scm"))
  
  "x" (lambda ()
        (system-bg "xemacs"))

  "u" (lambda ()
        (system-bg "gnome-character-map"))

  "s" (lambda ()
        (system-bg "skype"))
  "m" (lambda ()
        (system-bg "sylpheed"))


  "a" (lambda ()
        (system-bg "xsane"))

  "g" 'gkrellm

  "n" '(lambda ()
         (system-bg "nautilus /dati/foto"))
  ;"q" 'links
  "Q" 'links-google
  "t" 'xterm
                                        ;"a" 'mixer-uniconify
  "c" (lambda ()
                                        ;(system-bg "kcalc")
        (system-bg "gcalctool")
        )
  "C" (lambda ()
        (system-bg "xchat -a"))


  "q" (lambda ()
         (system-bg "/home/mmc/gauche/gg/gauche-mdb/bin/mdb.scm"))
  )


(bind-keys global-keymap "H-y" my-application-map)

