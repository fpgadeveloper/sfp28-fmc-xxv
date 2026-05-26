# Advanced: project structure and customization

This section is intended for users who want to modify the reference
designs — adding IP to the block design, changing constraints, adding
packages or drivers to the PetaLinux project, and so on. It describes
how the repository is laid out, how the Make-driven build flow works,
how the PetaLinux BSPs are composed from layered fragments, and what
modifications have been added on top of the stock AMD BSPs.

The actual *build* instructions are in [build_instructions](build_instructions);
this section is about understanding the project well enough to modify
it.

## Repository layout

```
.
├── Makefile                   <- Top-level build entry point
├── README.md
├── config/                    <- Source-of-truth design metadata and auto-generation
│   ├── data.json
│   └── update.py
├── docs/                      <- This documentation (Sphinx + Read the Docs)
├── PetaLinux/
│   ├── Makefile               <- PetaLinux build orchestration
│   └── bsp/                   <- Per-board and per-port-config BSP fragments
│       ├── uzev/, vck190/, …  <-   board-specific overlays
│       └── ports-0/, ports-0123/, ports-versal-0123/   <- port-config overlays
└── Vivado/
    ├── Makefile               <- Vivado build orchestration
    ├── scripts/
    │   ├── build.tcl          <- Project creation + block design assembly
    │   └── xsa.tcl            <- Synthesis, implementation, XSA export
    └── src/
        ├── bd/
        │   ├── bd_zynqmp.tcl  <- Block design for all ZynqMP targets
        │   └── bd_versal.tcl  <- Block design for all Versal targets
        └── constraints/
            └── <target>.xdc   <- One XDC per target (pin assignments, timing)
```

Per-target build outputs are written to `Vivado/<target>/` and
`PetaLinux/<target>/`; packaged boot-image zips are written to
`bootimages/`. None of these are committed.

## Target naming

A `TARGET` is the canonical handle for a single design and is the only
parameter passed through the build flow. It encodes the board, the FMC
connector (where the board has more than one), and the line rate where
ambiguous:

```
<board>[_<connector>][_25g]
```

Examples: `uzev`, `vck190_fmcp1`, `zcu102_hpc0`, `vpk120_25g`. The
absence of a `_25g` suffix means 10G. The first underscore-delimited
token is taken as the *target board* and is what `PetaLinux/Makefile`
uses to select the BSP under `PetaLinux/bsp/<board>/`.

The complete list of valid targets is in the `UPDATER START` block of
each Makefile and is generated from `config/data.json` (see below).

## `config/data.json` and `config/update.py`

`config/data.json` is the canonical source of truth for the set of
supported designs and their per-target metadata (board name, board URL,
line rate, FMC connector, GT lane mapping, etc.). `config/update.py`
reads `data.json` and regenerates the auto-managed sections of the
three Makefiles, the top-level `README.md`, and `.gitignore` — the
sections delimited by `UPDATER START` / `UPDATER END` comment markers.

When adding or modifying a target, edit `data.json` and re-run
`update.py`. Do not hand-edit content between the `UPDATER START` /
`UPDATER END` markers; it will be overwritten on the next regeneration.

## Make-driven build flow

There are three Makefiles in the repository, each scoped to a stage of
the build:

| Makefile               | Scope                                                                                  |
|------------------------|----------------------------------------------------------------------------------------|
| `./Makefile`           | Top-level orchestration; assembles boot-image zips for one or all targets.             |
| `./Vivado/Makefile`    | Creates the Vivado project, runs synthesis and implementation, exports the XSA.        |
| `./PetaLinux/Makefile` | Creates the PetaLinux project from the XSA, applies BSP overlays, builds, packages.    |

A `make bootimage TARGET=<t>` invocation at the top level cascades:

```
make bootimage TARGET=t
  -> ensures PetaLinux build output exists
       PetaLinux/Makefile petalinux TARGET=t
         -> ensures Vivado XSA exists
              Vivado/Makefile xsa TARGET=t
                -> vivado -mode batch -source scripts/build.tcl   (creates project)
                -> vivado -mode batch -source scripts/xsa.tcl     (synth, impl, XSA export)
         -> petalinux-create --template <zynqMP|versal> --name t
         -> petalinux-config --get-hw-description <XSA>
         -> copy bsp/<board>/project-spec/* into the project
         -> copy bsp/<port-config>/project-spec/* into the project   (overlay)
         -> petalinux-config --silentconfig
         -> petalinux-build
         -> petalinux-package boot ...
  -> zip the resulting boot files into bootimages/
```

