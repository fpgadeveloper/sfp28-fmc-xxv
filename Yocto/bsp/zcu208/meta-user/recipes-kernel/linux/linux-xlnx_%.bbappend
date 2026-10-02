# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"

# QPLL re-lock after the Si5328 refclk reprogramming (qpllreset-gpios in
# port-config.dtsi); without it every port fails with "XXV MAC GT reset not
# complete" / "DMA reset timeout". Same patch as the PetaLinux BSP.
SRC_URI:append = " file://0001-xxv-qpllreset-gpio.patch"
