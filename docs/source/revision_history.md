# Revision History

## 2025.2

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

