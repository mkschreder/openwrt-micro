#
# Copyright (C) 2012-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/target.mk

PKG_NAME:=newlib
PKG_VERSION:=$(call qstrip,$(CONFIG_NEWLIB_VERSION))
PKG_RELEASE=1

PKG_SOURCE_URL:=ftp://sourceware.org/pub/newlib/
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
LIBC_SO_VERSION:=$(PKG_VERSION)
PATCH_DIR:=$(PATH_PREFIX)/patches

HOST_BUILD_DIR:=$(BUILD_DIR_TOOLCHAIN)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/toolchain-build.mk
include $(INCLUDE_DIR)/hardening.mk

# Please see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=67260
ifeq ($(CONFIG_sh3),y)
TARGET_CFLAGS+= \
	-fno-optimize-sibling-calls
endif

#--host=$(GNU_HOST_NAME) 
#		--target=$(REAL_GNU_TARGET_NAME) 

NEWLIB_CONFIGURE:= \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="-nostdlib $(TARGET_CFLAGS)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	$(HOST_BUILD_DIR)/configure \
		--prefix=/ \
		--with-newlib \
		--host=$(REAL_GNU_TARGET_NAME) \
		--target=$(REAL_GNU_TARGET_NAME) 

define Host/Prepare
	$(call Host/Prepare/Default)
	$(if $(strip $(QUILT)), \
		cd $(HOST_BUILD_DIR); \
		if $(QUILT_CMD) next >/dev/null 2>&1; then \
			$(QUILT_CMD) push -a; \
		fi
	)
	ln -snf $(PKG_NAME)-$(PKG_VERSION) $(BUILD_DIR_TOOLCHAIN)/$(PKG_NAME)
endef

define Host/Configure
	( cd $(HOST_BUILD_DIR); rm -f config.cache; \
		$(NEWLIB_CONFIGURE) \
	);
endef

define Host/Clean
	rm -rf \
		$(HOST_BUILD_DIR) \
		$(BUILD_DIR_TOOLCHAIN)/$(PKG_NAME) \
		$(BUILD_DIR_TOOLCHAIN)/$(LIBC)-dev
endef
