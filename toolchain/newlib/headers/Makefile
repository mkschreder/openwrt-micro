PATH_PREFIX:=..

include ../common.mk

HOST_STAMP_BUILT:=$(HOST_BUILD_DIR)/.headers_built
HOST_STAMP_INSTALLED:=$(TOOLCHAIN_DIR)/stamp/.newlib_libc_headers_installed

define Host/Compile

endef

define Host/Install
	$(CP) $(HOST_BUILD_DIR)/include/* $(TOOLCHAIN_DIR)/include/
endef

$(eval $(call HostBuild))

