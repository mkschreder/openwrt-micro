#
# Copyright (C) 2012-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/target.mk

PKG_NAME:=avr-libc
PKG_VERSION:=$(call qstrip,$(CONFIG_AVR_LIBC_VERSION))
PKG_RELEASE=1

#v1.8.1
#PKG_MD5SUM:=0caccead59eaaa61ac3f060ca3a803ef
#v2.0.0
PKG_MD5SUM:=2360981cd5d94e1d7a70dfc6983bdf15

PKG_SOURCE_URL:=http://download.savannah.gnu.org/releases/avr-libc
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
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

AVR_LIBC_CONFIGURE:= \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	./bootstrap && $(HOST_BUILD_DIR)/configure \
		--prefix=/ \
		--host=avr \
		--disable-nls \

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
		$(AVR_LIBC_CONFIGURE) \
	);
endef

define Host/Clean
	rm -rf \
		$(HOST_BUILD_DIR) \
		$(BUILD_DIR_TOOLCHAIN)/$(PKG_NAME) \
		$(BUILD_DIR_TOOLCHAIN)/$(LIBC)-dev
endef
