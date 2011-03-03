
#where we compile
SAWFISH_LISP_DIRS :=  mmc mmc/adt
#what we install from:
INSTALL_DIRS:= mmc mmc/adt

KEYMAP_DIR:=/etc/X11/sawfish/keymaps/
INSTALL_DATA:= /usr/bin/install --mode=444

initdir=/etc/X11/sawfish/site-init.d/
lispdir=/usr/share/sawfish/site-lisp/
# COMPILE_ENV = SAWFISHLISPDIR=. \
# 	      SAWFISHEXECDIR=$(top_builddir)/src/.libexec \
# 	      SAWFISHDOCFILE=../DOC


all: keymaps/default-keymap.jl

keymaps/default-keymap.jl: keymaps/default-keymap.jl.in
	sed -e 's|@@KEYMAPS_PATH@@|$(KEYMAP_DIR)|g' $<  >  $@

# i don't compile
lisp : $(SAWFISH_LISP_FILES)
	set -e; for d in $(SAWFISH_LISP_DIRS); do \
	  $(COMPILE_ENV) $(sawfish_prog) compiler -f compile-lib-batch $$d; \
	done


install:
	install -d $(DESTDIR)/$(lispdir)
	install -d $(DESTDIR)/$(initdir)
	install -d $(DESTDIR)/$(KEYMAP_DIR)/
	$(INSTALL_DATA) -D mmc-init.jl $(DESTDIR)/$(initdir)/
	set -e; for d in $(INSTALL_DIRS); do \
	  install -d $(DESTDIR)/$(lispdir)/$$d; \
	  for f in $$d/*.jl; do \
	    $(INSTALL_DATA) -D $$f $(DESTDIR)$(lispdir)/$$d; \
	  done; \
	  done;
	set -e; for d in keymaps; do \
	  for f in $$d/*.jl; do \
	    $(INSTALL_DATA) -D $$f $(DESTDIR)$(KEYMAP_DIR)/ ; \
	  done; \
	  done;
# $$f



installdirs : mkinstalldirs
	$(SHELL) $< $(foreach x,$(INSTALL_DIRS),$(DESTDIR)$(lispdir)/$(x))
