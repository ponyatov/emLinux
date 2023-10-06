# var
MODULE = $(notdir $(CURDIR))

# dirs
CWD  = $(CURDIR)
TMP  = $(CWD)/tmp
HOST = $(CWD)/host
ROOT = $(CWD)/root
GZ   = $(HOME)/gz

# version
BINUTILS_VER =
GCC_VER      = 
GMP_VER      =
MPFR_VER     =
MPC_VER      = 

# package
BINUTILS = binutils-$(BINUTILS_VER)
GCC      = gcc-$(GCC_VER)
GMP      = gmp-$(GMP_VER)
MPFR     = mpfr-$(MPFR_VER)
MPC      = mpc-$(MPC_VER)

# install
.PHONY: install update gz
install: gz
	$(MAKE) update
update:
	sudo apt update
	sudo apt install -yu `cat apt.txt`
gz:
