# simple makefile 
# BINDIR is passed when invoking 'make'

SETV_SRC_DIR = src/venv
SETV_FILES = setv.sh setv_fcn.sh

install:
	@for f in $(SETV_FILES); do cp $(SETV_SRC_DIR)/$${f} $(BINDIR); done

.PHONY: install