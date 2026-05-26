# PetaLinux

PetaLinux can be built for these reference designs by using the Makefile in the `PetaLinux` directory
of the repository.

## Requirements

To build the PetaLinux projects, you will need a physical or virtual machine running one of the 
[supported Linux distributions] with Vivado 2025.2 and PetaLinux Tools 2025.2 installed.

```{attention} You cannot build the PetaLinux projects in the Windows operating system. Windows
users are advised to use a Linux virtual machine to build the PetaLinux projects.
```

## How to build

1. From a command terminal, clone the Git repository and `cd` into it.
   ```
   git clone https://github.com/fpgadeveloper/sfp28-fmc-xxv.git
   cd sfp28-fmc-xxv
   ```
2. Launch PetaLinux by sourcing the `settings.sh` bash script, eg:
   ```
   source <path-to-petalinux-install>/2025.2/settings.sh
   ```
3. Launch Vivado by sourcing the `settings64.sh` bash script, eg:
   ```
   source <path-to-xilinx-tools>/2025.2/Vivado/settings64.sh
   ```
4. Build the Vivado and PetaLinux project for your specific target platform by running the following
   commands and replacing `<target>` with one of the target design labels listed in build instructions.
   ```
   cd PetaLinux
   make petalinux TARGET=<target>
   ```
   
The last command will launch the build process for the corresponding Vivado project if that project
has not already been built and it's hardware exported.

## Boot from SD card

### Prepare the SD card

Once the build process is complete, you must prepare the SD card for booting PetaLinux.

1. The SD card must first be prepared with two partitions: one for the boot files and another 
   for the root file system.

   * Plug the SD card into your computer and find it's device name using the `dmesg` command.
     The SD card should be found at the end of the log, and it's device name should be something
     like `/dev/sdX`, where `X` is a letter such as a,b,c,d, etc. Note that you should replace
     the `X` in the following instructions.
     
```{warning} Do not continue these steps until you are certain that you have found the correct
device name for the SD card. If you use the wrong device name in the following steps, you risk
losing data on one of your hard drives.
```
   * Run `fdisk` by typing the command `sudo fdisk /dev/sdX`
   * Make the `boot` partition: typing `n` to create a new partition, then type `p` to make 
     it primary, then use the default partition number and first sector. For the last sector, type 
     `+1G` to allocate 1GB to this partition.
   * Make the `boot` partition bootable by typing `a`
   * Make the `root` partition: typing `n` to create a new partition, then type `p` to make 
     it primary, then use the default partition number, first sector and last sector.
   * Save the partition table by typing `w`
   * Format the `boot` partition (FAT32) by typing `sudo mkfs.vfat -F 32 -n boot /dev/sdX1`
   * Format the `root` partition (ext4) by typing `sudo mkfs.ext4 -L root /dev/sdX2`

2. Copy the following files to the `boot` partition of the SD card:
   Assuming the `boot` partition was mounted to `/media/user/boot`, follow these instructions:
   ```
   $ cd /media/user/boot/
   $ sudo cp /<petalinux-project>/images/linux/BOOT.BIN .
   $ sudo cp /<petalinux-project>/images/linux/boot.scr .
   $ sudo cp /<petalinux-project>/images/linux/image.ub .
   ```

3. Create the root file system by extracting the `rootfs.tar.gz` file to the `root` partition.
   Assuming the `root` partition was mounted to `/media/user/root`, follow these instructions:
   ```
   $ cd /media/user/root/
   $ sudo cp /<petalinux-project>/images/linux/rootfs.tar.gz .
   $ sudo tar xvf rootfs.tar.gz -C .
   $ sync
   ```
   
   Once the `sync` command returns, you will be able to eject the SD card from the machine.

### Boot PetaLinux

1. Plug the SD card into your target board.
2. Ensure that the target board is configured to boot from SD card:
   * **VCK190, VMK180, VEK280, VPK120:** DIP switch SW1 is set to 1000 (1=ON,2=OFF,3=OFF,4=OFF)
   * **UltraZed-EV:** DIP switch SW2 (on the SoM) is set to 1000 (1=ON,2=OFF,3=OFF,4=OFF)
   * **ZCU102, ZCU104, ZCU106, ZCU111:** DIP switch SW6 must be set to 1000 (1=ON,2=OFF,3=OFF,4=OFF)
   * **ZCU208, ZCU216:** DIP switch SW2 must be set to 1000 (1=ON,2=OFF,3=OFF,4=OFF)
