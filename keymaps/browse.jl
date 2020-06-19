;; todo:  explain `elinks-url'


(require 'mmc.browser)
(require 'mmc.xterm)

;; QT api docs browser
(define-command 'assistent (lambda () (system-bg "assistant")))

(bind-keys my-browser-map
  "a" 'maruska
  "A" 'maruska2


                                        ;"a" 'mixer-uniconify
  "s" 'assistent
                                        ;(run-shell-commmand ""
  "c" 'links-cz
  "C" '(netscape-url  "www.linux.cz")

  "u" 'elinks-url
  "h-u" 'elinks-url
  "h-U" 'elinks-small-url
  "U" 'elinks-small-url


  "g" 'google
  "G" 'google-maybe-selection
  ;"G" '(netscape-url "www.google.com")

  "h"  '(elinks-url "it" "chl" "http://www.chl.it")
  "H" '(netscape-url "http://www.computercityhw.com/shop/scripts/emporium.exe/store/index.ach")

  "l" 'elinks-maybe-selection ;;links
  "n" 'browse

  "k" 'konq

  "L" '(netscape-url "maruska.dyndns.org/login")
  "M" '(netscape-url "www.centrohl.it")

  "m" 'chl                              ;(define-links-command 'chl "en" "http://www.chl.it/")
  "w"  'wsws
  "W"  'lwn
                                        ;"u"  'netscape-unbind
  )
