;; x-message.jl -- Slightly fancier message display

;; [02 nov 04]  polished by M. Maruska
;; * modularized
;; * more windows possible

;; Pat Regan:  adapting to xinerama
;; (screen-width) ->  (car (head-dimensions 0))
;; (screen-height) -> (cdr (head-dimensions 0))

;; version 0.2

;; Copyright (C) 2000 merlin <merlin@merlin.org>

;; this is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; this is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with sawmill; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;; bug: spacing is added before the first line


;; supported global attributes:
;;
;; 'position - (x . y) position
;; 'gravity - how the window is positioned relative to position
;; 'font - default font
;; 'foreground - default foreground
;; 'background - default background
;; 'border-color - border color
;; 'font - default font
;; 'x-justify - default justification
;; 'spacing - interline spacing
;; 'padding - (x . y) outer padding
;; 'border-width - border width

;; supported inline attributes:    .. The message is a list of strings interspeded w/ these:
;;                                    example:  ("first line normal" (foreground "yellow") "2nd line in yellow" ....)
;; 'font - font
;; 'foreground - foreground
;; 'x-justify - justification
;; 'spacing - interline spacing


(define-structure mmc.x-message
    (export
      message-window?
      x-message-display
      x-message-hide
      split-nl)
    (open
     rep
     rep.system
     rep.regexp
     rep.data.records
                                        ;sawfish.wm.util.prompt
     sawfish.wm.fonts                   ;text-width
     sawfish.wm.misc                    ;screen-wi
     sawfish.wm.colors
     mmc.simple
     mmc.adt.alist
     sawfish.wm.util.x
     rep.trace
     )

(define debug #tf)

  ;; fixme:  don't leak all those GCs
  (define-record-type :message-window
    (make-message-window)
    message-window?

    ;; slots:
    (position position-of set-position)
    (dimension dimension-of set-dimension)
    (attributes attributes-of set-attributes)
    (gc gc-of set-gc)
    (window window-of set-window)
                                        ;(dimension dimension set-dimension!)	; and modifiers
    (message message-of set-message))


;; reloading ....
(defvar message-windows '())
;; (setq message-windows '())
;; Add by
;; remove ...


(define (find-window window)
  (find-first
   (lambda (mw)
     (if (eq window (window-of mw))
         mw #f))
   message-windows))

;; these will become slots!
;;   (defvar message-window nil)
;;   (defvar message-gc nil)
;;   (defvar message-msg nil)
;;   (defvar message-attrs nil)            ; ???
;;   (defvar message-pos (cons 0 0))
;;   (defvar message-dims (cons 0 0))



(defvar default-message-padding (cons 4 4)) ; border around the text.  XXXXTextXXXX

(defvar default-message-foreground "black")
(defvar default-message-background "white")
(defvar default-message-border-color "black")
(defvar default-message-border-width 1)
(defvar default-message-spacing 1)
(defvar default-message-position
  (cons (quotient (car (head-dimensions 0)) 2)  (quotient (cdr (head-dimensions 0)) 2)))




;; we accept Strings for colors/fonts, so convert them (implicitely)
(define (fontify font)
  (if (stringp font) (get-font font) font))

(define (colorify color)
  (if (stringp color) (get-color color) color))


;; the Expose handler:

(defvar x-message-delay '(0 . 300))
;; fixme: also, if DBE is not-supported?
;; todo:  avoid DBE use pixmap!
(define (x-message-repaint-window mwindow #!optional drawable)
  "walk the TEXT LINES and produce the glyphs."
  (let ((message-attrs (attributes-of mwindow))
        (message-msg (message-of mwindow))
        ;; mmc:
        (drawable (or drawable
                            (x-window-back-buffer (window-of mwindow))))
        (message-dims (dimension-of mwindow))
        (message-gc (gc-of mwindow)))

    ;;(when drawable

    (let ((pad (agetd 'padding message-attrs default-message-padding))
          (fg (colorify (cdr (assqd 'foreground message-attrs default-message-foreground))))
          (font (fontify (cdr (assq 'font message-attrs))))
          (justify (agetd 'x-justify message-attrs 'left))
          (spacing (agetd 'spacing message-attrs default-message-spacing))
          (w (car message-dims))
          x y)
      (setq y (cdr pad))

      ;; fixme: make it inherit the background color!

      ;; ??
      (when #f
        (x-change-gc message-gc
                     `((foreground . "yellow") ;black
                       ;(background . "black")
                       ))
        (x-fill-rectangle drawable
                          message-gc
                          '(0 . 0)
                          ;; fixme: fake:
                          '(1000 . 1000)))

      (x-change-gc message-gc `((foreground . ,fg))) ;why ??
      (mapcar (lambda (msg)
                (when (stringp msg)
                  (cond ((eq 'left justify)
                         (setq x (car pad)))
                        ((eq 'center justify)
                         (setq x (quotient (- w (text-width msg font)) 2)))
                        (t ;; (eq 'right justify)
                         (setq x (- w (text-width msg font) (car pad)))))
                  (setq y (+ y (font-ascent font) spacing)) ;; spacing not on first line!   mmc:??
                  (x-draw-string drawable message-gc (cons x y) msg font)
                  (setq y (+ y (font-descent font)))) ;hm, doesn't depend on the text???  g vs. l

                ;; Changing attribs:
                (when (consp msg)
                  (cond ((eq 'font (car msg))
                         (setq font (fontify (cdr msg))))
                        ((eq 'foreground (car msg))
                         (x-change-gc message-gc `((foreground . ,(colorify (cdr msg))))))
                        ((eq 'x-justify (car msg))
                         (setq justify (cdr msg)))
                        ((eq 'spacing (car msg))
                         (setq spacing (cdr msg))))))
              message-msg))
    (sleep-for (car x-message-delay) (cdr x-message-delay))
    (x-window-swap-buffers (window-of mwindow))))


;;
(define (x-message-calculate-dimensions mwindow)
  "walks the TEXT lines, and calculates the width."
  (let ((message-attrs (attributes-of mwindow))
        (message-msg (message-of mwindow))
        message-dims)

    (let ((pad (agetd 'padding message-attrs default-message-padding))
          (font (fontify (cdr (assq 'font message-attrs))))
          (spacing (agetd 'spacing message-attrs default-message-spacing)))
      (setq message-dims (cons (* 2 (car pad)) (* 2 (cdr pad))))

      (mapcar (lambda (msg)
                (when (stringp msg)
                  (rplaca message-dims
                          (max (car message-dims) (+ (* 2 (car pad)) (text-width msg font))))
                  (rplacd message-dims
                          (+ (cdr message-dims) spacing (font-height font)))) ;; spacing not on first line!
                (when (consp msg)
                  ;; only these are relevant for the dimension!
                  (cond ((eq 'font (car msg))
                         (setq font (fontify (cdr msg))))
                        ((eq 'spacing (car msg))
                         (setq spacing (cdr msg))))))
              message-msg)
      (set-dimension mwindow message-dims))))


  ;; (gravity text (x . y)) ->  recomputes (x . y)
  ;;
(define (x-message-calculate-position mwindow)
  (let ((message-attrs (attributes-of mwindow))
        (message-dims (dimension-of mwindow))
        message-pos)
    (let ((pos (agetd 'position message-attrs default-message-position))
          (bw (agetd 'border-width message-attrs default-message-border-width))
          (gravity (agetd 'gravity message-attrs 'center))
          (w (car message-dims))
          (h (cdr message-dims))
          x y)

      (cond ((memq gravity '(north center south))
             (setq x (- (car pos) (quotient w 2) bw)))
            ((memq gravity '(north-west west south-west))
             (setq x (- (car pos) w (* bw 2))))
            (t (setq x (car pos))))
      (cond ((memq gravity '(west center east))
             (setq y (- (cdr pos) (quotient h 2) bw)))
            ((memq gravity '(north-west north north-east))
             (setq y (- (cdr pos) h (* bw 2))))
            (t (setq y (cdr pos))))

      (setq message-pos
            (cons (max (min x (- (car (head-dimensions 0)) w (* bw 2))) 0)
                  (max (min y (- (cdr (head-dimensions 0)) h (* bw 2))) 0)))
      (set-position mwindow message-pos))))

(define (x-message-handler type window  #!optional args)
  (declare (unused args))
  (let ((mwindow (find-window window)))
    (if mwindow
        (cond
         ((eq type 'expose)
          (x-message-repaint-window mwindow))))))


;; init: and even `Xmap'!
(define (x-message-create-window mwindow)
  (let ((message-attrs (attributes-of mwindow))
        (message-dims (dimension-of mwindow))
        (message-pos (position-of mwindow))
        message-window
        message-gc)
    (let* ((bw (agetd 'border-width message-attrs default-message-border-width))
           (bg (colorify (agetd 'background message-attrs default-message-background)))
           (bd (colorify (agetd 'border-color message-attrs default-message-border-color)))
           (window-attrs `((background . ,bg)
                           (border-color . ,bd)
                           (override-redirect . ,t)
                           (save-under . ,nil)
                           (event-mask . ,'(expose))))
           (gc-attrs `((background . ,bg))))

      (setq message-window
            (if (window-of mwindow)
                (progn
                  (DB "recycling an X window!\n")
                  (x-configure-window
                   (window-of mwindow)
                   (append
                    `((x . ,(car message-pos))
                      (y . ,(cdr message-pos))
                      (width . ,(car message-dims))
                      (height . ,(cdr message-dims)))
                    window-attrs))
                  (window-of mwindow))
              (x-create-window message-pos message-dims bw window-attrs x-message-handler)))
      (setq message-gc (x-create-gc message-window gc-attrs))

      (set-window mwindow message-window)
      (set-gc mwindow message-gc)
      ;; fixme: here we should set the background? or what?
      (x-map-window message-window t))))

(define (x-message-update-window mwindow)
  (let ((message-attrs (attributes-of mwindow))
        (message-dims (dimension-of mwindow))
        (message-pos (position-of mwindow))
        (message-window (window-of mwindow))
        (message-gc (gc-of mwindow)))
    (let* ((x (car message-pos))
           (y (cdr message-pos))
           (w (car message-dims))
           (h (cdr message-dims))
           (bw (agetd 'border-width message-attrs default-message-border-width))
           (bg (colorify (agetd 'background message-attrs default-message-background)))
           (bd (colorify (agetd 'border-color message-attrs default-message-border-color)))
           (window-config `((x . ,x) (y  . ,y)
                            (width . ,w) (height . ,h)
                            (border-width . ,bw)
                            (stack-mode . top-if)))
           (window-attrs `((background . ,bg)
                           (border-color . ,bd)))
           (gc-attrs `((background . ,bg))))

      (x-configure-window message-window window-config)
      (x-change-window-attributes message-window window-attrs)
      (x-change-gc message-gc gc-attrs))))



;; mmc: i don't like this (sawfish-as-WM) terminology:
;; we don't merely hide: we destroy!
;;
(define (x-message-hide mwindow)
  "destroy the X window associated w/ MWINDOW"
  (let ((message-window (window-of mwindow))
	(message-gc (gc-of mwindow)))
    (setq message-windows (delq mwindow message-windows)) ;or  message-window?
    (when message-window
      (x-destroy-window message-window)
                                        ;(setq message-window nil)
      (set-window mwindow #f))
    (when message-gc
      (x-destroy-gc message-gc)
                                        ;(setq message-gc nil)
      (set-gc mwindow #f))))

(define (make-message-window-verbose )
  (DB "x-message: creating a new mwindow!\n")
  (make-message-window))

(define (x-message-display message attrs #!key (mwindow (make-message-window-verbose)))
  "message is a list of strings/lines. attrs is global"

                                        ;(let ((mwindow (make-message-window)))
  (unless (memq mwindow message-windows)
    (push! message-windows mwindow))

  (set-message mwindow message)
  (set-attributes mwindow attrs)
  ;; if i update, i have to do it atomically?
  (x-message-calculate-dimensions mwindow)
  (x-message-calculate-position mwindow)

  ;; fixme:
                                        ;(if message-window
                                        ;    (x-message-update-window mwindow)
  (x-message-create-window mwindow)
  (x-message-repaint-window mwindow)
  mwindow)

;; (x-message-display "message" '((position . (0 . 0))) )



;; just a hack to see about overriding the default display-message

;; 'font 'background 'foreground 'x-justify 'spacing 'position

(defun split-nl (msg)
  ;; (eq (elt "abc\nde" 3) ?\n)
  '(let ((index 0)
	 (split nil))
     (while (string-looking-at "([ -z]+)[^ -z]?" msg index)
       (setq split (nconc split (list (substring msg index (match-end 1)))))
       (setq index (match-end)))
     split)
  (string-split "\n" msg))


;; fixme:  this should use a standard window!
(defun zoo-display-message (msg #!optional attrs)
  (if msg
      (let ((pos (cdr (assq 'position attrs))) gravity)
	(when pos
	  (cond
	   ((and (>= (car pos) 0) (>= (cdr pos) 0))
	    (setq gravity 'south-east))
	   ((and (< (car pos) 0) (>= (cdr pos) 0))
	    (setq gravity 'south-west)
	    (rplaca pos (+ (car (head-dimensions 0)) (car pos))))
	   ((and (< (car pos) 0) (< (cdr pos) 0))
	    (setq gravity 'north-west)
	    (rplaca pos (+ (car (head-dimensions 0)) (car pos)))
	    (rplacd pos (+ (cdr (head-dimensions 0)) (cdr pos))))
	   ((and (>= (car pos) 0) (< (cdr pos) 0))
	    (setq gravity 'north-east)
	    (rplacd pos (+ (cdr (head-dimensions 0)) (cdr pos)))))
	  (setq attrs (nconc attrs `((gravity . ,gravity)))))
	(x-message-display (split-nl msg) attrs))
					;(x-message-hide)
    ))

;;  when redefining the record-type: we have to:
;; fixme: first!!
)


;; (if #f
;;   (progn
;;   (mapcar x-message-hide message-windows)
;;   (setq message-windows '())
;;   )
;; )
