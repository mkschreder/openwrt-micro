#
# Copyright (C) 2016 Martin K. Schröder <mkschreder.uk@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

ARCH:=arm
BOARD:=naze32
BOARDNAME:=STM32F10x (ARM)
MAINTAINER:=Martin Schröder <mkschreder.uk@gmail.com>
CPU_TYPE:=cortex-m3

include $(INCLUDE_DIR)/target.mk

LINUX_VERSION:=3.18

define Target/Description
	Build firmware images for stm32 cpu
endef

$(eval $(call BuildTarget))
