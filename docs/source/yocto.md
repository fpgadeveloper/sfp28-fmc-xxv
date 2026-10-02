# Yocto

The Yocto / EDF flow (AMD's Embedded Development Framework) is the announced successor to
PetaLinux. It can be built for the Quad SFP28 FMC (XXV Ethernet) reference designs with the
cross-platform `build.py` runner at the root of the repository, and produces a Linux image that
exercises the SFP28 ports in the same way as the PetaLinux image.

```{note}
For 2025.2 both the PetaLinux and Yocto flows are supported and produce an equivalent
image. From the next tool version onward, the PetaLinux flow for this repository will be retired
and Yocto will be the only supported flow.
```

The Yocto flow is supported for all of the Zynq UltraScale+ and Versal targets (the same set that
has PetaLinux support).

## Requirements

To build the Yocto projects you will need:

* A physical or virtual machine running one of the [supported Linux distributions].
* Vivado 2025.2 (to build the XSA) and Vitis 2025.2 — the flow uses `xsct`/`sdtgen`, which ship
  with Vitis, to generate a System Device Tree from the Vivado XSA. The build runner finds and
  sources both tools itself.
* [Google's repo tool](https://gerrit.googlesource.com/git-repo/) on your `PATH`.
* The Yocto host packages. On Ubuntu 22.04 / 24.04:
  ```
  sudo apt-get install repo gawk wget git diffstat unzip texinfo gcc \
      build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
      xz-utils debianutils iputils-ping python3-git python3-jinja2 \
      python3-subunit zstd liblz4-tool file locales libacl1 bmap-tools
  ```
* A valid [10G/25G Ethernet MAC/PCS license](https://www.xilinx.com/products/intellectual-property/ef-di-25gemac.html)
  for the XXV Ethernet IP, to build the XSA (see [Licenses](requirements.md#licenses)).
* Disk space: a Yocto workspace takes several tens of GB per target.

```{attention}
You cannot build the Yocto projects in the Windows operating system. Windows users
are advised to use a Linux virtual machine to build the Yocto projects.
```

## How to build

1. From a command terminal, clone the Git repository and `cd` into it:
   ```
   git clone https://github.com/fpgadeveloper/sfp28-fmc-xxv.git
   cd sfp28-fmc-xxv
   ```
2. Build the Yocto image for your target by running the following command, replacing
   `<target>` with one of the target design labels listed in the
   [build instructions](build_instructions.md#target-designs):
   ```
   ./build.sh yocto --target <target>
   ```

This command launches the corresponding Vivado build if that project has not already been
built and its hardware exported. The first build of a target downloads several GB of sources
(`repo sync`) and runs bitbake from scratch, so it takes a while; subsequent builds are
incremental. To also gather the boot files into a zip under `bootimages/`, run
`./build.sh all --target <target>` (or `./build.sh package --target <target>` after the build).

The build:

1. generates a System Device Tree from the XSA and creates a Yocto machine
   (`MACHINE = "sfp-<target>"`) from it, so the PS configuration and the XXV Ethernet, AXI DMA,
   AXI IIC and AXI GPIO cores of the design are described automatically;
2. layers the board BSP `Yocto/bsp/<board>/` (kernel configuration, kernel patch, device-tree
   additions, hostname, kernel arguments, extra packages) and the port configuration
   `Yocto/bsp/port-configs/<ports-*>/` (the SFP28 cage wiring) on top;
3. runs `bitbake edf-linux-disk-image`. The bitstream is included in `BOOT.BIN` and is loaded at
   boot.

See `Yocto/README.md` in the repository for a detailed description of the flow.

### Offline / faster builds

If you have downloaded the AMD sstate-cache mirror ("sstate-cache & Downloads - 2025.2" on the
AMD Embedded Design Tools download page), put the absolute path of the extracted mirror in the
file `Yocto/offline.txt`. The build then uses the mirror for the `aarch64` and `microblaze`
sstate (and `downloads/` as a source mirror, if present).

### Output products

The output products are gathered into `Yocto/<target>/images/linux/`:

| File | Description |
| --- | --- |
| `BOOT.BIN` | Boot image (FSBL/PMU firmware or PLM + bitstream + U-Boot) |
| `boot.scr` | U-Boot boot script (Zynq UltraScale+ only; Versal boots Linux through systemd-boot) |
| `Image` | Linux kernel |
| `system.dtb` | Linux device tree |
| `u-boot.elf` | U-Boot (also contained in `BOOT.BIN`) |
| `rootfs.wic.xz` | Full SD-card disk image — this is what you write to the SD card |
| `rootfs.wic.bmap` | Block map for `bmaptool` (fast writing) |
| `rootfs.tar.gz` | Root filesystem tarball |

The zip `bootimages/sfp28-fmc-xxv_<target>_yocto-2025-2.zip` contains `rootfs.wic.xz`,
`rootfs.wic.bmap`, `BOOT.BIN`, on Versal also `BOOTAA64.EFI`, and a `readme.txt` with the SD-card
steps below.

## Prepare the SD card

Unlike the PetaLinux flow (which produces separate boot files for a hand-partitioned card), the
Yocto flow produces a **full SD-card disk image** (`rootfs.wic.xz`) that already contains all
partitions. You write that image to the SD card's raw device, then copy the boot files onto the
first partition, because the image does not place them where the boot ROM looks for them:

* **All targets** — copy `BOOT.BIN` onto the first (FAT) partition. The image installs `BOOT.BIN`
  on an ext4 partition, which the boot ROM cannot read.
* **Versal** — also copy the systemd-boot EFI loader to `EFI/BOOT/BOOTAA64.EFI` on the first
  partition. The image ships an empty `EFI/BOOT/` folder; without the loader U-Boot stops at its
  prompt instead of booting Linux.

```{warning}
Writing an image to a raw block device cannot be undone. Be absolutely certain you have
identified the SD card's device node before running the commands below — if you use the wrong
device you risk destroying data on one of your hard drives.
```

1. Identify the SD card device. With the card **un**plugged, run `lsblk -o NAME,SIZE,RM,TYPE`,
   insert the card, and run it again. The new entry — typically `/dev/sdX`, with `RM=1`
   (removable) and a size matching your card — is your target. Replace `sdX` with that device,
   and `<target>` with your target label, below.
2. Unmount any partitions the desktop auto-mounted:
   ```
   for p in /dev/sdX?*; do sudo umount "$p" 2>/dev/null; done
   ```
3. Write the wic image to the raw device. With `bmaptool` (fast — only writes used blocks):
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
4. Copy `BOOT.BIN` onto the first partition (all targets):
   ```
   sudo partprobe /dev/sdX
   sudo mkdir -p /mnt/sd_esp
   sudo mount /dev/sdX1 /mnt/sd_esp
   sudo cp Yocto/<target>/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
   ```
5. **Versal only:** install the systemd-boot loader on the same partition. Use the
   `BOOTAA64.EFI` from the boot-image zip, or extract it from the root filesystem tarball:
   ```
   tar -xzf Yocto/<target>/images/linux/rootfs.tar.gz --wildcards -O \
       '*usr/lib/systemd/boot/efi/systemd-bootaa64.efi' > BOOTAA64.EFI
   sudo mkdir -p /mnt/sd_esp/EFI/BOOT
   sudo cp BOOTAA64.EFI /mnt/sd_esp/EFI/BOOT/BOOTAA64.EFI
   ```
6. Unmount and eject the card cleanly so pending writes flush:
   ```
   sync
   sudo umount /mnt/sd_esp && sudo rmdir /mnt/sd_esp
   sudo eject /dev/sdX
   ```

## Boot

1. Plug the SD card into the target board and set it to boot from SD. The boot-mode DIP-switch
   settings are the same regardless of the Linux flow — see the per-board switch settings under
   [Boot PetaLinux](petalinux.md#boot-petalinux), and the board's user guide.
2. Connect the [Quad SFP28 FMC] to the FMC connector that your target was built for (for example
   HPC0 for `zcu106_hpc0`) and plug SFP+/SFP28 modules into the cages you want to use.
3. Connect the USB-UART to your PC and open a terminal emulator at 115200 baud (8N1) — see
   [UART terminal](petalinux.md#uart-terminal).
4. Optionally, connect the board's own Ethernet port (RJ45) to your network, for SSH access.
5. Connect and power your hardware.

### What to expect on the console

On a **Zynq UltraScale+** board the FSBL, U-Boot and the EDF boot script run, and Linux mounts its
root filesystem from partition 3 of the SD card. Excerpts from a `zcu104` boot:

```none
Zynq MP First Stage Boot Loader
Release 2025.2   ...
U-Boot 2025.01-...
Bootmode: LVL_SHFT_SD_MODE1
...
Scanning mmc 0:2...
Found U-Boot script /boot.scr
...
[    0.000000] Kernel command line: earlycon console=ttyPS0,115200 clk_ignore_unused init_fatal_sh=1 root=/dev/mmcblk0p3 ro rootwait uio_pdrv_genirq.of_id=generic-uio cma=1536M
...
[    2.224768] si5324 6-0068: si5328 probed
[    2.295101] si5324 6-0068: si5328 probe successful
[    2.355329] sfp sfp-eth0: Host maximum power 2.0W
[    2.360048] sfp sfp-eth0: No tx_disable pin: SFP modules will always be emitting.
[    2.676310] sfp sfp-eth0: module OEM              SFP-10G-T        rev 02   sn ...
[    4.619143] systemd[1]: Hostname set to <zcu104-sfp-2025-2>.
...
AMD Embedded Development Framework Linux distribution 25.11.1+release-... zcu104-sfp-2025-2 ttyPS0

zcu104-sfp-2025-2 login:
```

On a **Versal** board the PLM loads the boot image, U-Boot first enables the FMC VADJ supply
(on the VCK190, VMK180, VPK120 and VPK180, the line `Setting bus to 1` below), then loads
systemd-boot from the first partition, which starts Linux. Excerpts from a `vck190_fmcp1` boot:

```none
U-Boot 2025.01-...
Bootmode: LVL_SHFT_SD_MODE1
...
Hit any key to stop autoboot:  0
Setting bus to 1
...
Scanning mmc 0:1...
Booting: mmc 0
     EDF Xen       EDF Linux                         Boot in 5 s.
EFI stub: Exiting boot services...
[    0.000000] Kernel command line: console=ttyAMA0 earlycon=pl011,mmio32,0xFF000000,115200n8 root=PARTUUID=... ro rootwait uio_pdrv_genirq.of_id=generic-uio clk_ignore_unused cma=1536M
...
[    4.537238] si5324 7-0068: si5328 probed
[    4.602219] si5324 7-0068: si5328 probe successful
[    5.298158] sfp sfp-eth0: Host maximum power 2.0W
...
[    5.683256] sfp sfp-eth0: module OEM              SFP-10G-T        rev 02   sn ...
[    6.170796] systemd[1]: Hostname set to <vck190-sfp-2025-2>.
...
vck190-sfp-2025-2 login:
```

### Log in

Log in on the console as **`amd-edf`**. On the first login you are asked to choose a new
password immediately (there is no password to enter beforehand):

```none
zcu104-sfp-2025-2 login: amd-edf
You are required to change your password immediately (administrator enforced).
New password:
Retype new password:
```

The `amd-edf` user can run commands as root with `sudo` (it asks for that password). The image
includes an SSH server, so once the board's own Ethernet port has an address you can also log
in over the network: `ssh amd-edf@<board-ip>`.

### Image settings

| Setting | Value |
|---------|-------|
| Hostname | `<board>-sfp-2025-2` (for example `zcu106-sfp-2025-2`, `vck190-sfp-2025-2`) |
| User | `amd-edf` (password set at first login) |
| Extra kernel arguments | Zynq UltraScale+: `cma=1536M` (`uzev`: `cma=1000M`); Versal: `clk_ignore_unused cma=1536M` |
| Root filesystem | partition 3 of the SD card (`/dev/mmcblk0p3`; `/dev/mmcblk1p3` on `uzev`) |
| Network | every Ethernet interface requests an address over DHCP at boot |
| Extra packages | `ethtool`, `iperf3`, `phytool`, `pciutils`, `mtd-utils`, `can-utils`, `nfs-utils` |

The extra kernel arguments are set by `BSP_EXTRA_BOOTARGS` and the hostname by
`hostname:pn-base-files:forcevariable` in `Yocto/bsp/<board>/conf/local.conf.append`. The board
Ethernet port has a fixed MAC address (`local-mac-address` in
`Yocto/bsp/<board>/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`); change it if you
run more than one board of the same type on your network.

## Network interface names

The image uses systemd's predictable interface names. The SFP28 ports (driver `xilinx_axienet`)
and the board's own Ethernet port (driver `macb`) are named as follows:

| Targets | SFP28 port 0 | SFP28 port 1 | SFP28 port 2 | SFP28 port 3 | Board RJ45 |
|---------|--------------|--------------|--------------|--------------|------------|
| 1-port Zynq UltraScale+ (`zcu104`, `zcu106_hpc1`) | `end0` | — | — | — | `end1` |
| 4-port Zynq UltraScale+ (`uzev`, `zcu102_*`, `zcu106_hpc0`, `zcu111`, `zcu208`, `zcu216`) | `end0` | `eth1` | `eth2` | `eth3` | `end1` |
| Versal (all) | `end0` | `end1` | `end2` | `end3` | `end4` (and `end5` on boards with a second GEM) |

On the 4-port Zynq UltraScale+ targets, ports 1 to 3 keep their kernel names `eth1` to `eth3`
(they are not renamed by systemd); they work the same as the renamed ports. Interface names depend
on the order in which the kernel probes the devices, so if a name differs on your build, identify
the ports by driver and base address:

```none
zcu106-sfp-2025-2:~$ ip -br link
end1             UP             00:0a:35:06:21:07 <BROADCAST,MULTICAST,UP,LOWER_UP>
eth1             DOWN           00:0a:35:00:00:02 <NO-CARRIER,BROADCAST,MULTICAST,UP>
eth2             DOWN           00:0a:35:00:00:03 <NO-CARRIER,BROADCAST,MULTICAST,UP>
eth3             DOWN           00:0a:35:00:00:04 <NO-CARRIER,BROADCAST,MULTICAST,UP>
end0             UP             00:0a:23:00:00:00 <BROADCAST,MULTICAST,UP,LOWER_UP>
zcu106-sfp-2025-2:~$ ls -l /sys/class/net/*/device
```

`xilinx_axienet <address>.ethernet` is an SFP28 port and `macb ff0e0000.ethernet` (Zynq
UltraScale+) or `macb ff0c0000.ethernet` (Versal) is the board's own port. The SFP28 ports appear
in port order of their base addresses: on `zcu106_hpc0` port 0 to 3 are at `0x80060000`,
`0x80070000`, `0x80080000` and `0x80090000`; on `vck190_fmcp1` at `0x80000000` to `0x80030000`.
The base addresses of your target are in `dmesg | grep xilinx_axienet`.

## Using and testing the SFP28 ports

Once Linux has booted and you have logged in:

1. Check that the SFP28 cages and the fitted modules are detected, and that every port came out
   of reset (there must be no `GT reset not complete` or `DMA reset timeout` lines):
   ```
   dmesg | grep -E 'sfp sfp-eth[0-9]'
   dmesg | grep -iE 'xilinx_axienet|GT reset|DMA reset'
   ```
2. Connect a port to a link partner running at the target's rate (see
   [Testing the SFP28 ports](testing)) and check the link:
   ```
   sudo ethtool end0
   ```
   A 10G link shows `Speed: 10000Mb/s` and `Link detected: yes`, and the kernel logs
   `xilinx_axienet 80060000.ethernet end0: Link is Up - 10Gbps/Full - flow control off`. With a
   10GBASE-T copper module, the module's PHY is also reported, for example
   `PHY [i2c:sfp-eth0:11] driver [Aquantia AQR113C]`.
3. The port requests an address over DHCP. To use a fixed address instead:
   ```
   sudo ip addr add 192.168.10.10/24 dev end0
   sudo ip link set end0 up
   ```
4. Ping the link partner and measure the throughput with `iperf3` — see
   [Testing the SFP28 ports](testing) for the commands and the results to expect.

The PetaLinux examples in [Example Usage](petalinux.md#example-usage) (`ifconfig`, `ip`,
`ethtool`, `ping`, `iperf3`) apply to the Yocto image as well; use the interface names from the
table above.

## Board support details

The board-specific parts of the Yocto flow live under `Yocto/bsp/`. The notable ones:

* **SFP28 cage wiring (`port-config.dtsi`).** The SFP28 cages and the parts on the FMC (Si5328
  clock generator, PCA9548 I2C mux, the modules) are not described by the XSA, so each target
  applies a port-config overlay that describes the Si5328 (programmed to 156.25 MHz) and wires
  each active cage to the kernel SFP framework: the I2C-mux channel, an `sff,sfp` cage node with
  its `MOD_ABS` GPIO, and the `sfp = <&...>` link on the XXV MAC node. Three overlays exist —
  `ports-0` (single-port Zynq UltraScale+: `zcu104`, `zcu106_hpc1`), `ports-0123` (four-port Zynq
  UltraScale+) and `ports-versal-0123` (four-port Versal).
* **Kernel configuration (`bsp.cfg`).** Enables the SFP framework (`CONFIG_SFP`,
  `CONFIG_MDIO_I2C`) so that empty cages stay down instead of flapping, and the PHY drivers used
  by 10GBASE-T copper SFP+ modules (`CONFIG_MARVELL_10G_PHY`, `CONFIG_AQUANTIA_PHY`,
  `CONFIG_BCM84881_PHY`, `CONFIG_MARVELL_88X2222_PHY`).
* **QPLL reset kernel patch (Zynq UltraScale+).** `0001-xxv-qpllreset-gpio.patch` lets the
  `xilinx_axienet` driver pulse the shared QPLL reset of the XXV IP once after the Si5328 has been
  programmed (see [QPLL reset](description.md#qpll-reset-zynq-ultrascale)). Versal does not need
  it.
* **Board Ethernet PHY (device tree).** The System Device Tree flow does not describe the TI
  DP83867 PHY of the board's Ethernet port, so `system-user.dtsi` describes it with its RGMII
  delay settings and gives the port a fixed MAC address.
* **FMC VADJ.** On the ZCU104, an FSBL patch (`zcu104_vadj_fsbl.patch`) makes the FSBL read the
  VADJ voltage from the FMC card's EEPROM and enable VADJ. On the VCK190, VMK180, VPK120 and
  VPK180, the U-Boot boot command programs and enables the VADJ regulator before booting Linux.
* **Machine generated from the XSA.** There is no pinned AMD machine; `gen-machineconf
  parse-sdt` derives the machine from each target's Vivado XSA, which is what lets third-party
  boards like the Avnet UltraZed-EV build with no AMD machine configuration.

[Quad SFP28 FMC]: https://docs.opsero.com/op081/datasheet/overview/
[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment
