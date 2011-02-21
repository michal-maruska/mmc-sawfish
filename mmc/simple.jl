(define-structure mmc.simple
    ;; sawfish.user.
    (export
      print-debug
      ;DB
      
      message-format
      my-read-event

      ;read-one-event

      window-live?

      print-hash
      localhost
      host-is-me
      display->remote
      display-host
      display-number
      set-xauthority

      system-bg
      delete-nth-from-list!
      not-in-numbers
      map-numbers
      my-map-windows
      other-window
      find-first filter-morphing   rotate-list-from!
      compose-path
      user-uid

     
      set-nth!
      my-clean
      ; home-dir
      pop! push!
      string>file
      read-and-run

      string-match-string-list-p
      )
    (open
     rep
     rep.system
                                        ;rep.mmsystem
     rep.data.tables
     rep.io.files                       ;stderr-file
     rep.io.file-handlers
      	  
     sawfish.wm.util.keymap             ; read-event
     sawfish.wm.util.decode-events
     rep.regexp

     rep.trace

                                        ;rep.io.timers
     sawfish.wm.windows
     sawfish.wm.misc                    ; ungrab-keyboard-soft
     sawfish.wm.events
     sawfish.wm.commands
     sawfish.wm.custom
     sawfish.wm.util.window-order
     sawfish.wm.session.init)

  (define debug #t)

  '(define (print-debug fmt #!rest arguments)
    ;(message (apply format #f fmt arguments))
    (apply format (stderr-file) fmt arguments))


;; i provide this in rep.trace !
  '(defmacro DB (fmt #!rest arguments)
    ;; fixme:
    ; `(if ,debug (print-debug ,fmt ,@arguments))
    (if debug
        `(print-debug ,fmt ,@arguments)
      '()))
    
;;

  (define (compose-path a b)
    (concat a "/" b))
  
  (define (message-format format-string  #!rest rest)
    (message (apply format #f format-string rest)))


;; move away !!
  (define (window-live? win)
    (and (windowp win)
         (window-id win)))


  (define (other-window)
    ;; the previous focused ?
    (nth 1 (window-order current-workspace)))
  
  (when #f
    (define alist '(1 2 3))
    (nth-create 10 alist #f #f))


;;  (define home-dir (getenv "HOME"))  (user-home-directory)


  (define (print-hash hash)
    (table-walk
     (lambda (key value)
       (message (format nil "%s-> %s\n" key value)))
     hash))


  ;; I add: C-g
  (define (my-read-event #!optional prompt)
                                        ;(display-message prompt)
    (let ((e (event-name (read-event prompt))))
      (if (string= e "C-g")
          (throw 'command-canceled #t))
      (display-message #f)
      e))

  
  (defmacro pop! (symbol)
    `(setq ,symbol (cdr ,symbol)))


  (defmacro push! (symbol item)
    `(setq ,symbol (cons ,item ,symbol)))

  (define (set-xauthority file)
    (setenv "XAUTHORITY" (canonical-file-name file)))
  
  (define (my-clean)
    "Un-display, "
    (display-message)
                                        ;(menu-stop-process)
    )
  (define-command 'my-clean my-clean)
  
  (define-command 'customize-new (lambda ()
                                   (system-bg "sawfish-configure.scm")))

  (define (localhost)
    (if (string-match "^([^.]+)\\.[^.]+" (system-name))
        (substring (system-name) 0 (match-end 1))
      (system-name)))

;; host:0  ->  :0   host
  (define (display-number display)
    "return the DISPLAY, which can be used on remote hosts."
    (if (string-match ":(.*)" display)
        (expand-last-match ":\\1")))

  (define (display-host display)
    "return the DISPLAY, which can be used on remote hosts."
    (if (string-match "(.*):(.*)" display)
        (let ((name (expand-last-match "\\1")))
          (if (string= name "")
              (system-name)
            name))))

;; ???
  (define (display->remote display)
    (concat (display-host display)
            (display-number display)))

                                        ;(display-number)
                                        ;(display-host)

  (define (host-is-me hostname)
    ;;(getenv "HOSTNAME")
    (let ((localhost (localhost)))
      (or (string= hostname "localhost")
          (string= hostname localhost))))


  (define (user-uid)
    (cond
     ((string= (user-login-name) "mmc") 501)
     ((string= (user-login-name) "beta") 502)
     (t 0)))
            
;; fixme: only public version:
  (define (system-bg command)
    (message (format #f "system: %s" command))
    (system (concat "nohup " command " &")))


  (define (set-nth! list n value)
    (rplaca (nthcdr n list) value))
  

  (define (delete-nth-from-list! list n)
    (when (> n 0)
      (setcdr (nthcdr (1- n) list) (nthcdr (1+ n) list))
      list))
;;; The `same'
;; (define (remove-nth n list)
;;   "remove the N-th element from the LIST"
;;   (let* ((first (nthcdr (- n 1) list))
;; 	 (second (cdr first)))		; should be safe-cdr
;;     (setcdr first (cdr second))))


  (define (my-map-windows condition action #!key (verbose #f))
    ;; on windows which satisfy CONDITION, run ACTIONS
    (map-windows
     (lambda (w)
       (when (condition w)
         (if verbose
             (message (format #f "my-map-windows: action on %s\n" (window-name w))))
         (action w)))))



  (define (map-numbers from to function)
    (let ((result '()))
      (do ((index from (+ 1 index)))
          ((= index to) result)
        ;; fixme: how to declare that function takes 1 arg? `funcall' ?
        (setq result (cons (funcall function index)
                           result)))))




  (define (not-in-numbers numbers)
    ;; numbers is ordered non-empty !!!
    (let loop ((next (+ 1 (car numbers)))
               (set (cdr numbers)))
                                        ;(format #t "%d\n" next)
         (cond ((not set) next)         ;(null-p set)
               ((eq next (car set))
                (loop (+ next 1)
                      (cdr set)))
               ('t next))))


;; obsolete:  see saving
  (define (read-and-run file function)
    (if (file-exists-p file)
        (let ((stream (open-file file 'read))
              object)
          (unwind-protect
              (condition-case my-error
                  (while (setq object (read stream))
                    (funcall function object))
                ;; eof   ok?
                (end-of-stream #t)
                (error .
                       (message "read-and-run: error occured")
                       (message                   
                        (format #f "error: %s\n" my-error))
                       't))
            (close-file stream)))
                                        ;(error "file doesn't exist" file)
      (format (stderr-file) "file doesn't exist: %a" file)))


  (define (find-first function in-list)
    ;; (unless (functionp function) (error "find-first: bad argument 1"))
    ;; (value #t)
    (let step ((list in-list))
      (cond
       ((null list) #f)
       ((function (car list))
          (car list))
       ('t
        (step (cdr list))))))
                                        ;(find-first evenp '(1 3 2))

  (define (filter-first proc list)
    ;; find the firs in LIST, which (proc ##) succeeds.
    (let ((res (filter proc list)))
      (if (null res)
          #f
        (car res))))


;; (rotate-from 2 '(1 2 3 4)) -> (2 3 4 1)

;; this should use srfi-1 !
;; is it related to `forwards' in sawfish.wm.commands.x-cycle ?
;; split-at (member )
(define (rotate-list-from! elem lst)
  (if elem
        (append (memq elem lst) (reverse (cdr (memq elem (reverse lst)))))
      lst))


;;; filtering:
(define (string-match-string-list-p string-list string)
    "does the STRING match ALL elements of string-list"
    (if (null string-list)
        #t
      (and
       (string-match (car string-list) string 0 'ignore-case)
       (string-match-string-list-p (cdr string-list) string))))
;; (string-match-string-list-p "emacs: beta@linux6" (list "emacs" "6"))
  )


;(require 'my-simple)
;(not-in-numbers '(1 2 3 6))
;;(not-in-numbers '())
