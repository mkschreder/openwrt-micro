#
# Copyright (C) 2006-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

KERNEL_MAKEOPTS := -C $(KERNEL_DIR) \
	HOSTCFLAGS="$(HOST_CFLAGS) -Wall -Wmissing-prototypes -Wstrict-prototypes" \
	CROSS_COMPILE="$(KERNEL_CROSS)" \
	ARCH="$(KERNEL_KARCH)" \
	KBUILD_HAVE_NLS=no \
	KBUILD_BUILD_USER="$(call qstrip,$(CONFIG_KERNEL_BUILD_USER))" \
	KBUILD_BUILD_HOST="$(call qstrip,$(CONFIG_KERNEL_BUILD_DOMAIN))" \
	CONFIG_SHELL="$(BASH)" \
	$(if $(findstring c,$(OPENWRT_VERBOSE)),V=1,V='') \
	$(if $(PKG_BUILD_ID),LDFLAGS_MODULE=--build-id=0x$(PKG_BUILD_ID))

ifdef CONFIG_STRIP_KERNEL_EXPORTS
  KERNEL_MAKEOPTS += \
	EXTRA_LDSFLAGS="-I$(KERNEL_BUILD_DIR) -include symtab.h"
endif

INITRAMFS_EXTRA_FILES ?= $(GENERIC_PLATFORM_DIR)/image/initramfs-base-files.txt

ifneq (,$(KERNEL_CC))
  KERNEL_MAKEOPTS += CC="$(KERNEL_CC)"
endif

ifdef CONFIG_USE_SPARSE
  KERNEL_MAKEOPTS += C=1 CHECK=$(STAGING_DIR_HOST)/bin/sparse
endif

export HOST_EXTRACFLAGS=-I$(STAGING_DIR_HOST)/include

# defined in quilt.mk
Kernel/Patch:=$(Kernel/Patch/Default)

KERNEL_GIT_OPTS:=
ifneq ($(strip $(CONFIG_KERNEL_GIT_LOCAL_REPOSITORY)),"")
  KERNEL_GIT_OPTS+=--reference $(CONFIG_KERNEL_GIT_LOCAL_REPOSITORY)
endif

ifneq ($(strip $(CONFIG_KERNEL_GIT_BRANCH)),"")
  KERNEL_GIT_OPTS+=--branch $(CONFIG_KERNEL_GIT_BRANCH)
endif

ifeq ($(strip $(CONFIG_EXTERNAL_KERNEL_TREE)),"")
  ifeq ($(strip $(CONFIG_KERNEL_GIT_CLONE_URI)),"")
    define Kernel/Prepare/Default
	xzcat $(DL_DIR)/$(KERNEL_SOURCE) | $(TAR) -C $(KERNEL_BUILD_DIR) $(TAR_OPTIONS)
	$(Kernel/Patch)
	touch $(KERNEL_DIR)/.quilt_used
    endef
  else
    define Kernel/Prepare/Default
	git clone $(KERNEL_GIT_OPTS) $(CONFIG_KERNEL_GIT_CLONE_URI) $(KERNEL_DIR)
    endef
  endif
else
  define Kernel/Prepare/Default
	mkdir -p $(KERNEL_BUILD_DIR)
	if [ -d $(KERNEL_DIR) ]; then \
		rmdir $(KERNEL_DIR); \
	fi
	ln -s $(CONFIG_EXTERNAL_KERNEL_TREE) $(KERNEL_DIR)
  endef
endif

