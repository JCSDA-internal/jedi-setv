# simple makefile 
# BINDIR is passed when invoking 'make'

SETV_SRC_DIR = src/setv
SETV_FILES = setv.sh setv_fcn.sh

install:
	$(shell mkdir -p $(BINDIR)/bin)
	@for f in $(SETV_FILES); do cp $(SETV_SRC_DIR)/$${f} $(BINDIR)/bin/$${f}; done

.PHONY: install
