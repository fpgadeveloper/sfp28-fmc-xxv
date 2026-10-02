# Revision History

## 2025.2

### Yocto (AMD EDF) flow and hardware fixes

* Added the Yocto / EDF build flow (`./build.sh yocto --target <target>`) for all Zynq
  UltraScale+ and Versal targets, alongside PetaLinux. It produces a complete SD-card image
  (`rootfs.wic.xz`). See [Yocto](yocto).
* Yocto, Zynq UltraScale+: all SFP28 ports stayed down with `XXV MAC GT reset not complete` and
  `DMA reset timeout`. The kernel patch `0001-xxv-qpllreset-gpio.patch` of the PetaLinux BSPs is
  now also applied in the Yocto BSPs, so the shared QPLL locks again after Linux programs the
  Si5328.
* Yocto: the board's own Ethernet port (RJ45) linked at 1G but passed no packets, because the TI
  DP83867 PHY was not described in the device tree. The PHY and its RGMII delays are now
  described in the board's `system-user.dtsi`, and the port has a fixed MAC address.
* Yocto: the board-specific kernel arguments (`cma=...`, and `clk_ignore_unused` on Versal) and
  the hostname (`<board>-sfp-2025-2`) were not applied by the EDF boot flow. They are now added
  to the U-Boot boot script (Zynq UltraScale+) or the systemd-boot entry (Versal).
* Yocto, ZCU104: the FMC VADJ supply was not enabled. The FSBL patch of the PetaLinux BSP
  (`zcu104_vadj_fsbl.patch`) is now also applied in the Yocto BSP.
* Yocto, VCK190 / VMK180 / VPK120 / VPK180: the FMC VADJ supply could still be off when Linux
  probed the card. U-Boot now programs and enables the VADJ regulator before booting, as in the
  PetaLinux images.
* Yocto: the image includes `ethtool`, `iperf3` and `phytool` (plus `pciutils`, `mtd-utils`,
  `can-utils`, `nfs-utils`), like the PetaLinux image.
* Yocto: the boot-image zip contains `BOOT.BIN` (and `BOOTAA64.EFI` on Versal), which must be
  copied to the first partition of the SD card after writing the wic image. See
  [Prepare the SD card](yocto.md#prepare-the-sd-card).
* Build runner: `./build.sh package` now rewrites a boot-image zip that is older than the newly
  built files, instead of keeping the zip of an earlier build. `./build.sh clean --keep-boot`
  deletes the intermediate build files of a target but keeps its boot images.
* Documentation: new block diagrams drawn from the block design, a page on
  [testing the SFP28 ports](testing) with link-partner settings and measured throughput, and new
  troubleshooting entries.

### Vivado and PetaLinux

* Bumped to Vivado / PetaLinux 2025.2.
* Added kernel patch `0001-xxv-qpllreset-gpio.patch` so the GTH QPLL
  re-locks on ZynqMP after the FMC's Si5328 reference clock is
  reprogrammed during Linux probe (otherwise the AXI DMA reset times
  out on first `axienet_open()`).
* Added FSBL patch `zcu104_vadj_fsbl.patch` so the ZCU104 FSBL reads
  the FMC EEPROM correctly and programs VADJ to the required voltage.
* Forced `TX_PLL_TYPE` / `RX_PLL_TYPE` to `RPLL` on Versal GT_Quad
  customisations to work around the 2025.2 default of `LCPLL` (which
  fails block lock on 10G/25G Ethernet).
* `PetaLinux` build composes per-target projects from a board BSP
  fragment under `PetaLinux/bsp/<board>/` plus a port-config overlay
  under `PetaLinux/bsp/ports-*/`. See [advanced](advanced) for the
  full layout.

## 2024.1

* First revision