ifeq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),y)
  ifeq ($(strip $(CONFIG_EXTERNAL_CPIO)),"")
    define Kernel/SetInitramfs/PreConfigure
	grep -v -e INITRAMFS -e CONFIG_RD_ -e CONFIG_BLK_DEV_INITRD $(KERNEL_DIR)/.config.old > $(KERNEL_DIR)/.config
	echo 'CONFIG_BLK_DEV_INITRD=y' >> $(KERNEL_DIR)/.config
	echo 'CONFIG_INITRAMFS_SOURCE="$(strip $(TARGET_DIR) $(INITRAMFS_EXTRA_FILES))"' >> $(KERNEL_DIR)/.config
    endef
  else
    define Kernel/SetInitramfs/PreConfigure
	grep -v INITRAMFS $(KERNEL_DIR)/.config.old > $(KERNEL_DIR)/.config
	echo 'CONFIG_INITRAMFS_SOURCE="$(call qstrip,$(CONFIG_EXTERNAL_CPIO))"' >> $(KERNEL_DIR)/.config
    endef
  endif

  define Kernel/SetInitramfs
	rm -f $(KERNEL_DIR)/.config.prev
	mv $(KERNEL_DIR)/.config $(KERNEL_DIR)/.config.old
	$(call Kernel/SetInitramfs/PreConfigure)
	echo 'CONFIG_INITRAMFS_ROOT_UID=$(shell id -u)' >> $(KERNEL_DIR)/.config
	echo 'CONFIG_INITRAMFS_ROOT_GID=$(shell id -g)' >> $(KERNEL_DIR)/.config
	echo "$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_NONE),CONFIG_INITRAMFS_COMPRESSION_NONE=y,# CONFIG_INITRAMFS_COMPRESSION_NONE is not set)" >> $(KERNEL_DIR)/.config
	echo -e "$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_GZIP),CONFIG_INITRAMFS_COMPRESSION_GZIP=y\nCONFIG_RD_GZIP=y,# CONFIG_INITRAMFS_COMPRESSION_GZIP is not set\n# CONFIG_RD_GZIP is not set)" >> $(KERNEL_DIR)/.config
	echo -e "$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_BZIP2),CONFIG_INITRAMFS_COMPRESSION_BZIP2=y\nCONFIG_RD_BZIP2=y,# CONFIG_INITRAMFS_COMPRESSION_BZIP2 is not set\n# CONFIG_RD_BZIP2 is not set)" >> $(KERNEL_DIR)/.config
	echo -e "$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA),CONFIG_INITRAMFS_COMPRESSION_LZMA=y\nCONFIG_RD_LZMA=y,# CONFIG_INITRAMFS_COMPRESSION_LZMA is not set\n# CONFIG_RD_LZMA is not set)" >> $(KERNEL_DIR)/.config
	echo -e "$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_LZO),CONFIG_INITRAMFS_COMPRESSION_LZO=y\nCONFIG_RD_LZO=y,# CONFIG_INITRAMFS_COMPRESSION_LZO is not set\n# CONFIG_RD_LZO is not set)" >> $(KERNEL_DIR)/.config
	echo -e "$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_XZ),CONFIG_INITRAMFS_COMPRESSION_XZ=y\nCONFIG_RD_XZ=y,# CONFIG_INITRAMFS_COMPRESSION_XZ is not set\n# CONFIG_RD_XZ is not set)" >> $(KERNEL_DIR)/.config
	echo -e "$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_LZ4),CONFIG_INITRAMFS_COMPRESSION_LZ4=y\nCONFIG_RD_LZ4=y,# CONFIG_INITRAMFS_COMPRESSION_LZ4 is not set\n# CONFIG_RD_LZ4 is not set)" >> $(KERNEL_DIR)/.config
  endef
else
endif

define Kernel/SetNoInitramfs
	mv $(KERNEL_DIR)/.config.set $(KERNEL_DIR)/.config.old
	grep -v INITRAMFS $(KERNEL_DIR)/.config.old > $(KERNEL_DIR)/.config.set
	echo 'CONFIG_INITRAMFS_SOURCE=""' >> $(KERNEL_DIR)/.config.set
endef

define Kernel/Configure/Default
	$(KERNEL_CONF_CMD) > $(KERNEL_DIR)/.config.target
