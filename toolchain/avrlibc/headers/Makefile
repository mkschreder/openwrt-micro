PATH_PREFIX:=..

include ../common.mk

HOST_STAMP_BUILT:=$(HOST_BUILD_DIR)/.headers_built
HOST_STAMP_INSTALLED:=$(TOOLCHAIN_DIR)/stamp/.avr_libc_headers_installed

define Host/Compile

endef

define Host/Install
	echo "Headers install"
endef

$(eval $(call HostBuild))

