
;; in progress
(bind-keys global-keymap "H-F11"
	   '(let* ((stream (make-string-output-stream))
		   (proc (make-process stream)))
	      (call-process proc nil "gnome-screensaver-command" "-l")))


