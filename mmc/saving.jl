;;  M. Maruska


;; saving & reading data:

(define-structure mmc.saving
    ;; sawfish.user.
    (export
      read-and-run
      string>file
      )
    (open
     rep
     rep.system
     rep.io.files                       ;stderr-file
     ;;rep.io.file-handlers
     rep.regexp

     rep.trace
     )

    (define debug #f "used by rep.trace macros")

  (define (read-and-run file function)
    "`read' lisp data from FILE, and run FUNCTION on each object read.
errors? fixme! should throw."
    (if (file-exists-p file)
        (let ((stream (open-file file 'read))
              object)
          (condition-case my-error
              (while (setq object (read stream))
                (funcall function object))
                                        ; eof
            (error .
                   (DB "read-and-run: error occured")
                   (DB "error: %s\n" my-error))
            't)))
                                        ;(error "file doesn't exist" file)
    (DB "file doesn't exist: %a" file))




  (define (string>file file-name string)
    "save STRING into FILE-NAME.  Make backup."
    (if (file-exists-p file-name)
        (let ((new-name (concat file-name ".~1~")))
          (rename-file file-name new-name)))
    (let ((file-object (open-file file-name 'write)))
      (write file-object string)
      (close-file file-object)))
  )