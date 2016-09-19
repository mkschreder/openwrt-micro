PATH_PREFIX=.

include ./common.mk

HOST_STAMP_BUILT:=$(HOST_BUILD_DIR)/.built
HOST_STAMP_INSTALLED:=$(TOOLCHAIN_DIR)/stamp/.avr_libc_installed

HOST_BUILD_PARALLEL:=1

AVR_LIBC_MAKEOPTS = -C $(HOST_BUILD_DIR) \
	DESTDIR="$(TOOLCHAIN_DIR)/" \
	LIBCC="$(subst libgcc.a,libgcc_initial.a,$(shell $(TARGET_CC) -print-libgcc-file-name))"

define Host/SetToolchainInfo
	$(SED) 's,^\(LIBC_TYPE\)=.*,\1=$(PKG_NAME),' $(TOOLCHAIN_DIR)/info.mk
	$(SED) 's,^\(LIBC_URL\)=.*,\1=http://download.savannah.gnu.org/releases/avr-libc/,' $(TOOLCHAIN_DIR)/info.mk
	$(SED) 's,^\(LIBC_VERSION\)=.*,\1=$(PKG_VERSION),' $(TOOLCHAIN_DIR)/info.mk
	$(SED) 's,^\(LIBC_SO_VERSION\)=.*,\1=$(LIBC_SO_VERSION),' $(TOOLCHAIN_DIR)/info.mk
endef

define Host/Compile
	+$(MAKE) $(HOST_JOBS) $(AVR_LIBC_MAKEOPTS) all
endef

define Host/Install
	$(call Host/SetToolchainInfo)
	$(MAKE) $(AVR_LIBC_MAKEOPTS) DESTDIR="$(TOOLCHAIN_DIR)/usr/" install
	# FIXME: we currently copy this manually for atmega but somehow compiler needs to be able to find them automatically based on -mmcu flag. 
	# copy crtatmega and libatmega
	$(CP) $(TOOLCHAIN_DIR)/lib/avr5/*atmega* $(TOOLCHAIN_DIR)/lib/
endef

$(eval $(call HostBuild))
