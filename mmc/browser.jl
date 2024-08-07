;;; Netscape/mozilla etc

(define-structure mmc.browser
    (export
      mozilla-window?
      netscape-running?
      git-browser-window?
      code-browser-window?
      )

    (open
     rep
     rep.system
     rep.mmsystem

     rep.io.timers
     rep.io.files
     sawfish.wm.util.prompt
     sawfish.wm.util.display-window
     sawfish.wm.commands
     sawfish.wm.windows
                                        ;sawfish.wm.misc
     sawfish.wm                         ;x-kill-client
     mmc.display
     mmc.simple
     )

  ;; mozilla has changed the window class, in the past.
  (define (mozilla-window? w)
    (let ((class  (window-class w)))
      (format 't "%s" class)
      (and (stringp class)
           (member (string-downcase class)
                   '("mozilla" "mozillafirebird-bin"
                     "netscape"
                     "iceweasel"
                     "firefox"
                     "firefox-bin"
                     "google-chrome"
                     "chromium"
                     "chromium-browser"
                     "google-chrome-unstable"
                     "google-chrome-stable"
                     "google-chrome-beta"
                     "google-chrome"
                     "nightly"
                     "minefield"
                     )
               ))))

  (define (git-browser-window? w)
    (let ((class  (window-class w)))
      (or (string= class  "P4v.bin")
          (string= class  "Gitk"))))

  (define (code-browser-window? w)
    (let ((class  (window-class w)))
      (or (string= class  "jetbrains-idea-ce")
          (string= class  "jetbrains-studio")
          (string= class  "jetbrains-pycharm-ce")
          (string= class  "jetbrains-clion")
          )))

;; to add the current one:
;;(window-class (get-window-by-name-re "Mozilla "))

  (define (netscape-running?)
    "is the browser running"            ; dcop is so nice !!
    (filter-windows mozilla-window?))


  (define (netscape-remote #!optional url)
    "Start a new netscape window/frame."
    (interactive)
                                        ;(netscape-url (or url "http://maruska.dyndns.org/index.html"))
                                        ;(system-bg "/usr/lib/MozillaFirefox/mozilla-xremote-client \"openurl(,new-window)\"")
    (if url
        (system-bg
         (format #f "/usr/lib/MozillaFirefox/mozilla-xremote-client \"openurl(%s,new-window)\"" url))
                                        ;(system-bg (format #f "firefox -remote \"openurl(%s,new-window)\"" url))
      ;(system-bg "/opt/firefox/firefox -remote \"openurl(,new-window)\"")
      (system-bg "firefox -browser")
      ))

;; "%s %s lynx >/dev/null 2>&1 </dev/null &"

  (define (netscape-url url)
    "Start a new netscape window/frame."
    (if (netscape-running?)
                                        ;(system (format #f "%s -remote 'openURL(%s,new-window)'&" (netscape-program) url))
        (system (format #f "%s '%s'&" (netscape-program) url))
      (system-bg (format nil "%s %s" (netscape-program) url))))

;; (interactive "s")

;; "%s %s lynx >/dev/null 2>&1 </dev/null &"
  (define (netscape-program)
    "return the command to run a fresh instance"
    (let ((mozilla-path
                                        ;(expand-path
                                        ;"/home/mmc/MozillaFirebird/MozillaFirebird"
                                        ;"/home/mmc/firefox/firefox"
           "/opt/firefox/firefox")
                                        ;"/usr/bin/MozillaFirebird"
                                        ;)
          (galeon-path "/usr/bin/galeon"))
      (cond
       ((file-exists-p mozilla-path)
        mozilla-path)
       ((file-exists-p galeon-path)
        galeon-path)
       (#t                              ;else
        ;"/usr/local/netscape/netscape"
        "firefox"
        ))))

  (define (open-browser)
    (if (netscape-running?)
        (netscape-remote)
      (system-bg (netscape-program))))

  (define-command 'browse open-browser)


  (define-command 'mozilla
    (lambda () (system-bg "/usr/bin/mozilla")))


  '(defun netscape-unbind ()
     ""
     (interactive)
     (unbind-keys global-keymap
                  "M-Left" "M-Right"))


  (define-command 'konq (lambda () (system-bg "konqueror")))


;; author: resolve
  (defmacro stagger (time . forms)
    "Use timers to ensure that each form is executed at some delay"
    (let ((base time))
      `(progn
         ,@(mapcar
            (lambda (form)
              (prog1
                  `(make-timer (lambda () ,form) 0 ,base)
                (setq base (+ base time))))
            forms))))


  ;; broken
  '(define (moz-to-w3m)
    "Load the current mozilla url in emacs w3m"
    (stagger 100
             (display-window (browser)) ; appears to be necessary
             (synthesize-event "C-l" (browser))
             (synthesize-event "C-c" (browser))
             (emacs-lisp `(tech-goto ,(x-get-selection 'CLIPBOARD)))
             (display-window (emacs))))


  (define (mgoogle)
    (netscape-remote "http://www.google.com"))
  (define-command 'mgoogle mgoogle))
