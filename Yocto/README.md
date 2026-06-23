# Yocto / EDF builds

This folder builds Linux images for the **Quad SFP28 FMC (XXV Ethernet)**
reference designs using the AMD Yocto / Embedded Development Framework (EDF)
flow — the announced successor to PetaLinux Tools. It targets the Zynq
UltraScale+ (ZynqMP) and Versal boards that the design supports.

## How it works: the parse-sdt flow

The build generates a **custom Yocto MACHINE directly from the Vivado XSA** —
there is no dependency on an AMD-provided machine config. This is what lets the
design serve any board (including third-party boards with no AMD machine, like
the Avnet UltraZed-EV) and lets a customer change the PS in Vivado and have it
flow through automatically:

```
XSA  --sdtgen-->  System Device Tree  --gen-machineconf parse-sdt-->  MACHINE + DTS
```

`scripts/configure-build.sh` runs `xsct`/`sdtgen` on the XSA to produce a System
Device Tree (which includes `pl.dtsi`, the PL hardware extracted from the
design), then runs `gen-machineconf parse-sdt` to emit
`conf/machine/sfp-<target>.conf` plus the lopper-generated per-domain device
trees. The PL **XXV Ethernet cores** therefore come from the design's own SDT —
no hand-curated PL device tree. Because no PL overlay is requested, the Vivado
bitstream is embedded into `BOOT.BIN` (the FSBL/PLM programs the PL at boot).

The SFP28 cages and their off-chip parts (the Si5328 jitter-cleaner refclk, the
pca9548 I2C mux, and the modules themselves), however, are board knowledge the
XSA does not carry, so two small hand-written device-tree files are layered on
top of the generated tree:

