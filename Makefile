CWD    = $(CURDIR)
MODULE = $(notdir $(CWD))

TMP ?= $(HOME)/tmp
SRC ?= $(TMP)/src
GZ  ?= $(HOME)/gz

NOW = $(shell date +%d%m%y)
REL = $(shell git rev-parse --short=4 HEAD)

.PHONY: all
all: java

.PHONY: clean distclean
distclean: clean
clean:

WGET = wget -c

.PHONY: merge release

MERGE  = Makefile README.md .gitignore

merge:
	git checkout master
	git checkout shadow -- $(MERGE)

release:
	git tag $(NOW)-$(REL)
	git push -v && git push -v --tags
	git checkout shadow
