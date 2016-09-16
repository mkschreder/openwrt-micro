#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/Generic
  NAME:=Naze32 Cleanflight
  PACKAGES:=cleanflight
endef

define Profile/Generic/Description
	Default cleanflight naze32 build
endef

$(eval $(call Profile,Generic))

