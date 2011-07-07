
(define-structure mmc.cycle
    (export
      ;;  commmands
      bury-window
      window-focused-p
      exchange-windows

      ;;; Some serious  x-cycle enhancements:
      toggle-cycle-global
      global-cycle-windows
      )
    (open
     rep
     rep.system
                                        ;rep.mmsystem

     sawfish.wm.misc
     rep.data.tables
     sawfish.wm.commands
     sawfish.wm.events
     sawfish.wm.windows.subrs
     sawfish.wm.stacking

     sawfish.wm.commands.x-cycle
     ;;sawfish.wm.util.display-wininfo

     sawfish.wm.util.prompt

     sawfish.wm.workspace
     sawfish.wm.viewport
     mmc.display

     sawfish.wm.windows
     mmc.simple
     mmc.iswitch-window                 ; current-search!
                                        ;window-order ;focus-mode
     sawfish.wm.util.window-order
     )


  (define (window-focused-p window)     ; fixme: is this correct ?
    (eq (input-focus) window))


  (define (bury-window window)
    "make the window least recently focused. therefore lowered !!" 
    ;; `unfocus'
    (exchange-windows)
    (window-order-pop window)
    (lower-window window))

  (define-command 'bury-window bury-window #:spec "%W")


  (define (exchange-windows)
    "switch between the last 2 windows"
    (let ((candidate
           (nth 1
                (if cycle-all-workspaces
                    (window-order)
                  (window-order current-workspace)))))
      (when candidate
        (activate-window candidate))))  ;set-input-focus


  (define-command 'exchange-windows exchange-windows)



;; (define-cycle-command 'toggle-cycle-global toggle-cycle-global)
  (define (toggle-cycle-global #!optional on?)
    ;; on?
    (if cycle-all-workspaces
        (message "toggle-cycle-global: -> local")
      (message "toggle-cycle-global: -> GLOBAL"))
    (if on?
        (setq cycle-all-workspaces (zerop on?)
              cycle-all-viewports (zerop on?))
      (setq cycle-all-workspaces
            (not cycle-all-workspaces)
            cycle-all-viewports
            (not cycle-all-viewports))))


  (define (report-keys #!optional (text "global-cycle-windows:"))
    (message (format #f "%s\t%d\t%s" text (x-server-timestamp) (x-events-queued))))

  (define (global-cycle-windows)
    (x-server-timestamp (+ 1 (x-server-timestamp)))
    (report-keys "global-cycle-windows START:")
    (unwind-protect
        (progn
          (toggle-cycle-global)
          (call-command 'cycle-windows))
      (toggle-cycle-global)))

  (define-command 'global-cycle-windows global-cycle-windows)

  (define-cycle-command-pair
    'cycle-search 'cycle-search-backwards
    (lambda (#!rest args)
      (declare (unused args))
      ;; fixme: unused
      (display-information
       (format #f "%s"
               (mapconcat window-name current-search "\n")))
      current-search))

;;   command -------------- >  cycle-command   |  x-cycle  |
;;     cycle-search-start      cycle-search  ----
;;
  (define (cycle-search-start)

    (setq
     current-search
     (filter window-live? current-search))

    (unwind-protect
        (progn
          (toggle-cycle-global 0)
          (setq cycle-include-iconified 't)
          (call-command 'cycle-search))
      (toggle-cycle-global)
      (setq cycle-include-iconified '())))

  (define-command 'cycle-search-start cycle-search-start)
  )