* **`bsp/<board>/…/system-user.dtsi`** — SoC-side board quirks (see "Per-board
  fixups").
* **`bsp/port-configs/<ports-*>/…/port-config.dtsi`** — the per-target SFP28
  cage / XXV MAC wiring (see "Port-config overlays").

## Prerequisites

Host packages on Ubuntu 22.04 / 24.04:

```
sudo apt-get install repo gawk wget git diffstat unzip texinfo gcc \
    build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    python3-subunit zstd liblz4-tool file locales libacl1 bmap-tools
```

Plus Vivado 2025.2 (used to produce the XSA this flow consumes) and Vitis
2025.2 — `sdtgen`/`xsct` (used to turn the XSA into a System Device Tree)
ship with Vitis, not Vivado, in 2025.2. The build runner locates and sources
the Vitis environment itself; sourcing it manually is only needed when
running the `scripts/` engine by hand:

```
source <xilinx-install>/2025.2/Vivado/settings64.sh
source <xilinx-install>/2025.2/Vitis/settings64.sh
```

> The XXV Ethernet subsystem is a separately-licensed IP core. A valid
> [10G/25G Ethernet MAC/PCS license](https://www.xilinx.com/products/intellectual-property/ef-di-25gemac.html)
> must be installed to build the XSA this flow consumes.

## Build

Yocto images are built with the cross-platform build runner at the repo root
(this stage requires a native Linux machine; on Windows the runner refuses
it up front and prints the hand-off command):

```
./build.sh yocto --target zcu102_hpc0    # or any target from `./build.sh list`
```

The runner builds the Vivado XSA first if one isn't already present, then
sequences the four scripts in `scripts/` — the engine of the flow
(init-workspace, configure-build, build-image, package-output). The legacy
`cd Yocto && make yocto TARGET=<target>` still works on Linux (the Makefile
is now a thin wrapper around `build.sh`) but is deprecated.

The first build for a target:

1. Builds the Vivado project and exports the XSA if one isn't already
   present.
2. Initializes a manifest workspace under `Yocto/<TARGET>/` with
   `repo init -u https://github.com/Xilinx/yocto-manifests.git -b rel-v2025.2 -m default-edf.xml`
   and `repo sync` (≈5 GB of git history).
3. Sources `edf-init-build-env` to set up the bitbake environment.
4. Generates the System Device Tree from the XSA and runs
   `gen-machineconf parse-sdt` to create `MACHINE = "sfp-<target>"`.
5. Layers `bsp/<board>/conf/local.conf.append` (hostname, kernel cmdline) and
   `bsp/<board>/meta-user/` (kernel config, `system-user.dtsi` board fixups,
   image bbappend) over the EDF default config, plus — when the target has a
   port config — the `bsp/port-configs/<ports-*>/meta-user/` overlay layer.
6. Runs `bitbake edf-linux-disk-image`.
7. Gathers `BOOT.BIN` (with the PL bitstream embedded), `Image`,
   `system.dtb`, `boot.scr`, `rootfs.tar.gz`, `rootfs.wic.xz`, and
   `rootfs.wic.bmap` into `Yocto/<TARGET>/images/linux/`.

Subsequent builds skip `repo sync`. To force a re-config (e.g. after editing
`bsp/<board>/conf/local.conf.append`), remove `Yocto/<TARGET>/configdone.txt`.

`./build.sh yocto --target all` builds every target; `./build.sh status --target all`
reports which are built.

## Port-config overlays (`port-config.dtsi`)

The SFP28 cages and their off-chip parts are board knowledge the XSA does not
carry, and the set of active ports — as well as the SDT label scheme — differs
per target. Two targets can share one board BSP (e.g. `zcu106_hpc0` and
`zcu106_hpc1` both use `bsp/zcu106`) but need *different* port wiring, so the
wiring is factored into per-config overlay **layers** rather than into the board
BSP. This repo ships three:

```
bsp/port-configs/
  ports-0/meta-user/             single-port ZynqMP designs  (zcu104, zcu106_hpc1)
  ports-0123/meta-user/          four-port ZynqMP designs    (xxv_ethernet_0 / _0_1/_2/_3)
  ports-versal-0123/meta-user/   four-port Versal designs    (sfp_port0..3_xxv_ethernet)
```

Each overlay is a small Yocto layer whose `device-tree.bbappend` adds its
`port-config.dtsi` to the Linux device tree via `EXTRA_DT_INCLUDE_FILES`.
`configure-build.sh` adds the selected `bsp/port-configs/<ports-*>/meta-user`
layer to `bblayers.conf` alongside the board layer; a target with no port
config simply gets no overlay (the mechanism is a no-op there, so the scripts
stay identical across repos). Which overlay applies is derived per target from
its device family and its populated SFP28 ports:

* **`ports-0`** — single-port ZynqMP designs (`zcu104`, `zcu106_hpc1`, both with
  `lanes = ["0"]`). Only SFP28 slot 0 is wired to a MAC; the other three cages'
  I2C buses still exist behind the pca9548 mux, but no `xxv_ethernet_0_1/_2/_3`
  node exists in `pl.dtsi`, so referencing those labels would fail the `dtc`
  compile.
* **`ports-0123`** — four-port ZynqMP designs (`uzev`, `zcu102_hpc0`,
  `zcu102_hpc1`, `zcu106_hpc0`, `zcu111`, `zcu208`, `zcu216` and their `_25g`
  variants). ZynqMP instantiates a single XXV with four channels, so the labels
  are `xxv_ethernet_0` and `xxv_ethernet_0_1/_2/_3`.
* **`ports-versal-0123`** — four-port Versal designs (`vck190`, `vmk180`,
  `vpk120`, `vpk180`, `vhk158`, `vek280` and their `_25g` variants). Versal's
  SDT generates one XXV IP per port in its own `sfp_port<N>` hierarchy
  (`sfp_port0_xxv_ethernet` … `sfp_port3_xxv_ethernet`) — a different label set,
  which is why it needs its own overlay rather than sharing `ports-0123`.

For each active port, `port-config.dtsi` wires the SFP cage to the kernel SFP
framework: the pca9548 I2C-mux child bus (`sfp_ethN_i2c`), an `sff,sfp` cage
node with its `mod-def0-gpios` MOD_ABS line, the `sfp = <&sfp_ethN>` link on the
`&xxv_ethernet_*` MAC node, and (on the ZynqMP overlays) the shared
`qpllreset-gpios` the patched `xilinx_axienet` driver pulses to re-lock the GTH
QPLL after the Si5328 refclk reconfiguration glitch. The Versal overlay omits
`qpllreset-gpios` (the GTY/CPM5 quad doesn't get stuck) and relies on the SDT's
per-port MAC addresses; the ZynqMP `ports-0123` overlay assigns fixed MACs to
ports 1-3 (port 0 already gets `00:0a:35:00:00:01` from `pl.dtsi`).

## Per-board fixups (`system-user.dtsi`)

Each board's `bsp/<board>/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`
is layered onto the generated Linux device tree (via `EXTRA_DT_INCLUDE_FILES`,
guarded so it only applies to the Linux domain DT — the FSBL/PMU/PLM domain DTs
don't define the SoC peripheral labels). It contains only SoC-side board quirks,
not PL hardware or SFP wiring (that's the port-config overlay):

* **UART mapping (ZynqMP `zcu102`, `zcu104`, `zcu106`, `zcu111`, `zcu208`,
  `zcu216`)**: the 2025.2 flow leaves `port-number = <0>` on both `uart0` and
  `uart1`, so the `ttyPS0`/`ttyPS1` mapping is left to probe order. These boards
  pin the port numbers and serial aliases so the console (cabled to UART0) is
  deterministic.
* **Versal boards (`vck190`, `vmk180`, `vpk120`, `vpk180`, `vhk158`, `vek280`)**
  carry a small `zocl-versal` DRM node so the Xilinx runtime/zocl stack probes
  correctly; `vek280` additionally declares its PL-DDR / LPDDR `reserved-memory`
  regions.
* **`uzev` only**: the Avnet UltraZed-EV is a third-party SOM+carrier, so its
  `system-user.dtsi` is much larger — external GTR reference clocks + `&psgtr`
  mapping (for the PS-GTR-routed SATA/USB3), the on-SOM `gem3` PHY (with its MAC
  read from the board EEPROM via `nvmem-cells`), the I2C power/clock/EEPROM tree,
  eMMC, QSPI and SATA. It is ported from the proven PetaLinux `uzev` BSP.

Kernel config fragments live in
`bsp/<board>/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:

* **All boards**: `CONFIG_AMD_PHY`, `CONFIG_XILINX_PHY`, plus the kernel SFP
  framework (`CONFIG_SFP`, `CONFIG_MDIO_I2C`) so phylink can delegate
  module-presence detection to the `mod-def0-gpios` on each `sfp-eth*` node, and
  the copper-SFP PHY drivers (`CONFIG_MARVELL_10G_PHY`, `CONFIG_AQUANTIA_PHY`,
  `CONFIG_BCM84881_PHY`, `CONFIG_MARVELL_88X2222_PHY`) that the SFP-10G-T and
  fiber+SFP modules need.
* **Zynq UltraScale+**: `CONFIG_XILINX_DMA_ENGINES`, `CONFIG_XILINX_DPDMA`,
  `CONFIG_XILINX_ZYNQMP_DMA`.

## Flashing to SD card

The build produces a full wic disk image (`rootfs.wic.xz`). Flash it to the SD
card's raw device; per-partition file copies do **not** work because the boot
script boots from the device it finds itself on. The EDF wks differs by family:

* **Zynq UltraScale+ (ZynqMP)** — a 4-partition layout (`esp` (vfat), `boot`
  (ext4), `root` (ext4), `storage` (vfat)). It leaves the `esp` partition empty
  and installs `BOOT.BIN` onto the ext4 `boot` partition, which the BootROM
  cannot read. The BootROM reads `BOOT.BIN` from the first FAT partition
  (`esp`), so after flashing you must drop `BOOT.BIN` onto `esp` by hand (step 4
  below). Rootfs mounts on `/dev/mmcblk0p3`.
* **Versal** — an EFI wks: `bootimg-efi-amd` pre-populates the `esp` partition
  with systemd-boot **and** `BOOT.BIN`, so the card boots as-is — **there is no
  `BOOT.BIN` copy step** (skip step 4). The rootfs is located by EFI/partlabel
  (the kernel command line carries no fixed `root=`).

### 1. Identify the SD card device — carefully

`dd`-style writes to a block device cannot be undone. With the SD card
**un**plugged, run `lsblk -o NAME,SIZE,RM,TYPE,MOUNTPOINT`; insert the card and
re-run it. The new entry (typically `/dev/sdX`, `RM=1`, size matching your card)
is your target. Confirm with
`udevadm info --query=property --name=/dev/sdX | grep -E "ID_BUS|ID_MODEL"`
(`ID_BUS=usb`). **Do not proceed until you are certain `/dev/sdX` is your SD card
and not an internal disk.**

### 2. Unmount any auto-mounted partitions

```
for p in /dev/sdX?*; do sudo umount "$p" 2>/dev/null; done
```

### 3. Flash the wic image to the raw device

```
sudo bmaptool copy \
    --bmap Yocto/<TARGET>/images/linux/rootfs.wic.bmap \
          Yocto/<TARGET>/images/linux/rootfs.wic.xz \
          /dev/sdX
```

Fallback (slower): `xzcat …/rootfs.wic.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync`.

### 4. Install BOOT.BIN on the esp partition (ZynqMP only)

Versal cards are already bootable after step 3 — skip this step. On ZynqMP:

```
sudo partprobe /dev/sdX
sudo mkdir -p /mnt/sd_esp
sudo mount /dev/sdX1 /mnt/sd_esp
sudo cp Yocto/<TARGET>/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
sync
sudo umount /mnt/sd_esp && sudo rmdir /mnt/sd_esp
```

### 5. Eject and boot

Eject the card cleanly (`sudo eject /dev/sdX`) so pending writes flush. Insert it
into the board, set the boot-mode switches to SD (see
[Boot PetaLinux](../docs/source/petalinux.md) for the per-board switch settings),
power-cycle, and attach a UART terminal at 115200 8N1.

> On `uzev` the on-SOM eMMC enumerates as `mmcblk0` and the SD card as
> `mmcblk1`; the boot script's dynamic `root=` handles this (rootfs mounts on
> `mmcblk1p3`). On the stock ZynqMP boards the SD card is `mmcblk0` (rootfs on
> `mmcblk0p3`).

## Offline / faster builds

Place the absolute path to a directory containing an extracted AMD sstate-cache
mirror in `Yocto/offline.txt` — `configure-build.sh` auto-detects which
architecture subdirs exist under it and wires one `SSTATE_MIRRORS` entry per
arch (plus `SOURCE_MIRROR_URL` if a `downloads/` dir is present).

Expected layout under that path:

```
<sstate root>/
  aarch64/      (Zynq UltraScale+ and Versal Linux)
  microblaze/   (the PMU/PLM firmware multiconfig)
  downloads/    (optional — the source-mirror tarballs)
```

The sstate-cache and downloads archives are available behind login at the AMD
Embedded Design Tools download page under "sstate-cache & Downloads - 2025.2".

## Layout

```
Yocto/
  Makefile                  deprecated thin wrapper around ../build.sh
  README.md                 this file
  .gitignore                excludes per-target workspaces + local state
  offline.txt               (optional, gitignored) path to an extracted sstate mirror
  scripts/
    init-workspace.sh       repo init + sync
    configure-build.sh      sdtgen + gen-machineconf parse-sdt + apply BSP (+ overlay) + sstate
    build-image.sh          bitbake the image recipe
    package-output.sh       gather deploy artifacts into images/linux/
  bsp/
    <board>/                one per board (zcu102 is shared by hpc0 + hpc1,
                            zcu106 by hpc0 + hpc1)
      conf/local.conf.append   board overrides (hostname, kernel cmdline)
      meta-user/               Yocto layer: kernel cfg, system-user.dtsi, image bbappend
    port-configs/
      ports-0/, ports-0123/, ports-versal-0123/   per-target SFP28/XXV overlay layers
  <TARGET>/                 (gitignored) per-target workspace built by the runner
  logs/                     (gitignored) build logs
```

## Architectural notes

* **The four scripts are universal** — identical across all of our
  reference repos. The per-repo data (target list, `BD_NAME`, each target's
  template and optional port config) lives in `config/data.json`, which
  `build.py` reads at runtime — nothing is generated into this folder.

* **The MACHINE is generated from the XSA** by `gen-machineconf parse-sdt` (the
  flow AMD recommends; `parse-xsa` is deprecated). There is no pinned
  AMD-validated MACHINE and no per-target flow selection. The custom machine is
  named `${BD_NAME}-<target>` (i.e. `sfp-<target>`); `configure-build.sh`
  takes `BD_NAME` as an argument so the script stays repo-agnostic.

* **The bitstream lives in BOOT.BIN**, not loaded at runtime via FPGA manager.
  Because no PL overlay is requested, the bitstream `sdtgen` extracted from the
  XSA is embedded into `BOOT.BIN` and the FSBL/PLM programs the PL during boot.

* **`system-user.dtsi` and `port-config.dtsi` are scoped to the Linux device
  tree** (via a guard on `CONFIG_DTFILE`). The FSBL/PMU/PLM domain device-trees
  don't define the SoC peripheral / `xxv_ethernet` labels the overrides
  reference, so including them there makes `dtc` fail with "Label or path …
  not found".

* **Adding a target**: set `"yocto": true` for the design in `config/data.json`
  and run `config/update.py` (regenerates the README table), then create
  `bsp/<board>/` following an existing board (start from `zcu102` for a stock
  AMD ZynqMP board, `vck190` for a stock Versal board, or `uzev` for a board
  needing a rich `system-user.dtsi`). If the target uses a port count or label
  scheme not already covered, add a `bsp/port-configs/<ports-…>/` overlay.
```
