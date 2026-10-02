# Testing the SFP28 ports

This page describes how to connect the SFP28 ports of the [Quad SFP28 FMC] to a link partner,
check the link and measure the throughput, and what results to expect. It applies to both the
PetaLinux and the Yocto images; only the interface names differ (see
[PetaLinux port configurations](petalinux.md#port-configurations) and
[Yocto network interface names](yocto.md#network-interface-names)).

## Test setup

```none
  target board + Quad SFP28 FMC                         link partner
 +-----------------------------+                 +------------------------+
 | SFP28 port N  [SFP module] ===== fiber / ======[SFP module]  10G/25G   |
 |                             |    DAC / copper |               NIC or   |
 | board RJ45 (SSH, optional) ------- LAN -------|               switch   |
 +-----------------------------+                 +------------------------+
```

* **One link per SFP28 port.** Each SFP28 port is a separate network interface with its own MAC.
  Connect each port you want to test to its own link partner port: a 10G/25G network card in a
  PC, or a switch port.
* **Modules and cables.** Use parts that support the target's line rate. The 10G targets accept
  10G SFP+ optics, 10G DAC cables and 10GBASE-T copper SFP+ modules; a 25G-only SFP28 module is
  rejected. The `_25g` targets need 25G SFP28 optics or DAC cables. A 10GBASE-T copper module
  needs a matching 10GBASE-T port (or another copper module) at the far end.
* **Subnets.** If you test several ports from the same PC, put each port on its own subnet, for
  example `192.168.10.0/24` on port 0 and `192.168.11.0/24` on port 1. Interfaces on the same
  subnet confuse the routing on both ends.

## Link partner settings

The XXV Ethernet cores of this design run at one fixed rate, with no auto-negotiation, no link
training and no FEC (the IP options `INCLUDE_FEC_LOGIC`, `INCLUDE_RSFEC_LOGIC` and
`INCLUDE_AUTO_NEG_LT_LOGIC` are all disabled). Configure the link partner to match:

| Setting | 10G targets | `_25g` targets |
|---------|-------------|----------------|
| Speed | 10000 Mb/s, full duplex | 25000 Mb/s, full duplex |
| Auto-negotiation | off | off |
| FEC | off | off |

On a Linux PC, with the NIC port named `<pc-if>`:

```
sudo ethtool -s <pc-if> speed 10000 duplex full autoneg off    # 25000 for the _25g targets
sudo ethtool --set-fec <pc-if> encoding off
sudo ethtool <pc-if>                                            # check Speed / Link detected
```

Many 25G NICs and switches enable RS-FEC or BASE-R FEC by default at 25G, in which case the link
does not come up until FEC is turned off on the partner. With 10GBASE-T copper modules the copper
side negotiates between the two modules; the SFP side of each module runs at the fixed 10G rate.

## Bring up a port

On the board (the examples use `end0`; substitute your interface name):

```
dmesg | grep -E 'sfp sfp-eth[0-9]'          # cages probed, module identified
sudo ethtool end0                           # Speed: 10000Mb/s, Link detected: yes
ip -br addr show end0                       # address (DHCP) or set one by hand:
sudo ip addr add 192.168.10.10/24 dev end0
sudo ip link set end0 up
```

When the link comes up the kernel logs, for example:

```none
xilinx_axienet 80060000.ethernet end0: Link is Up - 10Gbps/Full - flow control off
```

The cage LEDs on the Quad SFP28 FMC show the state of each port: green when a module is fitted
and receives a signal, red when a module is fitted but has no receive signal (`RX_LOS`), off when
the cage is empty.

To get an address over DHCP from the PC, run a DHCP server on the PC's NIC port (for example
NetworkManager's "Shared to other computers" mode, which gives the PC `10.42.0.1` and hands out
addresses on that subnet), or give both ends a fixed address in the same subnet.

## Check the link

```
ping -c 5 -I end0 <partner-ip>
ip -s link show end0          # packet, byte, error and drop counters
sudo ethtool -S end0          # driver statistics, where the driver provides them
```

All transmitted pings should be received (`0% packet loss`), and the error counters of
`ip -s link` should stay at zero during the throughput test below.

## Measure the throughput with iperf3

`iperf3` is included in both images. Start a server on the link partner PC, bound to its address
on the link:

```
iperf3 -s -B <partner-ip>
```

Then run the client on the board. Binding the client to the interface makes sure the traffic uses
the SFP28 port even if the board is also connected through its own Ethernet port:

```
iperf3 -c <partner-ip> --bind-dev end0 -t 10        # board transmits (TX)
iperf3 -c <partner-ip> --bind-dev end0 -t 10 -R     # board receives (RX)
```

### Expected results

The table below lists single-stream TCP throughput measured with the Yocto images of this release,
with a 10GBASE-T copper SFP+ module in the Quad SFP28 FMC and a 10G NIC in a Linux PC as the link
partner. All runs had 0% ping loss and no interface errors.

| Target | SFP28 port | Link | TX (board → PC) | RX (PC → board) |
|--------|------------|------|-----------------|-----------------|
| `zcu104` | 0 | 10G | 2.52 Gbit/s | 2.30 Gbit/s |
| `zcu102_hpc0` | 1 | 10G | 1.84 Gbit/s | 1.53 Gbit/s |
| `zcu102_hpc1` | 0 | 10G | 1.85 Gbit/s | 1.55 Gbit/s |
| `zcu106_hpc0` | 0 | 10G | 1.82 Gbit/s | 1.42 Gbit/s |
| `zcu106_hpc1` | 0 | 10G | 1.83 Gbit/s | 1.53 Gbit/s |
| `uzev` | 0 | 10G | 1.74 Gbit/s | 1.41 Gbit/s |
| `vck190_fmcp1` | 0 | 10G | 2.33 Gbit/s | 1.94 Gbit/s |
| `vck190_fmcp2` | 0 | 10G | 2.31 Gbit/s | 1.96 Gbit/s |

The board's own Ethernet port (1G) measured about 940 Mbit/s TX and 935 Mbit/s RX on the same
boards.

What these numbers mean:

* **The link runs at 10 Gbit/s; the throughput is limited by the processor.** A single TCP stream
  passes through the Linux network stack and the `xilinx_axienet` driver on one Arm core
  (Cortex-A53 on Zynq UltraScale+, Cortex-A72 on Versal), which limits it to a fraction of the
  line rate. The PetaLinux page discusses this in
  [Where the bottleneck is](petalinux.md#where-the-bottleneck-is-and-what-the-solution-is).
* **The RX direction shows TCP retransmissions on the sender (the PC).** The PC sends faster than
  the board's receive path can take the packets; the dropped packets are retransmitted by TCP.
  Several hundred retransmissions per 10-second run are normal in this direction. The TX
  direction runs without retransmissions.
* **Results vary with the board and the link partner.** A busy link-partner PC lowers the
  results. Run the tests with an otherwise idle PC.

Throughput figures for the `_25g` targets are not listed here.

[Quad SFP28 FMC]: https://docs.opsero.com/op081/datasheet/overview/
