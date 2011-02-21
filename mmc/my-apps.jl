
;;; starting apps:
(define-structure mmc.my-apps
    (export
      letter->user
      letter->host
      prompt-for-host
      prompt-for-user
      ;;
      
      )
    (open rep
      rep.system
      sawfish.wm.commands
      mmc.simple                         ; sytem-bg
      )

;;;  key-event transformation:
  (define (letter->user letter)
    (cdr (assoc
          letter
          '(("m" . "mmc")
            ("b" . "beta")
            ("r" . "root")
            ("p" . "postgres")
            ))))

  (define (letter->host letter)
    (or
     (cdr (assoc
           letter
           '(("p" . "linux6")
             ("m" . "linux11")
             ("b" . "linux2")

             ("c" . "linux12")
             ("a" . "linux10")
             ("i" . "linux13")
             ("e" . "linux14")
             ("f" . "linux15")
             ("r" . "linux1")
             ;("t" . "toshiba")
             ("t" . "tablet")           ;portege
             ("d" . "dell")
             )))
     (concat "linux" letter)))

  (define (prompt-for-host #!optional prompt)
    (letter->host (my-read-event (or prompt "host: "))))

  (define (prompt-for-user #!optional prompt)
    (letter->user (my-read-event (or prompt "user: "))))


;;(letter->user (my-read-event "user:"))
;;(letter->host (my-read-event "host:"))

  )

