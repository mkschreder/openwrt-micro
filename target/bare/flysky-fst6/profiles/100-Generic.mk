#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/Generic
  NAME:=Default Configuration
  PACKAGES:=
endef

define Profile/Generic/Description
	Default configuration
endef

$(eval $(call Profile,Generic))

