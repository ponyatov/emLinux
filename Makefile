# var
MODULE  = $(notdir $(CURDIR))
module  = $(shell echo $(MODULE) | tr A-Z a-z)
OS      = $(shell uname -o|tr / _)
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
CORES  ?= $(shell grep processor /proc/cpuinfo | wc -l)

# target
APP = fx
HW  = qemu386
include   hw/$(HW).mk
include  cpu/$(CPU).mk
include arch/$(ARCH).mk
include  app/$(APP).mk

# dirs
CWD  = $(CURDIR)
SRC  = $(CWD)/src
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
SYSLINUX_VER = 6.03
LINUX_VER    = 6.5.5
UCLIBC_VER   = 1.0.44
BUSYBOX_VER  = 1.36.1

# package
BINUTILS = binutils-$(BINUTILS_VER)
GCC      = gcc-$(GCC_VER)
GMP      = gmp-$(GMP_VER)
MPFR     = mpfr-$(MPFR_VER)
MPC      = mpc-$(MPC_VER)
SYSLINUX = syslinux-$(SYSLINUX_VER)
LINUX    = linux-$(LINUX_VER)
UCLIBC   = uClibc-ng-$(UCLIBC_VER)
BUSYBOX  = busybox-$(BUSYBOX_VER)

BINUTILS_GZ = $(BINUTILS).tar.xz
GCC_GZ      = $(GCC).tar.xz
GMP_GZ      = $(GMP).tar.gz
MPFR_GZ     = $(MPFR).tar.xz
MPC_GZ      = $(MPC).tar.gz
SYSLINUX_GZ = $(SYSLINUX).tar.xz
LINUX_GZ    = $(LINUX).tar.xz
UCLIBC_GZ   = $(UCLIBC).tar.xz
BUSYBOX_GZ  = $(BUSYBOX).tar.bz2

# cfg

XPATH    = PATH=$(HOST)/bin:$(PATH)

CFG_HOST = configure --prefix=$(HOST)

.PHONY: fw
fw: fw/bzImage

.PHONY: qemu
qemu: fw/bzImage
	$(QEMU) $(QEMU_CFG) -kernel $<

fw/bzImage: tmp/linux/arch/x86/boot/bzImage
	cp $< $@

# build
.PHONY: gcclibs0 gmp0 mpfr0 mpc0
gcclibs0: gmp0 mpfr0 mpc0

WITH_GCCLIBS = --with-gmp=$(HOST) --with-mpfr=$(HOST) --with-mpc=$(HOST)
CFG_GCCLIBS  = configure --prefix=$(HOST) --disable-shared
CFG_GCCLIBS += $(WITH_GCCLIBS)

CFG_BINUTILS = --disable-nls --target=$(TARGET) --with-sysroot=$(ROOT) \
               --disable-multilib
CFG_GCC0     = $(CFG_BINUTILS) $(WITH_GCCLIBS) \
               --without-headers --with-newlib --enable-languages="c" \
               --disable-shared --disable-decimal-float --disable-libgomp \
               --disable-libmudflap --disable-libssp --disable-libatomic \
               --disable-libquadmath --disable-threads

gmp0: $(HOST)/lib/libgmp.a
$(HOST)/lib/libgmp.a: $(SRC)/$(GMP)/README
	rm -rf $(TMP)/gmp ; mkdir $(TMP)/gmp ; cd $(TMP)/gmp ;\
	$(SRC)/$(GMP)/$(CFG_GCCLIBS) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

mpfr0: $(HOST)/lib/libmpfr.a
$(HOST)/lib/libmpfr.a: $(SRC)/$(MPFR)/README
	rm -rf $(TMP)/mpfr ; mkdir $(TMP)/mpfr ; cd $(TMP)/mpfr ;\
	$(SRC)/$(MPFR)/$(CFG_GCCLIBS) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

mpc0: $(HOST)/lib/libmpc.a
$(HOST)/lib/libmpc.a: $(SRC)/$(MPC)/README
	rm -rf $(TMP)/mpc ; mkdir $(TMP)/mpc ; cd $(TMP)/mpc ;\
	$(SRC)/$(MPC)/$(CFG_GCCLIBS) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

.PHONY: binutils0 gcc0
binutils0: $(HOST)/bin/$(TARGET)-ld
$(HOST)/bin/$(TARGET)-ld: $(SRC)/$(BINUTILS)/README.md
	rm -rf $(TMP)/binutils0 ; mkdir $(TMP)/binutils0 ; cd $(TMP)/binutils0 ;\
	$(XPATH) $(SRC)/$(BINUTILS)/$(CFG_HOST) $(CFG_BINUTILS) &&\
	$(MAKE) -j$(CORES) && $(MAKE) install

