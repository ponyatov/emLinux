APP = console
HW  = qemu386
-include hw/$(HW).mk
-include cpu/$(CPU).mk
-include arch/$(ARCH).mk
-include app/$(APP).mk

CWD    = $(CURDIR)
MODULE = $(notdir $(CWD))

TMP ?= $(HOME)/tmp
SRC ?= $(TMP)/src
GZ  ?= $(HOME)/gz
FW  ?= $(CWD)/firmware

NOW = $(shell date +%d%m%y)
REL = $(shell git rev-parse --short=4 HEAD)

.PHONY: all
all: dirs config build image

.PHONY: dirs
dirs:
	mkdir -p $(GZ)

.PHONY: clean distclean
distclean: clean
	rm -rf $(BUILDROOT) && git checkout $(BUILDROOT)
clean:

BUILDROOT_VER	= 2019.11.1
BUILDROOT  		= buildroot-$(BUILDROOT_VER)
BUILDROOT_GZ	= $(BUILDROOT).tar.gz

KERNEL_VER		= 5.3.18
KERNEL_CONFIG	= $(BUILDROOT)/output/build/linux-$(KERNEL_VER)/.config

.PHONY:
buildroot: $(BUILDROOT)/README

$(BUILDROOT)/README: $(GZ)/$(BUILDROOT_GZ)
	tar zx < $< && touch $@

.PHONY: config build image qemu

config: $(BUILDROOT)/.config
	# buldroot
	cat config.buildroot hw/$(HW).buildroot >> $<
	echo "BR2_DL_DIR=\"$(GZ)\"" >> $<
	echo "$(ARCH_BR)" >> $<
	echo "$(CPU_BR)" >> $<
	echo "BR2_TOOLCHAIN_BUILDROOT_VENDOR=\"$(USER)\"" >> $<
	echo "BR2_TARGET_GENERIC_HOSTNAME=\"$(APP)\"" >> $<
	echo "BR2_TARGET_GENERIC_ISSUE=\"$(MODULE)/$(APP) build $(NOW)_$(REL)/$(USER) @ $(HW)/$(CPU)\"" >> $<
	echo "BR2_ROOTFS_OVERLAY=\"$(CWD)/files\"" >> $<
	tail $<
	# kernel
	git checkout $(KERNEL_CONFIG)
	cat config.kernel hw/$(HW).kernel cpu/$(CPU).kernel arch/$(ARCH).kernel app/$(APP).kernel >> $(KERNEL_CONFIG)
	echo "CONFIG_LOCALVERSION=\"-$(HW)$(APP)\"" >> $(KERNEL_CONFIG)
	echo "CONFIG_DEFAULT_HOSTNAME=\"$(APP)\"" >> $(KERNEL_CONFIG)

build: config
	cd $(BUILDROOT) ; $(MAKE) menuconfig
	cd $(BUILDROOT) ; $(MAKE) linux-menuconfig
	cd $(BUILDROOT) ; $(MAKE)
$(BUILDROOT)/.config: buildroot 
	cd $(BUILDROOT) ; $(MAKE) allnoconfig

IMAGE_KERNEL = $(FW)/$(NOW)_$(HW)$(APP).kernel
IMAGE_INITRD = $(FW)/$(NOW)_$(HW)$(APP).initrd
image:  $(IMAGE_KERNEL) $(IMAGE_INITRD)
$(IMAGE_KERNEL): $(BUILDROOT)/output/images/bzImage
	dd if=$< of=$@
$(IMAGE_INITRD): $(BUILDROOT)/output/images/rootfs.cpio.gz
	dd if=$< of=$@

QEMU_ARGS += no387
,PHONY: qemu
qemu: $(IMAGE_KERNEL) $(IMAGE_INITRD)
	qemu-system-$(ARCH) $(QEMU) -kernel $(IMAGE_KERNEL) -initrd $(IMAGE_INITRD) -append $(QEMU_ARGS)

.PHONY: gz
gz: $(GZ)/$(BUILDROOT_GZ)

$(GZ)/$(BUILDROOT_GZ):
	$(WGET) -O $@ https://github.com/buildroot/buildroot/archive/$(BUILDROOT_VER).tar.gz

WGET = wget -c

.PHONY: merge release wiki

MERGE  = Makefile README.md .gitignore
MERGE += app hw cpu arch files config.* $(BUILDROOT)

merge:
	git checkout master
	git checkout shadow -- $(MERGE)

release:
	git tag $(NOW)-$(REL)
	git push -v && git push -v --tags
	git checkout shadow

wiki: wiki/Home.md
	$(MAKE) -C wiki

wiki/Home.md:
	git clone -o gh git@github.com:ponyatov/GameConsole.wiki.git wiki