The dependency chain means a clean `make bootimage TARGET=t` from
scratch will perform every step in order. Re-running after an
intermediate step has succeeded will pick up where the previous run
left off, because every step's output is declared as a Make
prerequisite of the next.

Per-target lock files (`.<target>.lock` in each Makefile's directory)
prevent two concurrent builds of the same target from clobbering each
other.

## Vivado side

### Block design

There is one block-design TCL per processor family:

* `Vivado/src/bd/bd_zynqmp.tcl` — used by all ZynqMP targets.
* `Vivado/src/bd/bd_versal.tcl` — used by all Versal targets.

Each script is parameterised by the target name (selected via
`config/data.json`'s `lanes` and `linkspeed` fields), and contains
per-board conditional blocks (`if {$is_vpk120 || $is_vpk180}` etc.)
where a target needs to deviate from the family defaults — typically
for clock-source selection, PS configuration, or GT-quad placement.

After sourcing the BD script, `scripts/build.tcl` runs
`validate_bd_design -force`, which triggers parameter propagation and
fills in connection automation rules. As a result the final
implemented design may contain nets that aren't visible in the BD TCL
source — to see the actual netlist as built, inspect the saved `.bd`
file under `Vivado/<target>/<target>.srcs/sources_1/bd/<bd_name>/` or
use `write_bd_tcl` to export a complete script from an open project.

### Constraints

`Vivado/src/constraints/<target>.xdc` contains pin assignments and any
target-specific timing constraints. Constraints common to all targets
of a given family are not factored out — each target's XDC is
self-contained.

### Build scripts

* `Vivado/scripts/build.tcl` creates the Vivado project, adds the
  target's XDC, sources the appropriate `bd_*.tcl`, and validates the
  block design. Invoked via `make project TARGET=<t>`.
* `Vivado/scripts/xsa.tcl` opens the existing project, runs synthesis
  and implementation, exports the XSA, and writes the bitstream into
  the implementation run directory. Invoked via
  `make xsa TARGET=<t>`.

Both scripts check `XILINX_VIVADO` to confirm the installed Vivado
version matches the `version_required` constant at the top of the
file. Bumping a project to a new Vivado release means changing those
constants and re-testing — the BD TCL APIs are not stable across major
releases.

### Modifying the block design

Edit the block-design script for the appropriate processor family
directly:

* `Vivado/src/bd/bd_zynqmp.tcl` for ZynqMP targets, or
* `Vivado/src/bd/bd_versal.tcl` for Versal targets.

If the change applies only to some targets in the family, wrap
the additions in the appropriate per-board conditional block (for
example `if {$is_vpk120 || $is_vpk180} { … }`).

```{note} On Versal (GTY/GTYP), `bd_versal.tcl` explicitly forces
`TX_PLL_TYPE` / `RX_PLL_TYPE` to `RPLL` on the GT_Quad PROT0_LR0
settings. Vivado 2025.2's GT_Quad IP auto-selects `LCPLL` for the
10G/25G Ethernet preset, which prevents block lock on these designs;
if you regenerate the GT_Quad customisation or copy presets from
another design, make sure the PLL type stays at `RPLL`. The ZynqMP
GTH XXV-Ethernet IP uses the shared QPLL and has no equivalent
choice in the BD.
```

Once the script is edited, delete any existing per-target Vivado
project directory (`rm -rf Vivado/<target>`) and re-run the Vivado
build through the Makefile:

```
cd Vivado
make xsa TARGET=<target>
```

This re-creates the project, sources the modified BD script, runs
`validate_bd_design`, synthesises, implements, and re-exports the XSA.
Downstream PetaLinux / boot-image steps will then pick up the new XSA
on the next `make` at the top level.

### Adding or modifying constraints

Edit `Vivado/src/constraints/<target>.xdc` directly. If a constraint
applies to all targets in a family, it still needs to be replicated to
each target's XDC — there is no shared XDC.

## PetaLinux side

### BSP composition

The PetaLinux project for a given target is composed at build time
from two BSP fragments copied into the target's project directory:

1. A **board BSP** at `PetaLinux/bsp/<board>/` (for example `uzev/`,
   `vck190/`, `zcu102/`). Provides board-specific kernel and U-Boot
   configuration, the system device-tree fragment for the board, and
   any board-specific patches.
2. A **port-config overlay** at `PetaLinux/bsp/<port-config>/` (one
   of `ports-0/`, `ports-0123/`, or `ports-versal-0123/`). Provides
   `port-config.dtsi` — the device-tree fragment that wires up the SFP
   cages, the AXI Ethernet MAC nodes, and the SFP module-presence GPIOs
   for the FMC ports active on this target.

The mapping from target to (board BSP, port-config overlay) is encoded
in `PetaLinux/Makefile`'s `UPDATER` block:

```
vck190_fmcp1_target := versal 0 0 ports-versal-0123
zcu102_hpc0_target  := zynqMP 0 0 ports-0123
zcu104_target       := zynqMP 0 0 ports-0
```

The first column is the PetaLinux template (`zynqMP` or `versal`); the
last is the port-config overlay name. The board BSP is derived from
the first token of the target name (`vck190`, `zcu102`, `zcu104`).

At build time both directories' `project-spec/` trees are copied into
the target's PetaLinux project, with the port-config overlay copied
*after* the board BSP so its files take precedence on collision (in
practice the two BSPs touch disjoint files, so this is academic).

### Layout of a board BSP

```
PetaLinux/bsp/<board>/project-spec/
├── configs/
│   ├── config                <- petalinux-config: bootargs, root filesystem, hostname
│   ├── rootfs_config         <- petalinux-config -c rootfs: included packages
│   ├── init-ifupdown/
│   │   └── interfaces        <- /etc/network/interfaces
│   └── busybox/
│       └── inetd.conf
└── meta-user/
    ├── conf/
    │   ├── user-rootfsconfig <- declares additional rootfs config options
    │   ├── petalinuxbsp.conf
    │   └── layer.conf
    └── recipes-bsp/
        ├── device-tree/
        │   ├── device-tree.bbappend
        │   └── files/
        │       └── system-user.dtsi      <- board-specific DT additions
        └── u-boot/
            ├── u-boot-xlnx_%.bbappend
            └── files/
                ├── bsp.cfg               <- U-Boot Kconfig additions
                ├── platform-top.h        <- U-Boot platform header overrides
                └── *.patch               <- U-Boot source patches
    └── recipes-kernel/
        └── linux/
            ├── linux-xlnx_%.bbappend
            └── linux-xlnx/
                ├── bsp.cfg               <- kernel Kconfig additions
                └── *.patch               <- kernel source patches
```

The board BSPs in this repository are derived from the corresponding
stock AMD reference BSPs, but with substantial additions — see
[Modifications layered on the stock BSPs](#modifications-layered-on-the-stock-bsps)
below.

### Layout of a port-config overlay

```
PetaLinux/bsp/<port-config>/project-spec/meta-user/recipes-bsp/device-tree/files/
└── port-config.dtsi
```

That is the entire overlay — a single device-tree fragment that is
included from `system-user.dtsi` (`/include/ "port-config.dtsi"`).
Three variants exist:

* `ports-0` — single-port designs (zcu104, zcu106_hpc1).
* `ports-0123` — four-port ZynqMP designs (uzev, zcu102_hpc0, etc.).
  Uses the ZynqMP label scheme `xxv_ethernet_0`, `xxv_ethernet_0_1`,
  `xxv_ethernet_0_2`, `xxv_ethernet_0_3` (one XXV-Ethernet IP with
  four channels).
* `ports-versal-0123` — four-port Versal designs. Uses the Versal
  label scheme `sfp_port0_xxv_ethernet` through
  `sfp_port3_xxv_ethernet` (one XXV-Ethernet IP per port).

The split exists because the SDT (system device-tree) generator
produces different label hierarchies for the two families, so a single
overlay can't reference both. See
`PetaLinux/bsp/ports-versal-0123/project-spec/meta-user/recipes-bsp/device-tree/files/port-config.dtsi`
for an annotated example.

### Adding a package to the root filesystem

1. Append the new option to `bsp/<board>/project-spec/configs/rootfs_config`:

   ```
   CONFIG_<package>=y
   ```

2. If the package is not in the default `petalinux-config -c rootfs`
   menu, also append a declaration line to
   `bsp/<board>/project-spec/meta-user/conf/user-rootfsconfig`:

   ```
   CONFIG_<package>
   ```

   This makes the option visible in the rootfs configuration menu and
   exposes it for `rootfs_config` to enable.

3. If the package is not provided by an existing meta-layer (i.e. it
   does not appear in `petalinux-config -c rootfs` even after the
   declaration), add it via a recipe under
   `bsp/<board>/project-spec/meta-user/recipes-apps/<package>/<package>.bb`.

### Adding a kernel config option

Append the option to `bsp/<board>/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:

```
CONFIG_<name>=y
```

The corresponding bbappend at
`recipes-kernel/linux/linux-xlnx_%.bbappend` is what causes `bsp.cfg`
to be picked up as a kernel configuration fragment
(`KERNEL_FEATURES:append = " bsp.cfg"`). Configs added to `bsp.cfg`
take effect on the next `petalinux-build`.

### Adding a device-tree fragment

If the fragment is per-board, edit
`bsp/<board>/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`.
The file is included verbatim into the final device tree.

If the fragment is per-port-config (i.e. it relates to the SFP cages
or the AXI Ethernet ports), edit the corresponding
`bsp/<port-config>/project-spec/meta-user/recipes-bsp/device-tree/files/port-config.dtsi`.

If you add new files, ensure they are listed in `SRC_URI:append` in
`device-tree.bbappend`.

### Adding a kernel patch or out-of-tree driver

1. Drop the patch file into
   `bsp/<board>/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/`.
2. Add a line to `recipes-kernel/linux/linux-xlnx_%.bbappend`:

   ```
   SRC_URI:append = " file://<your-patch>.patch"
   ```

3. Re-run the build. The patch is applied during the kernel
   `do_patch` task.

The existing
`PetaLinux/bsp/uzev/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/0001-xxv-qpllreset-gpio.patch`
is a working example.

### Modifying U-Boot

The same pattern as the kernel, under
`bsp/<board>/project-spec/meta-user/recipes-bsp/u-boot/`. `bsp.cfg`
adds U-Boot Kconfig options; `platform-top.h` overrides the U-Boot
platform header; patches are listed in `SRC_URI:append` in
`u-boot-xlnx_%.bbappend`.

## Modifications layered on the stock BSPs

The board BSPs in this repository started as the corresponding stock
AMD reference BSPs and have been modified in the following ways. This
list is the answer to *"what would I lose if I overwrote the BSP with
the stock one?"* — it is what to re-apply if you ever do that.

### All BSPs

* **Root filesystem additions** in `configs/rootfs_config`:
  `ethtool`, `iperf3`, `phytool` (and on ZynqMP, additionally
  `ethtool-dev`, `ethtool-dbg`).
* **Hostname / product name** set in `configs/config` via
  `CONFIG_SUBSYSTEM_HOSTNAME` and `CONFIG_SUBSYSTEM_PRODUCT`.
* **`system-user.dtsi`** includes `port-config.dtsi`. The matching
  `device-tree.bbappend` adds both files to `SRC_URI:append`.
* **Kernel configs** in `linux-xlnx/bsp.cfg`:
  `CONFIG_AMD_PHY`, `CONFIG_XILINX_PHY`, plus the SFP framework
  (`CONFIG_SFP`, `CONFIG_MDIO_I2C`) and PHY drivers for 10G copper
  SFP modules (`CONFIG_AQUANTIA_PHY`, `CONFIG_MARVELL_10G_PHY`,
  `CONFIG_BCM84881_PHY`, `CONFIG_MARVELL_88X2222_PHY`). Without the
  SFP framework, `phylink` ignores the `sfp = <&...>` properties in
  `port-config.dtsi` and falls back to in-band-status; without the PHY
  drivers, 10GBASE-T copper SFP modules fail `phylink` validation.

### ZynqMP BSPs

* **SD-card root filesystem** configured in `configs/config`:
  `CONFIG_SUBSYSTEM_ROOTFS_EXT4`, `CONFIG_SUBSYSTEM_SDROOT_DEV`,
  `CONFIG_SUBSYSTEM_USER_CMDLINE` (with `cma=1536M` for the AXI DMA
  buffers).
* **Kernel patch `0001-xxv-qpllreset-gpio.patch`** in
  `linux-xlnx/`, registered via `SRC_URI:append` in the bbappend.
  Patches the `xilinx_axienet` driver to pulse an optional GPIO
  connected to the XXV-Ethernet IP's `qpllreset_in_0` port during
  `axienet_device_reset()`, so the GTH QPLL re-locks after the Si5328
  reference clock is reprogrammed during Linux boot. The GPIO is
  named in the device tree via the `qpllreset-gpios` property on each
  `xxv_ethernet_*` node in `bsp/ports-0*/port-config.dtsi`.
* **DMA-engine kernel configs**: `CONFIG_XILINX_DMA_ENGINES`,
  `CONFIG_XILINX_DPDMA`, `CONFIG_XILINX_ZYNQMP_DMA`.
* **U-Boot patch `0001-ubifs-distroboot-support.patch`** in
  `u-boot/files/`, registered via `SRC_URI:append` in the bbappend.
  Adds UBIFS distroboot fallback to the ZynqMP U-Boot bootcmd.

### ZCU104 BSP (additional)

* **FSBL patch `zcu104_vadj_fsbl.patch`** in
  `recipes-bsp/embeddedsw/files/`, staged into the
  `xlnx-embeddedsw` recipe by
  `fsbl-firmware_%.bbappend`. The patch fixes the FSBL's FMC VADJ
  autodetect on the ZCU104: the stock 2025.2 FSBL reads from the
  carrier-board EEPROM (I2C addr `0x54`) instead of the FMC EEPROM
  (`0x50`), selects the wrong MUX channel, and reads only 32 bytes,
  which is too few to reach the VADJ voltage record. Without this
  patch VADJ is never programmed on the ZCU104 and the Quad SFP28 FMC
  does not power up cleanly. The bbappend uses `apply=no` and inserts
  a manual `do_apply_vadj_patch` task between `do_copy_shared_src`
  and `do_configure` — this is necessary because 2025.2's
  `xlnx-embeddedsw.bbclass` runs `do_patch` *before*
  `do_copy_shared_src`, so SRC_URI-attached patches would otherwise
  be applied to an empty workdir.

### UltraZed-EV (uzev) BSP

* **`CONFIG_YOCTO_MACHINE_NAME="zynqmp-generic"`** in `configs/config`
  (the UZ-EV is not a stock Xilinx eval board).
* **SD-card device set to `/dev/mmcblk1p2`** rather than the ZynqMP
  default `mmcblk0p2`.
* **`PRIMARY_SD_PSU_SD_1_SELECT=y`** to route the boot SD interface
  through PSU SD1 instead of SD0.
* **Custom `system-user.dtsi`** with UZ-EV-specific peripheral
  configuration (overwrites the file copied in from a stock UZ-EV BSP).

### Versal BSPs (vck190, vmk180, vpk120, vpk180, vhk158, vek280)

* **`meta-xilinx-tools/recipes-bsp/uboot-device-tree/`** overlay that
  overrides the U-Boot device tree (`uboot-device-tree.bbappend` +
  `system-user.dtsi`). This is required because the stock U-Boot
  device tree does not describe the SFP-side AXI Ethernet ports.
* **U-Boot patch `0001-xilinx_versal.h-ubifs-distroboot-support.patch`**.
* **No `qpllreset-gpios` patch** — the Versal GTY/CPM5 transceiver
  doesn't have the same QPLL re-lock issue as the ZynqMP GTH. The
  port-config overlay used by Versal targets
  (`bsp/ports-versal-0123/`) correspondingly omits the
  `qpllreset-gpios` property and instead uses an input-only AXI GPIO
  for the four MOD_ABS lines.

### Port-config overlays

The three overlays in `PetaLinux/bsp/ports-*/` are not derived from
any stock BSP — they exist solely to add the device-tree fragment
that wires up the SFP cages. They contain a single `port-config.dtsi`
file (and the directory structure needed to make Yocto pick it up via
`device-tree.bbappend` in the board BSP, which has the
`SRC_URI:append = " file://port-config.dtsi"` line).

## Where build outputs land

| Path                                | Contents                                                  |
|-------------------------------------|-----------------------------------------------------------|
| `Vivado/<target>/`                  | Vivado project. `<bd_name>_wrapper.xsa` is the export.    |
| `Vivado/<target>/<target>.runs/impl_1/<bd_name>_wrapper.bit` | Bitstream.                          |
| `Vivado/logs/`                      | Per-target Vivado build logs (xpr + xsa).                 |
| `PetaLinux/<target>/`               | PetaLinux project. All Yocto build state lives here.      |
| `PetaLinux/<target>/images/linux/`  | `BOOT.BIN`, `image.ub`, `boot.scr`, `rootfs.tar.gz`, etc. |
| `PetaLinux/<target>/build/build.log`| PetaLinux build log.                                      |
| `bootimages/`                       | Per-target zipped boot files (`<prj>_<target>_petalinux-<ver>.zip` and `<prj>_<target>_standalone-<ver>.zip`). |

None of these directories are committed to the repository.
