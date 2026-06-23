# Yocto

The Yocto / EDF flow (AMD's Embedded Development Framework) is the announced successor to
PetaLinux. It can be built for the Quad SFP28 FMC (XXV Ethernet) reference designs with the
cross-platform `build.py` runner at the root of the repository, and produces a Linux image that
exercises the SFP28 ports in exactly the same way as the PetaLinux flow.

```{note}
For 2025.2 both the PetaLinux and Yocto flows are supported and produce an equivalent
image. From the next tool version onward, the PetaLinux flow for this repository will be retired
and Yocto will be the only supported flow.
```

The Yocto flow is supported for the Zynq UltraScale+ and Versal targets (the same set that has
PetaLinux support).

## Requirements

To build the Yocto projects you will need a physical or virtual machine running one of the
[supported Linux distributions], with the Vitis Core Development Kit installed — the flow uses
`xsct`/`sdtgen` (which ship with Vitis) to generate a System Device Tree from the Vivado XSA. You
also need [Google's repo tool](https://gerrit.googlesource.com/git-repo/) on your `PATH`. As with
the other flows, building the XSA requires a valid
[10G/25G Ethernet MAC/PCS license](https://www.xilinx.com/products/intellectual-property/ef-di-25gemac.html)
for the XXV Ethernet IP.

```{attention}
You cannot build the Yocto projects in the Windows operating system. Windows users
are advised to use a Linux virtual machine to build the Yocto projects.
```

## How to build

The build runner locates and sources the Vivado and Vitis settings itself, so there is no
need to source them by hand; you only need [Google's repo tool](https://gerrit.googlesource.com/git-repo/)
on your `PATH` (see Requirements above).

1. From a command terminal, clone the Git repository (with its submodules) and `cd` into it:
   ```
   git clone --recurse-submodules https://github.com/fpgadeveloper/sfp28-fmc-xxv.git
   cd sfp28-fmc-xxv
   ```
2. Build the Yocto image for your target by running the following command, replacing
   `<target>` with one of the target design labels listed in the
   [build instructions](build_instructions.md):
   ```
   ./build.sh yocto --target <target>
   ```

This command launches the corresponding Vivado build if that project has not already been
built and its hardware exported. The first build of a target downloads several GB of sources
(`repo sync`) and runs bitbake from scratch, so it takes a while; subsequent builds are
incremental. The output products are gathered into `Yocto/<target>/images/linux/`:

| File | Description |
| --- | --- |
| `BOOT.BIN` | Boot image (FSBL/PLM + bitstream + U-Boot) |
| `boot.scr` | U-Boot boot script |
| `Image` | Linux kernel |
| `system.dtb` | Linux device tree |
| `rootfs.wic.xz` | Full SD-card disk image — this is what you flash |
| `rootfs.wic.bmap` | Block map for `bmaptool` (fast flashing) |
| `rootfs.tar.gz` | Root filesystem tarball |

## Boot from SD card

Unlike the PetaLinux flow (which produces separate boot files for a hand-partitioned card), the
Yocto flow produces a **full SD-card disk image** (`rootfs.wic.xz`) that already contains all
partitions. You flash that image to the SD card's raw device. The final step depends on the
device family:

* **Zynq UltraScale+ (ZynqMP)** — the wic stages `BOOT.BIN` on an ext4 partition the BootROM
  cannot read, so after flashing you must copy `BOOT.BIN` onto the first FAT partition (`esp`).
* **Versal** — the wic's EFI `esp` partition is pre-populated by `bootimg-efi-amd`
  (systemd-boot + `BOOT.BIN`), so the card boots as-is and there is **nothing to copy**.

### Prepare the SD card

```{warning}
Flashing writes directly to a raw block device and cannot be undone. Be absolutely
certain you have identified the SD card's device node before running the commands below — if you
use the wrong device you risk destroying data on one of your hard drives.
```

1. Identify the SD card device. With the card **un**plugged, run `lsblk -o NAME,SIZE,RM,TYPE`,
   insert the card, and run it again. The new entry — typically `/dev/sdX`, with `RM=1`
   (removable) and a size matching your card — is your target. Replace `sdX` with that device,
   and `<target>` with your board, below.
2. Unmount any partitions the desktop auto-mounted:
   ```
   for p in /dev/sdX?*; do sudo umount "$p" 2>/dev/null; done
   ```
3. Flash the wic image to the raw device. With `bmaptool` (fast — only writes used blocks):
   ```
   sudo bmaptool copy --bmap Yocto/<target>/images/linux/rootfs.wic.bmap \
                            Yocto/<target>/images/linux/rootfs.wic.xz \
                            /dev/sdX
   ```
   Or, as a fallback with `dd`:
   ```
   xzcat Yocto/<target>/images/linux/rootfs.wic.xz \
       | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   ```
4. **(Zynq UltraScale+ only) Install `BOOT.BIN` on the `esp` partition.** The EDF wic leaves the
   first FAT partition (`esp`) empty and installs `BOOT.BIN` onto the ext4 `boot` partition, which
   the BootROM cannot read. Since the BootROM loads `BOOT.BIN` from the first FAT partition, copy
   it onto `esp` by hand:
   ```
   sudo partprobe /dev/sdX
   sudo mkdir -p /mnt/sd_esp
   sudo mount /dev/sdX1 /mnt/sd_esp
   sudo cp Yocto/<target>/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
   sync
   sudo umount /mnt/sd_esp && sudo rmdir /mnt/sd_esp
   ```
   On **Versal** the `esp` partition already contains `BOOT.BIN`, so skip this step.
5. Eject the card cleanly so pending writes flush: `sudo eject /dev/sdX`.

### Boot

1. Plug the SD card into the target board and set it to boot from SD. The boot-mode DIP-switch
   settings are the same regardless of the Linux flow — see the per-board switch settings under
   [Boot PetaLinux](petalinux.md#boot-petalinux).
2. Connect the [Quad SFP28 FMC] to the target board's FMC connector and plug SFP+/SFP28 modules
   into the cages you want to exercise.
3. Connect the USB-UART to your PC and open a terminal emulator at 115200 baud (8N1) — see
   [UART terminal](petalinux.md#uart-terminal).
4. Connect and power your hardware.

## Using the SFP28 ports

Once Linux has booted and you have logged in at the console, the SFP28 ports are exercised
exactly as in the PetaLinux flow — see [Example Usage](petalinux.md#example-usage) for the
port-enable, fixed-IP, DHCP, status and ping walkthrough.

```{note}
**Interface names differ from the PetaLinux flow.** The EDF rootfs uses the systemd
predictable-naming scheme, so the XXV Ethernet ports appear as `end0`–`end3` rather than the
PetaLinux names. The interface number does **not** necessarily track the SFP28 cage number;
identify a port by its MAC address (the per-port MACs assigned in `port-config.dtsi` / the SDT) or
by the controller base address printed at boot (`xilinx_axienet a0000000.ethernet …`). Substitute
the appropriate `end<N>` name into the commands in [Example Usage](petalinux.md#example-usage).
```

## Patches and known issues

The per-board fixups applied in the Yocto flow live under `Yocto/bsp/` — the board
`system-user.dtsi` device-tree overrides, the per-target `port-config.dtsi` overlays, and the
kernel `bsp.cfg` fragments. See [advanced](advanced.md) for the full list. The notable ones:

* **SFP28 cage / XXV PHY wiring (`port-config.dtsi`).** The SFP28 cages and their off-chip parts
  (Si5328 refclk, pca9548 I2C mux, the modules) are not described by the XSA, so each target
  applies a port-config overlay that wires each active cage to the kernel SFP framework: the
  I2C-mux child bus, an `sff,sfp` cage node with its MOD_ABS GPIO, and the `sfp = <&...>` link on
  the XXV MAC node. Three overlays exist — `ports-0` (single-port ZynqMP: `zcu104`,
  `zcu106_hpc1`), `ports-0123` (four-port ZynqMP) and `ports-versal-0123` (four-port Versal,
  whose SDT uses the `sfp_port<N>_xxv_ethernet` label scheme).
* **Kernel SFP framework.** `bsp.cfg` enables `CONFIG_SFP` / `CONFIG_MDIO_I2C` so phylink
  delegates module-presence detection to the `mod-def0-gpios` on each cage; without it the
  `sfp = <&...>` properties are silently ignored and empty cages flap their link state. The copper
  SFP PHY drivers (`CONFIG_MARVELL_10G_PHY`, `CONFIG_AQUANTIA_PHY`, `CONFIG_BCM84881_PHY`,
  `CONFIG_MARVELL_88X2222_PHY`) are added so SFP-10G-T and fiber+SFP modules validate.
* **QPLL reset (ZynqMP).** The ZynqMP overlays carry a shared `qpllreset-gpios` that the patched
  `xilinx_axienet` driver pulses once at first reset to re-lock the GTH QPLL after the Si5328
  refclk reconfiguration glitch. Versal (GTY/CPM5) doesn't need it, so the Versal overlay omits it.
* **MACHINE generated from the XSA.** There is no pinned AMD machine; `gen-machineconf parse-sdt`
  derives `MACHINE = "sfp-<target>"` (PS and PL device tree) directly from each target's Vivado
  XSA, which is what lets third-party boards like the Avnet UltraZed-EV build with no AMD machine
  config.

[Quad SFP28 FMC]: https://docs.opsero.com/op081/datasheet/overview/
[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment
