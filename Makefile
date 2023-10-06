# var
MODULE = $(notdir $(CURDIR))

# dirs
CWD  = $(CURDIR)
TMP  = $(CWD)/tmp
HOST = $(CWD)/host
ROOT = $(CWD)/root
GZ   = $(HOME)/gz

# tool
CURL = curl -L -o

# version
BINUTILS_VER = 2.41
GCC_VER      = 13.2.0
GMP_VER      = 6.2.1
MPFR_VER     = 4.2.1
MPC_VER      = 1.3.1

# package
BINUTILS = binutils-$(BINUTILS_VER)
GCC      = gcc-$(GCC_VER)
GMP      = gmp-$(GMP_VER)
MPFR     = mpfr-$(MPFR_VER)
MPC      = mpc-$(MPC_VER)

BINUTILS_GZ = $(BINUTILS).tar.xz
GCC_GZ      = $(GCC).tar.xz
GMP_GZ      = $(GMP).tar.gz
MPFR_GZ     = $(MPFR).tar.xz
MPC_GZ      = $(MPC).tar.xz

# install
.PHONY: install update gz
install: gz
	$(MAKE) update
update:
	sudo apt update
	sudo apt install -yu `cat apt.txt`
gz: \
	$(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ) \
	$(GZ)/$(GMP_GZ) $(GZ)/$(MPFR_GZ) $(GZ)/$(MPC_GZ)
	ls -la $^

$(GZ)/$(BINUTILS_GZ):
	$(CURL) $@ https://ftp.gnu.org/gnu/binutils/$(BINUTILS_GZ)
$(GZ)/$(GCC_GZ):
	$(CURL) $@ http://mirror.linux-ia64.org/gnu/gcc/releases/$(GCC)/$(GCC_GZ)

$(GZ)/$(GMP_GZ):
	$(CURL) $@ https://github.com/alisw/GMP/archive/refs/tags/v$(GMP_VER).tar.gz
$(GZ)/$(MPFR_GZ):	
	$(CURL) $@ https://www.mpfr.org/mpfr-current/$(MPFR_GZ)
$(GZ)/$(MPC_GZ):
	$(CURL) $@ https://ftp.gnu.org/gnu/mpc/$(MPC_GZ)
