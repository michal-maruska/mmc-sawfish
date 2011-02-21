;;;
;;; animate-move.jl
;;; by Rafal Strzalinski <rstrzali@elka.pw.edu.pl>
;;;
;;; Some functions to asynchronous animated moving windows.
;;; 
;;; TODO:
;;; - change english docs string to english 
;;; 
;;;  add this to your .sawfishrc 
;;; (bind-keys window-keymap
;;;	   "H-x" 'toggle-window-shaded
;;;	   "H-z" 'iconify-window
;;;	   "H-c" 'animate-center-window
;;;	   "H-C" 'center-window
;;;	   "H-k" 'delete-window
;;;	   "H-r" 'rotate-move)
;;;
;;; ;Add this to your modmap to work windows-logo-key as Hyper
;;;  keycode 115 = Hyper_L
;;;  keycode 116 = Hyper_R
;;;  clear MOD3
;;;  add mod3 = Hyper_L  Hyper_R
;;;
;;; with this Windows-logo-keys become more usable

(define-structure mmc.animate-move
  
  (export
   animate-move-window-to
   animate-move-window-exec-to
   animate-move-window-relative
   animate-move-window-right
   animate-move-window-left
   animate-move-window-up
   animate-move-window-down
   animate-rotate-window
   animate-center-window
   animate-window-real-position)
  
  (open
   rep
   rep.system
   rep.io.timers
   ;rep.trace
   sawfish.wm.custom
   sawfish.wm.misc
   sawfish.wm.util.edges
   sawfish.wm.util.workarea
   sawfish.wm.windows
   sawfish.wm.state.maximize)
  
  (defgroup animate-move "Animate move"
    :group move)
  
  (defcustom animate-move-mode 'exp
    "The method of animated moving windows"
    :type (set exp lin)
    :group (move animate-move))
  
  (defcustom animate-move-delay 5
    "Animations rate in milliseconds"
    :type number
    :range (0 . nil)
    :group (move animate-move))
  
  (defcustom animate-horizontal-move-step 20
    "Horizontal step to move a window"
    :type number
    :range (1 . 100)
    :group (move animate-move))
  
  (defcustom animate-vertical-move-step 20
    "Vertical step to move a window"
    :type number
    :range (1 . 100)
    :group (move animate-move))
  
  (defvar animate-move-timer nil)
  
  (defmacro dolist (spec &rest body)
    `(progn 
       (mapc #'(lambda(,(car spec)) ,@body)
	     ,(cadr spec))
       ,(caddr spec)))
  
  (defun abs (x)
    (cond
     ((> x 0) x)
     ((< x 0) (- x))
     (t x)))
  
  (defun approx (x y)
    (if (< (abs (- x y)) 2) 
	t 
      nil))
  
  (defun sgn (x)
    (cond 
     ((> x 0) 1)
     ((< x 0) -1)
     (t 0)))
  
  (defun animate-move-step-exp-to (w tx ty)
    (let ((x (car (window-position w)))
	  (y (cdr (window-position w))))	
      (setq x (+ x (/ (- tx x) 2)))
      (setq y (+ y (/ (- ty y) 2)))
      (move-window-to w (round x) (round y))))

  (defun animate-move-step-lin-to (w tx ty)
    (let ((x (car (window-position w)))
	  (y (cdr (window-position w))))	
      (setq x (+ x (sgn (- tx x))))
      (setq y (+ y (sgn (- ty y))))
      (move-window-to w (round x) (round y))))
  
  (defun animate-move-timer-handler ()
    (let ((nanimate 0))
      (dolist (i (managed-windows))
	(when (window-get i 'animate-move)
	  (setq nanimate (+ nanimate 1))
	  (if (= (window-get i 'animate-focus) t)
	      (set-input-focus i))
	  (let ((x (car (window-position i)))
		(y (cdr (window-position i)))
		(nx (window-get i 'animate-move-x))
		(ny (window-get i 'animate-move-y)))
	    (if  (and (approx x nx) (approx y ny)) 
		(let (func (window-get i 'animate-move-func))
		  (when func
		    (func i)
		    (window-put i 'animate-move-func nil))
		  (move-window-to i (round nx) (round ny))
		  (window-put i 'animate-move nil)
		  (window-put i 'animate-focus nil))
	      (cond 
	       ((eq animate-move-mode 'lin) 
		(animate-move-step-lin-to i nx ny))
	       (t 
		(animate-move-step-exp-to i nx ny)))))))
      
      (if (> nanimate 0)
    	  (set-timer animate-move-timer)
    	(progn 
    	  (delete-timer animate-move-timer)
    	  (setq animate-move-timer nil)))))
  
  
  (defun animate-move-window-to (w x y)
    (unless (window-maximized-fullscreen-p w)
      (interactive "%W")
      (let (timer (window-get w 'animate-move-timer))
	(when timer
	  (delete-timer timer)))
      (window-put w 'previous-position (window-position w))
      (window-put w 'animate-move t)
      (window-put w 'animate-move-x x)
      (window-put w 'animate-move-y y)
      (window-put w 'animate-move-func nil)
      (unless animate-move-timer 
	(setq animate-move-timer (make-timer animate-move-timer-handler
					     (quotient animate-move-delay 1000)
					     (mod animate-move-delay 1000))))))
  
  (defun animate-move-window-exec-to (w x y func)
    (unless (window-maximized-p w)
      (interactive "%W")
      (let (timer (window-get w 'animate-move-timer))
	(when timer
	  (delete-timer timer)))
      (window-put w 'previous-position (window-position w))
      (window-put w 'animate-move t)
      (window-put w 'animate-move-x x)
      (window-put w 'animate-move-y y)
      (window-put w 'animate-move-func func)
      (unless animate-move-timer 
	(setq animate-move-timer (make-timer animate-move-timer-handler
					     (quotient animate-move-delay 1000)
					     (mod animate-move-delay 1000))))))
    
  (define (do-both window avoided edges coords dims fdims)
    (let ((max-rect (largest-rectangle-from-edges
		     edges #:avoided avoided #:head (current-head window))))
      (when max-rect
	(rplaca coords (nth 0 max-rect))
	(rplacd coords (nth 1 max-rect))
	(rplaca dims (- (nth 2 max-rect) (nth 0 max-rect)))
	(rplacd dims (- (nth 3 max-rect) (nth 1 max-rect)))
	;; 	(rplaca dims (- (- (nth 2 max-rect) (nth 0 max-rect))
	;; 			(- (car fdims) (car dims))))
	;; 	(rplacd dims (- (- (nth 3 max-rect) (nth 1 max-rect))
	;; 			(- (cdr fdims) (cdr dims))))
	window)))
  
  
  (defun animate-move-window-relative (w dx dy)
    (let* ((coords (window-position w))
	   (x (car coords))
	   (y (cdr coords)))
      (window-put w 'animate-focus t)
      (animate-move-window-to w (+ x dx) (+ y dy))))
  
  (defun space-available (w)
    (let* ((coords (window-position w))
	   (dims (window-dimensions w))
	   (fdims (window-frame-dimensions w))
	   (hints (window-size-hints w))
	   (avoided (avoided-windows w))
	   (edges (get-visible-window-edges
		   #:with-ignored-windows t
		   #:windows avoided
		   #:include-heads (list (current-head w)))))
      (do-both w avoided edges coords dims fdims)
      (let* ((x-min (car coords))
	     (y-min (cdr coords))
	     (x-max (+ x-min (car dims)))
	     (y-max (+ y-min (cdr dims))))
	(cons (cons x-min y-min) (cons x-max y-max)))
      ))
  
  (defun next-position (x) 
    (cond 
     ((equal x 'center) 'left-top)
     ((equal x 'left-top) 'right-top)
     ((equal x 'right-top) 'right-bottom)
     ((equal x 'right-bottom) 'left-bottom)
     (t 'left-top)))

  (defun get-position-by-name (p w)
    (let* ((wx (car (window-frame-dimensions w)))
	   (wy (cdr (window-frame-dimensions w)))
	   (space (space-available w))
	   (x-min (car (car space)))
	   (y-min (cdr (car space)))
	   (x-max (car (cdr space)))
	   (y-max (cdr (cdr space))))
      (cond
       ((equal p 'left-top) (cons x-min y-min))
       ((equal p 'right-top) (cons (- x-max wx)  y-min))
       ((equal p 'right-bottom)  (cons (- x-max wx)
				       (- y-max wy)))
       ((equal p 'left-bottom) (cons x-min (- y-max wy)))
       (t (cons (- (/ x-max 2) (/ wx 2))
		(- (/ y-max 2) (/ wy 2)))))))
  
  (defun animate-rotate-window (w)
    (interactive "%W")
    (let ((prop (window-get w 'last-pos))
	  (pos (cons 0 0)))
      (setq prop (next-position prop))
      (window-put w 'last-pos prop)
      (window-put w 'animate-focus t)
      (setq pos (get-position-by-name prop w))
      (animate-move-window-to w (car pos) (cdr pos))))
  
  (defun animate-center-window (w)
    (interactive "%W")
    (let* ((pos (get-position-by-name 'center w))
	   (nx (car pos))
	   (ny (cdr pos)))
      (window-put w 'animate-focus t)
      (animate-move-window-to w nx ny)))
  
  (defun animate-window-real-position (w)
    (if (window-get w 'animate-move)
	(cons (window-get w 'animate-move-x)
	      (window-get w 'animate-move-y))
      (window-position w)))
  
  (defun animate-move-window-left (w)
    (interactive "%W")
    (animate-move-window-relative w (- animate-horizontal-move-step) 0))
  
  (defun animate-move-window-right (w)
    (interactive "%W")
    (animate-move-window-relative w animate-horizontal-move-step 0))
  
  (defun animate-move-window-up (w)
    (interactive "%W")
    (animate-move-window-relative w 0 (- animate-vertical-move-step)))
  
  (defun animate-move-window-down (w)
    (interactive "%W")
    (animate-move-window-relative w 0 animate-vertical-move-step))
  )