gcc0: $(HOST)/bin/$(TARGET)-gcc
$(HOST)/bin/$(TARGET)-gcc: $(SRC)/$(GCC)/README.md
	rm -rf $(TMP)/gcc0 ; mkdir $(TMP)/gcc0 ; cd $(TMP)/gcc0 ;\
	$(XPATH) $(SRC)/$(GCC)/$(CFG_HOST) $(CFG_GCC0) &&\
	$(MAKE) -j$(CORES) all-gcc && $(MAKE) install-gcc &&\
	$(MAKE) -j$(CORES) all-target-libgcc && $(MAKE) install-target-libgcc

KMAKE  = $(XPATH) make -C $(SRC)/$(LINUX) O=$(TMP)/linux \
         ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)- \
         INSTALL_MOD_PATH=$(ROOT) INSTALL_HDR_PATH=$(ROOT)
KONFIG = $(TMP)/linux/.config

.PHONY: linux
linux: $(SRC)/$(LINUX)/README.md
	mkdir -p $(TMP)/linux ; cd $(TMP)/linux ;\
	rm $(KONFIG) ; $(KMAKE) allnoconfig &&\
	cat all/all.kernel arch/$(ARCH).kernel cpu/$(CPU).kernel \
	    hw/$(HW).kernel app/$(APP).kernel   >> $(KONFIG) &&\
	echo CONFIG_DEFAULT_HOSTNAME=\"$(APP)\" >> $(KONFIG) &&\
	$(KMAKE) menuconfig && $(KMAKE) -j$(CORES) &&\
	$(KMAKE) modules_install headers_install

UMAKE = $(XPATH) make -C $(SRC)/$(UCLIBC) O=$(TMP)/uclibc \
         ARCH=$(ARCH) CROSS_COMPILE=$(TARGET)-
UONFIG = $(TMP)/uclibc/.config
.PHONY: uclibc
uclibc: $(SRC)/$(UCLIBC)/README.md
	mkdir -p $(TMP)/uclibc ; cd $(TMP)/uclibc ;\
	rm $(UONFIG) ; $(UMAKE) allnoconfig &&\
	cat all/all.uclibc arch/$(ARCH).uclibc cpu/$(CPU).uclibc \
	    hw/$(HW).uclibc app/$(APP).uclibc   >> $(UONFIG) &&\
	$(UMAKE) menuconfig

# src
.PHONY: src
src: $(SRC)/$(BINUTILS)/README.md $(SRC)/$(GCC)/README.md \
	 $(SRC)/$(GMP)/README $(SRC)/$(MPFR)/README.md $(SRC)/$(MPC)/README.md \
	 $(SRC)/$(SYSLINUX)/README.md $(SRC)/$(LINUX)/README.md
	 du -csh src/*

$(SRC)/$(GMP)/README: $(GZ)/$(GMP_GZ)
	cd $(SRC) ; tar zx < $< && mv GMP-$(GMP_VER) $(GMP) ; touch $@

# rule
$(SRC)/%/README.md: $(GZ)/%.tar.xz
	cd $(SRC) ; xzcat $< | tar x && touch $@
$(SRC)/%/README.md: $(GZ)/%.tar.gz
	cd $(SRC) ;  zcat $< | tar x && touch $@

# install
.PHONY: install update gz
install: gz
	$(MAKE) update
update:
	sudo apt update
	sudo apt install -yu `cat apt.txt`
gz: \
	$(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ) \
	$(GZ)/$(GMP_GZ) $(GZ)/$(MPFR_GZ) $(GZ)/$(MPC_GZ) \
	$(GZ)/$(SYSLINUX_GZ) \
	$(GZ)/$(LINUX_GZ) $(GZ)/$(UCLIBC_GZ) $(GZ)/$(BUSYBOX_GZ)
	du -csh $^

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

$(GZ)/$(SYSLINUX_GZ):
	$(CURL) $@ https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/$(SYSLINUX_GZ)

$(GZ)/$(LINUX_GZ):
	$(CURL) $@ https://cdn.kernel.org/pub/linux/kernel/v6.x/$(LINUX_GZ)
$(GZ)/$(UCLIBC_GZ):
	$(CURL) $@ https://downloads.uclibc-ng.org/releases/$(UCLIBC_VER)/$(UCLIBC_GZ)
$(GZ)/$(BUSYBOX_GZ):
	$(CURL) $@ https://busybox.net/downloads/$(BUSYBOX_GZ)

# merge
MERGE += Makefile apt.txt .gitignore .vscode
MERGE += all arch cpu hw app
MERGE += host root fw
MERGE += src tmp

dev:
	git push -v
	git checkout $@
	git pull -v
	git merge shadow -- $(MERGE)

shadow:
	git push -v
	git checkout $@
	git pull -v

.PHONY: release
release:
	git tag $(NOW)-$(REL)
	git push -v --tags
	$(MAKE) shadow

.PHONY: zip
ZIP = tmp/$(MODULE)_$(NOW)_$(REL)_$(BRANCH).zip
zip:
	git archive --format zip --output $(ZIP) HEAD
#	zip -ru $(ZIP) tmp/*.?pp static/
	unzip -t $(ZIP)
