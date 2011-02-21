;; for multimedia keys

;;; The XF86 (internet function keys):
;;  I want to use the MS keyboard entirely !   but it is slow.
(when nil
  (bind-keys global-keymap "XF86Start" '(system "gnome-run &"))
  (bind-keys global-keymap "XF86AudioPlay" '(system "xmms -u"))
  (bind-keys global-keymap "XF86AudioStop" '(system "xmms -s"))
  (bind-keys global-keymap "XF86AudioPrev" '(system "xmms -r"))
  (bind-keys global-keymap "XF86AudioNext" '(system "xmms -f"))
  )



(bind-keys global-keymap "XF86AudioNext" '(system "xmms -f"))
(bind-keys global-keymap "XF86Start" '(system "gnome-run &"))
(bind-keys global-keymap "XF86Start" '(system "gnome-run &"))
(bind-keys global-keymap "XF86AudioPlay" '(system "xmms -u"))
(bind-keys global-keymap "XF86AudioStop" '(system-bg "netsay linux3 \"busy\""))
	   ;; '(system "xmms -s")) (system-bg "netsay linux3 \"busy\"")
(bind-keys global-keymap "XF86AudioPrev" '(system "xmms -r"))
(bind-keys global-keymap "XF86AudioNext" 'ring) ;; '(system "xmms -f")




(bind-keys global-keymap "XF86AudioNext" '(system "~/activity/shell/sawfish_rotate_log"))
;(system "ring &")




(bind-keys global-keymap "XF86AudioRaiseVolume"
	   '(let* ((stream (make-string-output-stream))
		   (proc (make-process stream)))
	      (call-process proc nil "/usr/sbin/mixer" "-s" "vol")
	      (if (string-match "vol (\\d+)" (get-output-stream-string stream))
		  (call-process nil nil "/usr/sbin/mixer" "vol"
				(prin1-to-string (+ (read-from-string (expand-last-match "\\1")) 5))) ) ) )

(bind-keys global-keymap "XF86AudioLowerVolume"
	   '(let* ((stream (make-string-output-stream))
		   (proc (make-process stream)))
	      (call-process proc nil "/usr/sbin/mixer" "-s" "vol")
	      (if (string-match "vol (\\d+)" (get-output-stream-string stream))
		  (call-process nil nil "/usr/sbin/mixer" "vol"
				(prin1-to-string (- (read-from-string (expand-last-match "\\1")) 5))))))
