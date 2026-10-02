# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Raise CONFIG_SYS_INIT_SP_BSS_OFFSET so the large system DTB (multi-port MRMAC
# design) fits within u-boot's init-stack/BSS headroom check. See the kconfig
# fragment files/large-dtb-sp-bss.cfg for the rationale.
#
# vck190-vadj-bootcmd.cfg overrides the EDF default bootcmd to enable the FMC VADJ rail
# before distro_bootcmd (see that fragment).
#
# := captures the bbappend dir at parse time (${THISDIR} is unreliable at task
# time inside a bbappend).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://large-dtb-sp-bss.cfg file://vck190-vadj-bootcmd.cfg"
