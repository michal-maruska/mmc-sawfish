;; Command/keybinding  for moving

;;still used !!
(require 'sawfish.wm.state.maximize)
(require 'sawfish.wm.commands.move-resize)

;;; Some automatic sizes, positions:
(defun window-resize  (window)
  (interactive "%W")
  (warp-cursor-to-window window 0 0)
  (resize-window-interactively window))

(defun window-resize-bl  (window)
  (interactive "%W")
  (let ((width (car (window-dimensions window)))
        (height (cdr (window-dimensions window))))
    (warp-cursor-to-window window width height)
    (resize-window-interactively window))) ;call-command ???


(defun resize-medium (window)
  (interactive "%W")
  (resize-window-with-hints*  window
                              (ceiling (/ (* 3 (screen-width)) 4))
                              (ceiling (/ (* 3 (screen-height)) 4)));w width height #!optional hints)
  ;(resize-window-to window 1200 1100)
  (maximize-discard window 't 't))

'(defun resize-half (window)
  (interactive "%W")
  (resize-window-to window (car (window-dimensions window)) 500))


(defun resize-half (window)
  (interactive "%W")
  (let ((dims (window-dimensions window))
	(index 2))
    (resize-window-with-hints* window
		      (/ (car dims) index)
		      (/ (cdr dims) index))))

(defun resize-half-vertically (window)
  (interactive "%W")
  (let ((dims (window-dimensions window))
	(index 2))
    (resize-window-with-hints* window
			       (/ (car dims) index)
			       (cdr dims))))

(defun resize-half-horizontally (window)
  (interactive "%W")
  (let ((dims (window-dimensions window))
	(index 2))
    (resize-window-with-hints*
     window
     (car dims)
     (/ (cdr dims) index))))		      


(defun resize-a4 (window)
  (interactive "%W")
  (resize-window-to window 803
                    (min 1100
                         (- (screen-height)
                            40))
                    ))

(defun resize-block (window)
  (interactive "%W")
  (resize-window-to window 680 1100))

;;;  Slide ???
;;  |~
(defun move-1 (window)
  (interactive "%W")
  (move-window-to window 0 0))

;;  ~|
(defun move-2 (window)
  (interactive "%W")
  (let ((dim (window-dimensions window))
	(width (screen-width)))
    (move-window-to window (- width (car dim) 15) 0)))

;;  _|
(defun move-3 (window)
  (interactive "%W")
  (let ((dim (window-dimensions window))
	(width (screen-width))
	(height (screen-height)))
    (move-window-to window (- width (car dim) 15)
		    (- height (cdr dim) 25))))

;;  |_
(defun move-4 (window)
  (interactive "%W")
  (let ((dim (window-dimensions window))
	(width (screen-width))
	(height (screen-height)))
    (move-window-to window
		    0
		    (- height (cdr dim) 25))))



;; OLD !!
(when nil
  (set-viewport 1600 100)
  ( screen-viewport)
  (window-position (input-focus))
  ;;; For emacs:
  font-lock-defaults
  )

;;; Mouse
(defun center-mouse (window)
  (interactive "%W")
  (let ((dim (window-dimensions window)))
    (warp-cursor-to-window
     window
					;(input-focus)  
     (quotient (car dim) 2) 
     (quotient (cdr dim) 2))))


;(send-to-workspace 
; (get-window-by-name "alsamixer")
; )
;(rename-window (input-focus) "ahasdf")

(provide 'mmc.my-move)
