# simple makefile 
# BINDIR is passed when invoking 'make'

SETV_SRC_DIR = src/setv
SETV_FILES = setv_main.sh setv_fcn.sh

SETV_RQMT_DIR = rqmts
SETV_RQMT_FILES = requirements.txt ewok.requirements.txt r2d2.requirements.txt

install:
	$(shell mkdir -p $(BINDIR)/share)
	@for f in $(SETV_RQMT_FILE); do cp $(SETV_RQMT_DIR)/$${f} $(INSTALLDIR)/share/$${f}; done

	$(shell mkdir -p $(BINDIR)/bin)
	@for f in $(SETV_FILES); do cp $(SETV_SRC_DIR)/$${f} $(INSTALLDIR)/bin/$${f}; done

.PHONY: install