3. Connect the [Quad SFP28 FMC] to the FMC connector of the target board.
4. Connect the USB-UART to your PC and then open a UART terminal set to 115200 baud and the 
   comport that corresponds to your target board.
5. Connect and power your hardware.

## Boot via JTAG

```{tip} You need to install the cable drivers before being able to boot via JTAG.
Note that the Vitis installer does not automatically install the cable drivers, it must be done separately.
For instructions, read section 
[installing the cable drivers](https://docs.amd.com/r/en-US/ug973-vivado-release-notes-install-license/Installing-Cable-Drivers) 
from the Vivado release notes.
```

```{warning} If you boot the Zynq-7000, Zynq UltraScale+ or Zynq RFSoC designs via JTAG, you must still
first prepare the SD card. The reason is because these designs are configured to use the SD card to store
the root filesystem. If you boot these designs via JTAG without preparing and connecting the SD card, the
boot will hang during at a message similar to this: `Waiting for root device /dev/mmcblk0p2...`
```

### Setup hardware

1. Prepare the SD card according to the [instructions above](#prepare-the-sd-card) and plug the SD card 
   into your target board.
2. Ensure that the target board is configured to boot from JTAG:
   * **VCK190, VMK180, VEK280, VPK120:** DIP switch SW1 is set to 1111 (1=ON,2=ON,3=ON,4=ON)
   * **UltraZed-EV:** DIP switch SW2 (on the SoM) is set to 1111 (1=ON,2=ON,3=ON,4=ON)
   * **ZCU102, ZCU104, ZCU106, ZCU111:** DIP switch SW6 must be set to 1111 (1=ON,2=ON,3=ON,4=ON)
   * **ZCU208, ZCU216:** DIP switch SW2 must be set to 1111 (1=ON,2=ON,3=ON,4=ON)
3. Connect the [Quad SFP28 FMC] to the FMC connector of the target board.
4. Connect the USB-UART to your PC and then open a UART terminal set to 115200 baud and the 
   comport that corresponds to your target board.
5. Connect and power your hardware.

### Boot PetaLinux

To boot PetaLinux on hardware via JTAG, use the following commands in a Linux command terminal:

1. Change current directory to the PetaLinux project directory for your target design:
   ```
   cd <project-dir>/PetaLinux/<target>
   ```
2. Download bitstream to the FPGA:
   ```
   petalinux-boot --jtag --kernel --fpga
   ```

An explanation of the above command is provided by the `petalinux-boot` command:
```none
For microblaze, it will download the bitstream to target board, and
then boot the kernel image on target board.
For Zynq, it will download the bitstream and FSBL to target board,
and then boot the u-boot and then the kernel on target
board.
For Zynq UltraScale+, it will download the bitstream, PMUFW and FSBL,
and then boot the kernel with help of linux-boot.elf to set kernel
start and dtb addresses.
```

## UART terminal

You will need to setup a terminal emulator to use the PetaLinux command line over the USB-UART connection.
Connect with a baud rate of 115200.

### In Windows

You will need to find the comport for the USB-UART in Windows Device Manager. As a terminal emulator, you
can use the open source and free [Putty](https://www.putty.org/).

### In Linux

In Linux, you can find the USB-UART device by running `dmesg | grep tty`. Typically, the device will be
`/dev/ttyUSB0` or it could be followed by a different number. To open a terminal emulator, you can use
the following command:

```
sudo screen /dev/ttyUSB0 115200
```

## Port configurations

The PetaLinux image uses persistent interface names with the `endN` prefix
(the kernel initially registers each NIC as `ethN`, then udev renames it
on boot). Numbering depends on the order the kernel probes the network
devices, which is driven by the device tree, so it differs between
single-port and multi-port designs.

All interfaces are auto-configured for DHCP at boot, so plugging any of
them into a DHCP server (a router, or another PC handing out IPs over
the SFP link) is enough to get an address.

### Single-port ZynqMP designs (zcu104, zcu106_hpc1)

One `xxv_ethernet` channel driving SFP port 0, plus the dev board's
built-in RJ45 (GEM):

| Interface | Driver         | Connector              |
|-----------|----------------|------------------------|
| `end0`    | macb           | Dev board's RJ45 (GEM) |
| `end1`    | xilinx_axienet | Quad SFP28 FMC port 0  |

### Four-port ZynqMP designs (uzev)

On the `uzev`, the four `xxv_ethernet` channels probe before the macb,
so the macb consumes the last `ethN` slot:

| Interface | Driver         | Connector              |
|-----------|----------------|------------------------|
| `end0`    | macb           | Dev board's RJ45 (GEM) |
| `end1`    | xilinx_axienet | Quad SFP28 FMC port 0  |
| `eth1`    | xilinx_axienet | Quad SFP28 FMC port 1  |
| `eth2`    | xilinx_axienet | Quad SFP28 FMC port 2  |
| `eth3`    | xilinx_axienet | Quad SFP28 FMC port 3  |

### Four-port ZynqMP designs (zcu102_hpc0, zcu106_hpc0, zcu111, zcu208, zcu216)

On the AMD ZCU* boards, the macb probes first (taking `eth0`) and the
SFP28 channels follow, so the numbering for ports 1–3 is offset by one
compared to the `uzev`:

| Interface | Driver         | Connector              |
|-----------|----------------|------------------------|
| `end0`    | macb           | Dev board's RJ45 (GEM) |
| `end1`    | xilinx_axienet | Quad SFP28 FMC port 0  |
| `eth2`    | xilinx_axienet | Quad SFP28 FMC port 1  |
| `eth3`    | xilinx_axienet | Quad SFP28 FMC port 2  |
| `eth4`    | xilinx_axienet | Quad SFP28 FMC port 3  |

> **Note on the mixed `endN` / `ethN` names.** SFP port 0 (and the macb)
> have their MAC address assigned at netdev-creation time — port 0's
> comes from the SDT-generated `pl.dtsi` — and so they pick up the
> persistent `endN` rename. SFP ports 1–3 get their MACs later via the
> `port-config.dtsi` overlay, after the rename rule has already run, so
> they keep their kernel-default `ethN` names. The interfaces work
> identically; only the names differ. Which `ethN` numbers the
> non-renamed ports land on depends on the order the kernel probed
> the netdevs (driven by the device tree), which is why `uzev` differs
> from the AMD ZCU* boards above.

### Versal designs (vck190, vmk180, vpk120, vpk180, vhk158, vek280)

| Interface | Driver         | Connector                                              |
|-----------|----------------|--------------------------------------------------------|
| `end0`    | xilinx_axienet | Quad SFP28 FMC port 0                                  |
| `end1`    | xilinx_axienet | Quad SFP28 FMC port 1                                  |
| `end2`    | xilinx_axienet | Quad SFP28 FMC port 2                                  |
| `end3`    | xilinx_axienet | Quad SFP28 FMC port 3                                  |
| `end4`    | macb           | Dev-board built-in Ethernet (GEM0)                     |
| `end5`    | macb           | Dev-board built-in Ethernet (GEM1, where present)      |

### Identifying the mapping on a specific board

If the table above doesn't match what you see, you can work it out at
runtime. `ip -br link` lists the interfaces, and either `ethtool -i
<name>` or the kernel bring-up messages in `dmesg` will tell you which
driver is behind each one:

```sh
$ ip -br link
end0    DOWN    54:10:ec:ba:b8:7c <NO-CARRIER,BROADCAST,MULTICAST,UP>
end1    UP      00:0a:35:00:00:01 <BROADCAST,MULTICAST,UP,LOWER_UP>
eth2    DOWN    00:0a:35:00:00:02 <NO-CARRIER,BROADCAST,MULTICAST,UP>
eth3    DOWN    00:0a:35:00:00:03 <NO-CARRIER,BROADCAST,MULTICAST,UP>
eth4    DOWN    00:0a:35:00:00:04 <NO-CARRIER,BROADCAST,MULTICAST,UP>
lo      UNKNOWN 00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>

$ ethtool -i end1 | head -1
driver: xilinx_axienet      # -> Quad SFP28 FMC port

$ dmesg | grep -E 'renamed from|axienet.*(end|eth)[0-9]+:.*configuring|macb.*end[0-9]+:.*PHY'
```

`xilinx_axienet` always means an XXV-Ethernet (Quad SFP28 FMC) port;
`macb` is the dev board's built-in Ethernet (GEM).

## Example Usage

The examples below were captured on a `zcu102_hpc0` build with an SFP28 module
in Quad SFP28 FMC port 0, which is named `end1` on that board. Substitute your
own interface name (see the [Port configurations](#port-configurations)
section above for the mapping that applies to your design).

### List the network interfaces

Run `ifconfig` (or `ip addr`) with no arguments to see all interfaces and their
current state. The on-board Ethernet port appears as `end0` (or `eth0`,
depending on the design); each Quad SFP28 FMC port appears as a separate
interface with a `00:0a:35:00:00:0X` MAC address.

```
zcu102-sfp28-2025-2:~$ ifconfig
end0      Link encap:Ethernet  HWaddr 8A:DE:CC:88:57:66
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          ...

end1      Link encap:Ethernet  HWaddr 00:0A:35:00:00:01
          inet6 addr: fe80::20a:35ff:fe00:1/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          ...

eth2      Link encap:Ethernet  HWaddr 00:0A:35:00:00:02
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          ...

eth3      Link encap:Ethernet  HWaddr 00:0A:35:00:00:03
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          ...

eth4      Link encap:Ethernet  HWaddr 00:0A:35:00:00:04
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          ...

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          ...
```

### Bring up a port with a fixed IP address

Use `ip` (or `ifconfig`) to assign a static address and bring the port up.

```
zcu102-sfp28-2025-2:~$ sudo ip addr add 192.168.1.10/24 dev end1
zcu102-sfp28-2025-2:~$ sudo ip link set end1 up
[   42.118663] xilinx_axienet 80060000.ethernet end1: Link is Up - 10Gbps/Full - flow control off
```

Verify with `ifconfig end1`:

```
zcu102-sfp28-2025-2:~$ ifconfig end1
end1      Link encap:Ethernet  HWaddr 00:0A:35:00:00:01
          inet addr:192.168.1.10  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::20a:35ff:fe00:1/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
```

### Bring up a port using DHCP

Use `udhcpc` to lease an address from a DHCP server reachable on the link
(for example a router, or a host PC running NetworkManager in shared mode).

```
zcu102-sfp28-2025-2:~$ sudo udhcpc -i end1
udhcpc: started, v1.36.1
udhcpc: broadcasting discover
udhcpc: broadcasting select for 192.168.1.22, server 192.168.1.1
udhcpc: lease of 192.168.1.22 obtained from 192.168.1.1, lease time 3600
/etc/udhcpc.d/50default: Adding DNS 192.168.1.1
```

### Inspect port settings with ethtool

Use `ethtool` to query link state, speed, duplex, supported link modes and the
PHY/transceiver type for a port.

```
zcu102-sfp28-2025-2:~$ sudo ethtool end1
Settings for end1:
        Supported ports: [ MII ]
        Supported link modes:   10000baseT/Full
                                10000baseKX4/Full
                                10000baseKR/Full
                                10000baseR_FEC
                                10000baseCR/Full
                                10000baseSR/Full
                                10000baseLR/Full
                                10000baseLRM/Full
                                10000baseER/Full
        Supported pause frame use: Symmetric Receive-only
        Supports auto-negotiation: Yes
        Supported FEC modes: Not reported
        Advertised link modes:  10000baseT/Full
                                10000baseKX4/Full
                                10000baseKR/Full
                                10000baseR_FEC
                                10000baseCR/Full
                                10000baseSR/Full
                                10000baseLR/Full
                                10000baseLRM/Full
                                10000baseER/Full
        Advertised pause frame use: Symmetric Receive-only
        Advertised auto-negotiation: Yes
        Advertised FEC modes: Not reported
        Speed: 10000Mb/s
        Duplex: Full
        Auto-negotiation: on
        Port: MII
        PHYAD: 0
        Transceiver: internal
        Link detected: yes
```

`Link detected: yes` along with `Speed: 10000Mb/s` confirms the GTH transceiver
has acquired the link with the SFP28 module.

### Ping a link partner

With the port up and an address assigned, use `ping` to verify reachability of
a host on the same link. The `-I` option forces the ping to egress from the
specified interface.

```
zcu102-sfp28-2025-2:~$ ping -I end1 192.168.1.1
PING 192.168.1.1 (192.168.1.1) from 192.168.1.22 end1: 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=0.180 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=64 time=0.151 ms
64 bytes from 192.168.1.1: icmp_seq=3 ttl=64 time=0.144 ms
64 bytes from 192.168.1.1: icmp_seq=4 ttl=64 time=0.146 ms
^C
--- 192.168.1.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3052ms
rtt min/avg/max/mdev = 0.144/0.155/0.180/0.014 ms
```

### Throughput test with iperf3

`iperf3` is the standard tool for measuring TCP/UDP throughput over a link.
Run it as a server on one end and a client on the other; data flows from
client to server by default (use `-R` to reverse).

In the examples below the host PC acts as the iperf3 server and the
PetaLinux target as the client. The numbers shown were captured on a
uzev build. Single-stream throughput on these embedded SoCs is
CPU-bound — the path traverses the kernel TCP/IP stack and the
single-queue `xilinx_axienet` driver on a Cortex-A53 — so absolute
figures vary by board with clock speed, DDR bandwidth, and core count.

#### On the host PC (server side)

Install iperf3 (any recent Linux distribution has it packaged) and start
it in server mode. The default listening port is 5201; `-B` pins it to a
specific local address (useful when the host has multiple interfaces, as
in our PC + SFP28-NIC setup):

```
$ sudo apt install iperf3
$ iperf3 -s -B 192.168.1.1
-----------------------------------------------------------
Server listening on 5201 (test #1)
-----------------------------------------------------------
```

Make sure the host and target are on the same subnet — in this session
the host has `192.168.1.1/24` on its SFP28 NIC and the uzev got
`192.168.1.161/24` on `end1` via DHCP from the host (NetworkManager
shared mode).

#### On the PetaLinux target (client side)

Run iperf3 in client mode, pointing it at the host's IP. `-t` sets the
test duration in seconds, `-i` the per-interval reporting period.

**TCP, target → host:**

```
uzev-sfp28-2025-2:~$ iperf3 -c 192.168.1.1 -t 10 -i 1
Connecting to host 192.168.1.1, port 5201
[  5] local 192.168.1.161 port 51276 connected to 192.168.1.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   194 MBytes  1.63 Gbits/sec    0    707 KBytes
[  5]   1.00-2.00   sec   187 MBytes  1.57 Gbits/sec    0    793 KBytes
[  5]   2.00-3.00   sec   193 MBytes  1.62 Gbits/sec    0   1.31 MBytes
[  5]   3.00-4.00   sec   186 MBytes  1.56 Gbits/sec    0   1.61 MBytes
[  5]   4.00-5.00   sec   147 MBytes  1.23 Gbits/sec    0   1.77 MBytes
[  5]   5.00-6.00   sec   186 MBytes  1.56 Gbits/sec    0   2.19 MBytes
[  5]   6.00-7.00   sec   200 MBytes  1.68 Gbits/sec    0   2.34 MBytes
[  5]   7.00-8.00   sec   167 MBytes  1.40 Gbits/sec    0   2.49 MBytes
[  5]   8.00-9.00   sec   193 MBytes  1.62 Gbits/sec    0   2.80 MBytes
[  5]   9.00-10.02  sec   174 MBytes  1.43 Gbits/sec    0   3.30 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.02  sec  1.86 GBytes  1.59 Gbits/sec    0          sender
[  5]   0.00-10.02  sec  1.86 GBytes  1.59 Gbits/sec               receiver

iperf Done.
```

Sustained throughput is approximately 1.6 Gbit/s with no retransmits.
The link layer is stable; the SoC is the limiting factor.

**TCP, host → target** (add `-R`):

```
uzev-sfp28-2025-2:~$ iperf3 -c 192.168.1.1 -t 10 -i 1 -R
...
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  1.49 GBytes  1.28 Gbits/sec  630         sender
[  5]   0.00-10.00  sec  1.49 GBytes  1.28 Gbits/sec              receiver
```

Throughput in the reverse direction is approximately 1.3 Gbit/s with
630 retransmits. The host PC's NIC drives the link faster than the
uzev's receive path can sustain; packets dropped when the A53 falls
behind trigger TCP retransmission.

**UDP, target → host at line-rate request:**

```
uzev-sfp28-2025-2:~$ iperf3 -c 192.168.1.1 -t 10 -i 1 -u -b 10G
...
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-10.00  sec  1.07 GBytes   919 Mbits/sec  0.000 ms  0/793232 (0%)  sender
[  5]   0.00-10.00  sec  1.07 GBytes   919 Mbits/sec  0.010 ms  0/793232 (0%)  receiver
```

The uzev cannot generate UDP traffic at 10 Gbit/s. The sender caps at
approximately 920 Mbit/s and all transmitted datagrams are received
intact (0% loss).

**UDP, host → target at line-rate request** (`-u -b 10G -R`):

```
uzev-sfp28-2025-2:~$ iperf3 -c 192.168.1.1 -t 10 -i 1 -u -b 10G -R
...
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-10.00  sec  4.50 GBytes  3.87 Gbits/sec  0.000 ms  0/3340532 (0%)       sender
[  5]   0.00-10.00  sec  1.39 GBytes  1.20 Gbits/sec  0.020 ms  2306431/3338654 (69%) receiver
```

The host PC's NIC transmits at 3.87 Gbit/s; the uzev's receive path can
sustain approximately 1.2 Gbit/s and drops the remaining ~69% of
datagrams (2,306,431 of 3,338,654) at the kernel RX path. UDP has no
flow control, so the sender is unaffected by receiver-side loss.

#### Where the bottleneck is and what the solution is

The link layer operates at 10 Gbit/s, as confirmed by `ethtool end1`
(`Speed: 10000Mb/s`, `Link detected: yes`). The single-stream iperf3
ceiling is set by the embedded CPU: each packet traverses the kernel
TCP/IP stack and the `xilinx_axienet` driver's single-queue DMA path
before reaching (or leaving) DDR. On a Cortex-A53 the resulting limit
is approximately 1.5 Gbit/s of single-stream TCP, independent of link
speed.

Designs that require sustained 10G or 25G throughput on these SoCs
structure the datapath as a split control / data plane, removing the
CPU from the bulk-traffic path:

* **Data plane in fabric.** Incoming packets are parsed at the MAC's
  AXI-Stream interface by a packet classifier in PL, typically matching
  on Ethernet / IP / UDP header fields, VLAN tag, or a protocol-specific
  marker. Matched flows are routed directly to fabric processing
  blocks. Typical destinations include:

  * raw sensor or ADC data into a DSP pipeline (filtering, FFT,
    decimation), then to DDR via a high-throughput DMA or back out a
    second MAC;
  * video frames into a Vivado / Vitis Vision pipeline (debayer,
    scale, encode);
  * application-specific compute kernels (cryptography, ML inference,
    protocol offload). On Versal, bulk traffic is typically handed
    off from PL to an AI Engine array; on ZynqMP it remains in PL or
    is processed by an HLS-generated accelerator.

  This traffic does not transit the PS. Each of the four SFP28 ports
  has its own `xxv_ethernet` IP and GT channel, and fabric processing
  pipelines are sized for line-rate operation by construction, so all
  four ports can sustain wire-rate concurrently.

* **Control plane on the CPU.** The classifier forwards a small subset
  of traffic — ARP, ICMP, DHCP, SSH, management protocols, application
  configuration — up the MAC's AXI-MM DMA path to the kernel. This
  traffic is low-volume and irregular, and the Linux network stack
  handles it without difficulty.

The Quad SFP28 FMC and the per-port `xxv_ethernet` IPs provide the
building blocks; the design choice is the partitioning of work between
fabric and PS. With this architecture a ZynqMP or Versal device can
sustain all four ports at 10G or 25G simultaneously. The iperf3 results
above represent the worst case, in which all traffic transits the CPU.

For benchmarking a fabric datapath, iperf3 over the Linux network
stack is not appropriate; an AXI-Stream loopback in PL with hardware
counters is the meaningful measurement.

An example design demonstrating this split control / data-plane
architecture on the Quad SFP28 FMC is currently in development.


[Quad SFP28 FMC]: https://docs.opsero.com/op081/datasheet/overview/
[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment

