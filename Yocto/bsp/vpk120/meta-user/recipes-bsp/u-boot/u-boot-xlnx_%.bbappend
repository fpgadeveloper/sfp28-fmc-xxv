# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Raise CONFIG_SYS_INIT_SP_BSS_OFFSET so the large system DTB (multi-port MRMAC
# design) fits within u-boot's init-stack/BSS headroom check. See the kconfig
# fragment files/large-dtb-sp-bss.cfg for the rationale.
#
# := captures the bbappend dir at parse time (${THISDIR} is unreliable at task
# time inside a bbappend).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://large-dtb-sp-bss.cfg"
