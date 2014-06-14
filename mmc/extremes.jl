;; -*- sawfish -*-

;;; push window to the extreme (of the viewport)

;; lexical:

(define-structure mmc.extremes
    (export)
    (open rep
	  rep.system
	  rep.regexp
	  rep.data.ring
	  sawfish.wm.windows
	  sawfish.wm.events
	  sawfish.wm.misc
	  sawfish.wm.util.rects
	  sawfish.wm.state.maximize
	  sawfish.wm.state.iconify
	  sawfish.wm.custom
	  sawfish.wm.commands
	  sawfish.wm.workspace
	  sawfish.wm.util.workarea
	  sawfish.wm.util.stacking
	  sawfish.wm.commands)


  ;;(define desired-x)
  ;;(define desired-y)

  ;; copied from ...'friedel.corner (by Friedrich Delgado Friedrichs <friedel@nomaden.org>)
  (define (corner-window-position w x y)
    (window-put w 'position x y)
    (move-window-to w x y)
    ;; isn't it implicit?
    (call-window-hook 'after-move-hook w '(())))

  ;; -1 0 1
  ;;
  ;; (   pos(   wid)  size)
  ;; selector moves the inner to the extreme, or not.
  ;;
  (define (shift selector position size width)
    (cond ((eq selector -1)
	   0)
	  ((eq selector 0)
	   position)
	  ((eq selector 1)
	   (- size width)
	   )))

;; within a head ->
  (define (move-to-extreme w vert hor)
;    ""
    (let* ((rectangle (calculate-workarea))
	   ;; (LEFT TOP RIGHT BOTTOM [WEIGHT])
           ;; limit from...
	   (head (current-head w))
           (max-dimension (cons
                           (- (nth 2 rectangle) (nth 0 rectangle))
                           (- (nth 3 rectangle) (nth 1 rectangle))))
	   (position (window-position w))
	   (offset (head-offset 0))
           ;(offset '(0 . 0))
           ;;
           (desired-x
            (shift
             hor
             (car (window-position w))
             (car max-dimension)
             (car (window-frame-dimensions w))))
           (desired-y
            (shift
             vert
             (cdr (window-position w))
             (cdr max-dimension)
             (cdr (window-frame-dimensions w)))))
      (corner-window-position w
			      (+ (nth 0 rectangle) desired-x)
			      (+ (nth 1 rectangle) desired-y))))

  ;; (move (input-focus) 1 0)
  (define-command 'extreme-window-se
    (lambda (w) (move-to-extreme w 1 1)) #:spec "%W")
  (define-command 'extreme-window-sw
    (lambda (w) (move-to-extreme w 1 -1)) #:spec "%W")
  (define-command 'extreme-window-s
    (lambda (w) (move-to-extreme w 1 0)) #:spec "%W")

  ;; west/eastt
  (define-command 'extreme-window-w
    (lambda (w) (move-to-extreme w 0 -1)) #:spec "%W")
  (define-command 'extreme-window-e
    (lambda (w) (move-to-extreme w 0 1)) #:spec "%W")

  ;; north
  (define-command 'extreme-window-n
    (lambda (w) (move-to-extreme w -1 0)) #:spec "%W")
  (define-command 'extreme-window-nw
    (lambda (w) (move-to-extreme w -1 -1)) #:spec "%W")
  (define-command 'extreme-window-ne
    (lambda (w) (move-to-extreme w -1 1)) #:spec "%W")
  )

; (require 'extremes)