# copy CONFIG_KERNEL_* settings over to .config.target
	awk '/^(#[[:space:]]+)?CONFIG_KERNEL/{sub("CONFIG_KERNEL_","CONFIG_");print}' $(TOPDIR)/.config >> $(KERNEL_DIR)/.config.target
	echo "# CONFIG_KALLSYMS_EXTRA_PASS is not set" >> $(KERNEL_DIR)/.config.target
	echo "# CONFIG_KALLSYMS_ALL is not set" >> $(KERNEL_DIR)/.config.target
	echo "CONFIG_KALLSYMS_UNCOMPRESSED=y" >> $(KERNEL_DIR)/.config.target
	$(SCRIPT_DIR)/metadata.pl kconfig $(TMP_DIR)/.packageinfo $(TOPDIR)/.config $(KERNEL_PATCHVER) > $(KERNEL_DIR)/.config.override
	$(SCRIPT_DIR)/kconfig.pl 'm+' '+' $(KERNEL_DIR)/.config.target /dev/null $(KERNEL_DIR)/.config.override > $(KERNEL_DIR)/.config.set
	$(call Kernel/SetNoInitramfs)
	rm -rf $(KERNEL_BUILD_DIR)/modules
	cmp -s $(KERNEL_DIR)/.config.set $(KERNEL_DIR)/.config.prev || { \
		cp $(KERNEL_DIR)/.config.set $(KERNEL_DIR)/.config; \
		cp $(KERNEL_DIR)/.config.set $(KERNEL_DIR)/.config.prev; \
	}
	$(_SINGLE) [ -d $(KERNEL_DIR)/user_headers ] || $(MAKE) $(KERNEL_MAKEOPTS) INSTALL_HDR_PATH=$(KERNEL_DIR)/user_headers headers_install
	$(SH_FUNC) grep '=[ym]' $(KERNEL_DIR)/.config.set | LC_ALL=C sort | md5s > $(KERNEL_DIR)/.vermagic
endef

define Kernel/Configure/Initramfs
	$(call Kernel/SetInitramfs)
endef

define Kernel/CompileModules/Default
	rm -f $(KERNEL_DIR)/vmlinux $(KERNEL_DIR)/System.map
	+$(MAKE) $(KERNEL_MAKEOPTS) modules
endef

OBJCOPY_STRIP = -R .reginfo -R .notes -R .note -R .comment -R .mdebug -R .note.gnu.build-id

# AMD64 shares the location with x86
ifeq ($(KERNEL_KARCH),x86_64)
IMAGES_DIR:=../../x86/boot
endif

define Kernel/CopyImage
	cmp -s $(KERNEL_DIR)/vmlinux $(KERNEL_BUILD_DIR)/vmlinux$(1).debug || { \
		$(KERNEL_CROSS)objcopy -O binary $(OBJCOPY_STRIP) -S $(KERNEL_DIR)/vmlinux $(KERNEL_KERNEL)$(1); \
		$(KERNEL_CROSS)objcopy $(OBJCOPY_STRIP) -S $(KERNEL_DIR)/vmlinux $(KERNEL_BUILD_DIR)/vmlinux$(1).elf; \
		$(CP) $(KERNEL_DIR)/vmlinux $(KERNEL_BUILD_DIR)/vmlinux$(1).debug; \
		$(foreach k, \
			$(if $(KERNEL_IMAGES),$(KERNEL_IMAGES),$(filter-out dtbs,$(KERNELNAME))), \
			$(CP) $(KERNEL_DIR)/arch/$(KERNEL_KARCH)/boot/$(IMAGES_DIR)/$(k) $(KERNEL_BUILD_DIR)/$(k)$(1); \
		) \
	}
endef

define Kernel/CompileImage/Default
	rm -f $(TARGET_DIR)/init
	+$(MAKE) $(KERNEL_MAKEOPTS) $(if $(KERNELNAME),$(KERNELNAME),all) modules
	$(call Kernel/CopyImage)
endef

ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
define Kernel/CompileImage/Initramfs
	$(call Kernel/Configure/Initramfs)
	$(CP) $(GENERIC_PLATFORM_DIR)/base-files/init $(TARGET_DIR)/init
	rm -rf $(KERNEL_BUILD_DIR)/linux-$(KERNEL_VERSION)/usr/initramfs_data.cpio*
	+$(MAKE) $(KERNEL_MAKEOPTS) $(if $(KERNELNAME),$(KERNELNAME),all) modules
	$(call Kernel/CopyImage,-initramfs)
endef
else
define Kernel/CompileImage/Initramfs
endef
endif

define Kernel/Clean/Default
	rm -f $(KERNEL_BUILD_DIR)/linux-$(KERNEL_VERSION)/.configured
	rm -f $(KERNEL_KERNEL)
	$(_SINGLE)$(MAKE) -C $(KERNEL_BUILD_DIR)/linux-$(KERNEL_VERSION) clean
endef


