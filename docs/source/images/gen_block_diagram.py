#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Opsero Electronic Design Inc.
"""
Generate the block diagrams for the Opsero Quad SFP28 FMC (OP081) 10G/25G Ethernet
(XXV Ethernet) reference design docs, one per device family.

Both diagrams follow the block-design scripts in Vivado/src/bd/:

* bd_zynqmp.tcl -- ONE xxv_ethernet_0 IP with NUM_OF_CORES = number of SFP28 ports
  (1 or 4), BASE-R, 156.25 MHz GT reference. Per port: an AXI DMA (scatter-gather,
  64-bit) behind its own AXI Interconnect to an S_AXI_HPn_FPD port, a TX and an RX
  AXI4-Stream data FIFO (16384 x 8 bytes, packet mode). AXI-Lite from M_AXI_HPM0_LPD.
  AXI IIC (FMC I2C) and a dual-channel AXI GPIO (QPLL reset out, MOD_ABS[3:0] in).
* bd_versal.tcl -- one xxv_ethernet IP PER PORT inside an sfp_port<N> hierarchy with
  its AXI DMA (3 AXI-MM masters to the NoC), TX/RX data FIFOs (32768 x 8 bytes, packet
  mode), two BUFG_GTs and a local SmartConnect; one shared gt_quad_base (GTY or GTYP,
  RPLL forced). clk_wizard_0 from the CIPS pl0_ref_clk: 156.25 MHz system clock and
  100 MHz APB3 / free-running clock. AXI IIC and an input-only AXI GPIO (MOD_ABS[3:0]).

Port 0 is drawn in detail; ports 1-3 are exact copies and are drawn compact. The
1-port ZynqMP targets (zcu104, zcu106_hpc1) instantiate port 0 only.

The output PNGs are written next to this script (docs/source/images/):
    zynqmp-xxv-eth-block-diagram.png
    versal-xxv-eth-block-diagram.png

Usage (from anywhere):
    python3 docs/source/images/gen_block_diagram.py
"""

import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, FancyBboxPatch, FancyArrowPatch
from matplotlib.lines import Line2D

# ---- palette (shared with the other Opsero reference-design block diagrams) --
C_PS_FILL      = "#D9D9D9"; C_PS_EDGE      = "#7F7F7F"   # processor / DDR column
C_FAB_FILL     = "#F2F2F2"; C_FAB_EDGE     = "#BFBFBF"   # FPGA fabric container
C_DMA_FILL     = "#808080"; C_DMA_EDGE     = "#404040"   # AXI DMA (dark grey)
C_MAC_FILL     = "#E8E8F2"; C_MAC_EDGE     = "#8C8CC0"   # soft logic (lavender)
C_GT_FILL      = "#F3EFE2"; C_GT_EDGE      = "#BFB585"   # hard blocks: GT quad (cream)
C_FMC_FILL     = "#DCE6F2"; C_FMC_EDGE     = "#9DB7D4"   # external FMC (blue-grey)
C_CAGE_FILL    = "#FFFFFF"                                # SFP28 cages (white on FMC)
C_CLK_FILL     = "#FDE9D9"; C_CLK_EDGE     = "#E0B090"   # clocking (peach)
C_CTRL_FILL    = "#ECECEC"; C_CTRL_EDGE    = "#BFBFBF"   # control-plane caption
C_AXARR_FILL   = "#EDF3D4"; C_AXARR_EDGE   = "#A6B85A"   # data arrows (pale green)
C_LINKARR_FILL = "#DAE8F5"; C_LINKARR_EDGE = "#6F9FCF"   # link arrows (pale blue)
C_REFCLK_LINE  = "#C8823C"                                # refclk arrows (orange)
TXT = "#1A1A1A"
# additions for this design
C_XXV_FILL     = "#E4F0D0"; C_XXV_EDGE     = "#7F9A2E"   # XXV Ethernet MAC/PCS (green)
C_HIER_EDGE    = "#9A9A9A"                                # Versal sfp_port<N> hierarchy
C_NOTE         = "#404040"


def box(ax, x, y, w, h, fc, ec, label, fs=10, rot=0, lw=1.2, weight="normal",
        txtcolor=None, ls="-", z=2):
    ax.add_patch(plt.Rectangle((x, y), w, h, fc=fc, ec=ec, lw=lw, ls=ls, zorder=z))
    if label:
        ax.text(x + w / 2, y + h / 2, label, ha="center", va="center",
                fontsize=fs, rotation=rot, color=txtcolor or TXT, weight=weight,
                zorder=z + 1, linespacing=1.25)


def titled_box(ax, x, y, w, h, fc, ec, title, body, title_fs=9.5, body_fs=7.6,
               lw=1.2, txtcolor=None, title_dy=2.6, ls="-", z=2):
    """A box() with a bold title line at the top and a smaller body below it."""
    box(ax, x, y, w, h, fc, ec, "", lw=lw, ls=ls, z=z)
    cx = x + w / 2
    ax.text(cx, y + h - title_dy, title, ha="center", va="center",
            fontsize=title_fs, weight="bold", color=txtcolor or TXT, zorder=z + 1,
            linespacing=1.15)
    if body:
        ax.text(cx, y + (h - title_dy * 1.9) / 2, body, ha="center", va="center",
                fontsize=body_fs, color=txtcolor or TXT, zorder=z + 1,
                linespacing=1.3)


def harrow(ax, x0, x1, yc, label, fc, ec, double=True, bh=2.0, hh=3.4, hl=3.2,
           fs=8.5, lw=1.1, lab_dy=0.0, lab_color=None, weight="normal"):
    """Horizontal block arrow from x0 to x1.

    double=True  : double-headed (requires x0 < x1).
    double=False : single-headed with the head at x1 (x1 may be < x0).
    """
    if double:
        pts = [(x0, yc), (x0 + hl, yc + hh), (x0 + hl, yc + bh),
               (x1 - hl, yc + bh), (x1 - hl, yc + hh), (x1, yc),
               (x1 - hl, yc - hh), (x1 - hl, yc - bh),
               (x0 + hl, yc - bh), (x0 + hl, yc - hh)]
    else:
        s = 1.0 if x1 >= x0 else -1.0
        neck = x1 - s * hl
        pts = [(x0, yc + bh), (neck, yc + bh), (neck, yc + hh),
               (x1, yc), (neck, yc - hh), (neck, yc - bh), (x0, yc - bh)]
    ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec, lw=lw, zorder=2.5))
    if label:
        ax.text((x0 + x1) / 2, yc + lab_dy, label, ha="center", va="center",
                fontsize=fs, color=lab_color or TXT, zorder=3.5, linespacing=1.15,
                weight=weight)


def varrow(ax, xc, y0, y1, fc, ec, double=True, bw=1.4, hw=2.6, hl=2.4, lw=1.1):
    """Vertical block arrow from y0 to y1 (head at y1; both ends if double)."""
    if double:
        lo, hi = min(y0, y1), max(y0, y1)
        pts = [(xc, lo), (xc + hw, lo + hl), (xc + bw, lo + hl),
               (xc + bw, hi - hl), (xc + hw, hi - hl), (xc, hi),
               (xc - hw, hi - hl), (xc - bw, hi - hl),
               (xc - bw, lo + hl), (xc - hw, lo + hl)]
    else:
        s = 1.0 if y1 >= y0 else -1.0
        neck = y1 - s * hl
        pts = [(xc - bw, y0), (xc - bw, neck), (xc - hw, neck), (xc, y1),
               (xc + hw, neck), (xc + bw, neck), (xc + bw, y0)]
    ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec, lw=lw, zorder=2.5))


def route(ax, pts, color, lw=1.6, z=3):
    """Thin elbow arrow through the points in pts (head at the last point)."""
    xs, ys = zip(*pts[:-1])
    ax.add_line(Line2D(xs, ys, color=color, lw=lw, zorder=z,
                       solid_capstyle="butt", solid_joinstyle="miter"))
    ax.add_patch(FancyArrowPatch(pts[-2], pts[-1], arrowstyle="-|>",
                                 mutation_scale=11, lw=lw, color=color,
                                 zorder=z, shrinkA=0, shrinkB=0))


def refclk_arrow(ax, p0, p1, label, lab_xy, fs=7.4, lw=1.9):
    """Thin single-line arrow (head at p1) for a single clock net."""
    ax.add_patch(FancyArrowPatch(p0, p1, arrowstyle="-|>", mutation_scale=13,
                                 lw=lw, color=C_REFCLK_LINE, zorder=3,
                                 shrinkA=0, shrinkB=0))
    ax.text(lab_xy[0], lab_xy[1], label, ha="center", va="center",
            fontsize=fs, color=C_REFCLK_LINE, zorder=4, weight="bold",
            linespacing=1.2)


def note(ax, x, y, text, fs=6.8, ha="center", color=C_NOTE, weight="normal"):
    ax.text(x, y, text, ha=ha, va="center", fontsize=fs, color=color,
            zorder=4, linespacing=1.3, weight=weight)


# ---- layout shared by both families -------------------------------------------
# vertical plan: control / clocking strip 4-27, port rows 31-104, titles above
P0 = (79.0, 104.0)                       # port 0 row (detailed: TX row over RX row)
ROWS = [(63.0, 75.0), (47.0, 59.0), (31.0, 43.0)]   # ports 1, 2, 3 (compact)
P0_TX = P0[0] + (P0[1] - P0[0]) * 0.72   # TX path centre line (left to right)
P0_RX = P0[0] + (P0[1] - P0[0]) * 0.28   # RX path centre line (right to left)


def row_yc(r):
    return (r[0] + r[1]) / 2


def draw_fmc(ax, gt_r, fmc_x0, fmc_x1, refclk_note):
    """External column: Quad SFP28 FMC with four cages, the Si5328 and the I2C mux,
    plus the link partner. gt_r is the right edge of the GT quad box."""
    fcx = (fmc_x0 + fmc_x1) / 2
    ax.add_patch(plt.Rectangle((fmc_x0, 4), fmc_x1 - fmc_x0, 121,
                               fc=C_FMC_FILL, ec=C_FMC_EDGE, lw=1.3, zorder=1))
    ax.text((fmc_x0 + 192) / 2, 127.6, "External to the FPGA", ha="center",
            va="bottom", fontsize=12.5, weight="bold", color=TXT)
    ax.text(fcx, 121.0, "Quad SFP28 FMC\n(OP081)", ha="center", va="center",
            fontsize=9.8, weight="bold", color=TXT, linespacing=1.3)

    sub_x, sub_w = fmc_x0 + 2.0, fmc_x1 - fmc_x0 - 4.0
    cages = [(P0[0] + 3.0, P0[1] - 3.0)] + [(r[0] + 0.5, r[1] - 0.5) for r in ROWS]
    for p, (y0, y1) in enumerate(cages):
        body = ("SFP+ / SFP28 module\n10GBASE-R or\n25GBASE-R\n\nMOD_ABS, RX_LOS,\n"
                "TX_FAULT, LEDs\nto the PL") if p == 0 else "10GBASE-R / 25GBASE-R"
        titled_box(ax, sub_x, y0, sub_w, y1 - y0, C_CAGE_FILL, C_FMC_EDGE,
                   f"SFP28 port {p}", body, title_fs=8.6, body_fs=6.8,
                   title_dy=2.4 if p == 0 else 3.2)
        yc = (y0 + y1) / 2 if p else P0_TX - 4.0
        harrow(ax, gt_r, sub_x, yc, "", C_LINKARR_FILL, C_LINKARR_EDGE,
               bh=1.6, hh=2.9, hl=1.5)
        ax.text((gt_r + sub_x) / 2, yc + 4.2, f"DP{p}", ha="center",
                va="center", fontsize=7.0, color=TXT, zorder=3)

    # Si5328 jitter attenuator -> GT reference clock (GBTCLK0)
    si_y0, si_y1 = 106.0, 117.0
    titled_box(ax, sub_x, si_y0, sub_w, si_y1 - si_y0, C_CLK_FILL, C_CLK_EDGE,
               "Si5328", "156.25 MHz\nprogrammed by Linux\nover the FMC I2C",
               title_fs=8.6, body_fs=6.6, title_dy=2.2)
    refclk_arrow(ax, (sub_x, si_y0 + 3.0), (gt_r, si_y0 + 3.0), "",
                 (0, 0))
    note(ax, (gt_r + sub_x) / 2, si_y0 + 6.6, "GBTCLK0\n" + refclk_note, fs=6.3,
         color=C_REFCLK_LINE, weight="bold")

    # I2C mux at the bottom of the FMC column
    titled_box(ax, sub_x, 6.0, sub_w, 19.0, C_CAGE_FILL, C_FMC_EDGE,
               "PCA9548 I2C mux",
               "ch 0-3: SFP28 module\nEEPROM / diagnostics\nch 4: Si5328",
               title_fs=8.2, body_fs=6.6, title_dy=2.4)

    # link partner, cabled to any cage
    lp_x0, lp_x1 = fmc_x1 + 3.0, 192.0
    titled_box(ax, lp_x0, 50.0, lp_x1 - lp_x0, 46.0, C_CAGE_FILL, C_LINKARR_EDGE,
               "Link partner",
               "10G or 25G NIC or\nswitch port, one\nper SFP28 port\n\n"
               "same fixed rate\nas the target\n(10G or _25g)\n\n"
               "FEC off\nauto-neg off\n\n"
               "fiber, DAC or\n10GBASE-T copper\nSFP+ module",
               title_fs=8.8, body_fs=6.9, title_dy=2.8, lw=1.3)
    for p, (y0, y1) in enumerate(cages):
        yc = (y0 + y1) / 2 if p else P0_TX - 4.0
        if 50.0 < yc < 96.0:
            ax.add_line(Line2D([fmc_x1 - 2.0, lp_x0], [yc, yc], color=C_LINKARR_EDGE,
                               lw=2.4, zorder=3, ls=(0, (4, 2))))
    ax.add_line(Line2D([fmc_x1 - 2.0, fmc_x1 + 1.5, fmc_x1 + 1.5, lp_x0],
                       [row_yc(ROWS[2]), row_yc(ROWS[2]), 52.0, 52.0],
                       color=C_LINKARR_EDGE, lw=2.4, zorder=3, ls=(0, (4, 2))))
    note(ax, (lp_x0 + lp_x1) / 2, 46.5, "optical / DAC /\ncopper link", fs=6.8,
         color=TXT)
    return sub_x


# ---- Zynq UltraScale+ -----------------------------------------------------------
def zynqmp(out):
    fig, ax = plt.subplots(figsize=(19.5, 13.4), dpi=120)
    ax.set_xlim(0, 195)
    ax.set_ylim(0, 133)
    ax.axis("off")

    # processing system column
    ps_x0, ps_w = 2.0, 17.0
    ps_r = ps_x0 + ps_w
    cx = ps_x0 + ps_w / 2
    titled_box(ax, ps_x0, 110, ps_w, 15, C_PS_FILL, C_PS_EDGE, "DDR4",
               "PS memory", title_fs=10.5, body_fs=7.4, title_dy=3.4, lw=1.3)
    box(ax, ps_x0, 31, ps_w, 75, C_PS_FILL, C_PS_EDGE, "", lw=1.3)
    varrow(ax, cx, 106, 110, C_AXARR_FILL, C_AXARR_EDGE, bw=1.4, hw=2.6, hl=1.6)
    ax.text(cx, 99.5, "Zynq\nUltraScale+\nPS", ha="center", va="center",
            fontsize=11.5, weight="bold", color=TXT, linespacing=1.2)
    ax.text(cx, 70.0,
            "Arm Cortex-A53\n\nLinux\n(PetaLinux or\nYocto / EDF)\n\n"
            "xilinx_axienet\ndriver: one\nnetdev per\nSFP28 port\n\n"
            "kernel SFP\nframework +\nphylink",
            ha="center", va="center", fontsize=7.4, color=TXT, linespacing=1.4)
    note(ax, cx, 37.0, "board RJ45:\nPS GEM3 (macb)", fs=6.9, color=TXT)

    # FPGA fabric container
    fab_x0, fab_x1 = 22.0, 141.0
    ax.add_patch(plt.Rectangle((fab_x0, 3), fab_x1 - fab_x0, 122,
                               fc=C_FAB_FILL, ec=C_FAB_EDGE, lw=1.3, zorder=1))
    ax.text((fab_x0 + fab_x1) / 2, 127.6, "Programmable logic  (Zynq UltraScale+)",
            ha="center", va="bottom", fontsize=13, weight="bold", color=TXT)

    ic_x, ic_w = 26.0, 11.0          # AXI Interconnect (3 -> 1) per port
    dma_x, dma_w = 41.0, 13.0
    ff_x, ff_w = 58.5, 14.0
    xxv_x, xxv_w = 78.0, 26.0
    gt_x, gt_w = 110.0, 13.0
    gt_r = gt_x + gt_w

    # port 0 in detail
    p0h = P0[1] - P0[0]
    titled_box(ax, ic_x, P0[0], ic_w, p0h, C_MAC_FILL, C_MAC_EDGE, "AXI\nInter-\nconnect",
               "\n\n\n3 → 1", title_fs=7.8, body_fs=7.0, title_dy=5.0)
    harrow(ax, ps_r, ic_x, row_yc(P0), "HP0", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.5, hh=2.7, hl=1.4, fs=7.0)
    titled_box(ax, dma_x, P0[0], dma_w, p0h, C_DMA_FILL, C_DMA_EDGE, "AXI DMA",
               "scatter-gather\n64-bit\n\nMM2S = TX\nS2MM = RX",
               title_fs=8.6, body_fs=7.0, txtcolor="#FFFFFF", title_dy=2.6)
    harrow(ax, ic_x + ic_w, dma_x, row_yc(P0), "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.5, hh=2.7, hl=1.2)
    note(ax, (ic_x + ic_w + dma_x) / 2, row_yc(P0) + 5.0, "3x\nAXI", fs=6.3)
    fh = p0h / 2 - 1.0
    titled_box(ax, ff_x, P0[1] - fh, ff_w, fh, C_MAC_FILL, C_MAC_EDGE, "TX FIFO",
               "AXIS data FIFO\npacket mode\n128 KB", title_fs=8.0, body_fs=6.6,
               title_dy=2.2)
    titled_box(ax, ff_x, P0[0], ff_w, fh, C_MAC_FILL, C_MAC_EDGE, "RX FIFO",
               "AXIS data FIFO\npacket mode\n128 KB", title_fs=8.0, body_fs=6.6,
               title_dy=2.2)
    harrow(ax, dma_x + dma_w, ff_x, P0_TX, "", C_AXARR_FILL, C_AXARR_EDGE,
           double=False, bh=1.3, hh=2.4, hl=1.4)
    harrow(ax, ff_x, dma_x + dma_w, P0_RX, "", C_AXARR_FILL, C_AXARR_EDGE,
           double=False, bh=1.3, hh=2.4, hl=1.4)
    harrow(ax, ff_x + ff_w, xxv_x, P0_TX, "AXIS", C_AXARR_FILL, C_AXARR_EDGE,
           double=False, bh=1.3, hh=2.4, hl=1.4, fs=6.4, lab_dy=4.0)
    harrow(ax, xxv_x, ff_x + ff_w, P0_RX, "AXIS", C_AXARR_FILL, C_AXARR_EDGE,
           double=False, bh=1.3, hh=2.4, hl=1.4, fs=6.4, lab_dy=-4.0)

    # compact rows for ports 1-3
    for p, r in enumerate(ROWS, start=1):
        yc, h = row_yc(r), r[1] - r[0]
        box(ax, ic_x, r[0], ic_w, h, C_MAC_FILL, C_MAC_EDGE, "AXI\nIC", fs=7.4)
        harrow(ax, ps_r, ic_x, yc, f"HP{p}", C_AXARR_FILL, C_AXARR_EDGE,
               bh=1.5, hh=2.7, hl=1.4, fs=7.0)
        box(ax, dma_x, r[0], dma_w, h, C_DMA_FILL, C_DMA_EDGE, "AXI DMA", fs=8.2,
            txtcolor="#FFFFFF", weight="bold")
        harrow(ax, ic_x + ic_w, dma_x, yc, "", C_AXARR_FILL, C_AXARR_EDGE,
               bh=1.5, hh=2.7, hl=1.2)
        box(ax, ff_x, r[0], ff_w, h, C_MAC_FILL, C_MAC_EDGE, "TX / RX\nFIFOs", fs=7.6)
        harrow(ax, dma_x + dma_w, ff_x, yc, "", C_AXARR_FILL, C_AXARR_EDGE,
               bh=1.5, hh=2.7, hl=1.2)
        harrow(ax, ff_x + ff_w, xxv_x, yc, "", C_AXARR_FILL, C_AXARR_EDGE,
               bh=1.5, hh=2.7, hl=1.2)

    # ONE XXV Ethernet IP with one channel per SFP28 port
    titled_box(ax, xxv_x, 29.0, xxv_w, 96.0 - 29.0 + 10.5, C_XXV_FILL, C_XXV_EDGE,
               "xxv_ethernet_0", "", title_fs=9.4, title_dy=2.6, lw=1.5)
    note(ax, xxv_x + xxv_w / 2, 110.4,
         "10G/25G Ethernet Subsystem\nMAC + PCS/PMA, BASE-R\n"
         "1 or 4 cores (one per port)", fs=6.7, color=TXT)
    for p, r in enumerate([P0] + ROWS):
        y0, y1 = (r[0], r[1]) if p else (P0[0] + 1.0, P0[1] - 1.0)
        body = ("10GBASE-R / 25GBASE-R\n64-bit AXIS\n156.25 MHz (10G)\n"
                "390.625 MHz (25G)\n\nno FEC, no AN/LT\nstatistics counters"
                if p == 0 else "")
        titled_box(ax, xxv_x + 1.5, y0 + 0.5, xxv_w - 3.0, y1 - y0 - 1.0, "#F4F9EA",
                   C_XXV_EDGE, f"core {p}", body, title_fs=8.0, body_fs=6.4,
                   title_dy=2.2 if p == 0 else (y1 - y0) / 2, z=2.2)

    # GT quad
    titled_box(ax, gt_x, 29.0, gt_w, 84.0, C_GT_FILL, C_GT_EDGE, "GT quad",
               "GTH\n(uzev, zcu102,\nzcu104, zcu106:\n10G only)\n\n"
               "GTY\n(zcu111, zcu208,\nzcu216:\n10G or 25G)\n\n"
               "4 channels\nshared QPLL",
               title_fs=9.0, body_fs=6.6, title_dy=2.8)
    for p, r in enumerate([P0] + ROWS):
        yc = row_yc(r) if p else row_yc(P0)
        harrow(ax, xxv_x + xxv_w, gt_x, yc, "", C_AXARR_FILL, C_AXARR_EDGE,
               bh=1.3, hh=2.4, hl=1.1)

    draw_fmc(ax, gt_r, 145.0, 167.0, "156.25 MHz")

    # bottom strip: clocking, sideband, control plane
    titled_box(ax, 24.0, 5.0, 37.0, 21.0, C_CLK_FILL, C_CLK_EDGE, "Clocking",
               "pl_clk0 (100 MHz): AXI-Lite, DMA SG,\nXXV dclk, interconnects\n\n"
               "per port tx_clk_out / rx_clk_out:\nDMA MM2S / S2MM, FIFOs\n\n"
               "GT refclk: 156.25 MHz (Si5328)",
               title_fs=8.6, body_fs=6.7, title_dy=2.8)
    titled_box(ax, 63.0, 5.0, 31.0, 21.0, C_CTRL_FILL, C_CTRL_EDGE,
               "SFP sideband (per port)",
               "green LED = present AND no RX_LOS\nred LED = present AND RX_LOS\n\n"
               "TX_DISABLE, RATE_SEL0/1:\ntied low\nTX_FAULT: not used",
               title_fs=8.4, body_fs=6.6, title_dy=2.8)
    titled_box(ax, 96.0, 5.0, 43.0, 21.0, C_CTRL_FILL, C_CTRL_EDGE,
               "Control plane: AXI-Lite (M_AXI_HPM0_LPD)",
               "XXV cores · AXI DMAs · AXI IIC (FMC I2C)\n"
               "AXI GPIO ch 1: QPLL reset (out)\n"
               "AXI GPIO ch 2: MOD_ABS[3:0] (in)\n\n"
               "interrupts: 2 per DMA + IIC → pl_ps_irq",
               title_fs=8.2, body_fs=6.6, title_dy=2.8)
    route(ax, [(ps_r - 6.0, 31.0), (ps_r - 6.0, 28.4), (117.5, 28.4), (117.5, 26.0)],
          C_PS_EDGE, lw=1.6)
    note(ax, 42.0, 27.2, "M_AXI_HPM0_LPD (AXI-Lite)", fs=6.6)
    route(ax, [(139.0, 15.5), (147.0, 15.5)], C_NOTE, lw=1.4)
    note(ax, 143.0, 17.6, "I2C", fs=6.3)

    fig.savefig(out, bbox_inches="tight", pad_inches=0.15, facecolor="white")
    plt.close(fig)
    print("wrote", out)


# ---- Versal ------------------------------------------------------------------------
def versal(out):
    fig, ax = plt.subplots(figsize=(19.5, 13.4), dpi=120)
    ax.set_xlim(0, 195)
    ax.set_ylim(0, 133)
    ax.axis("off")

    # processing system column: DDR, CIPS, NoC
    ps_x0, ps_w = 2.0, 15.0
    ps_r = ps_x0 + ps_w
    cx = ps_x0 + ps_w / 2
    titled_box(ax, ps_x0, 110, ps_w, 15, C_PS_FILL, C_PS_EDGE, "DDR4",
               "via NoC DDRMC", title_fs=10.5, body_fs=7.2, title_dy=3.4, lw=1.3)
    box(ax, ps_x0, 31, ps_w, 75, C_PS_FILL, C_PS_EDGE, "", lw=1.3)
    ax.text(cx, 99.5, "Versal\nPS\n(CIPS)", ha="center", va="center",
            fontsize=11.5, weight="bold", color=TXT, linespacing=1.2)
    ax.text(cx, 68.0,
            "Arm Cortex-A72\n\nLinux\n(PetaLinux or\nYocto / EDF)\n\n"
            "xilinx_axienet\ndriver: one\nnetdev per\nSFP28 port\n\n"
            "kernel SFP\nframework",
            ha="center", va="center", fontsize=7.3, color=TXT, linespacing=1.4)
    note(ax, cx, 37.0, "board RJ45:\nPS GEM (macb)", fs=6.9, color=TXT)

    noc_x, noc_w = 19.0, 4.0
    box(ax, noc_x, 31, noc_w, 94, C_PS_FILL, C_PS_EDGE, "NoC  (axi_noc_0)",
        fs=8.2, rot=90, weight="bold", lw=1.3)
    harrow(ax, ps_r, noc_x, 117.5, "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.2, hh=2.2, hl=1.0)
    harrow(ax, ps_r, noc_x, 95.0, "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.2, hh=2.2, hl=1.0)

    fab_x0, fab_x1 = 25.0, 141.0
    ax.add_patch(plt.Rectangle((fab_x0, 3), fab_x1 - fab_x0, 122,
                               fc=C_FAB_FILL, ec=C_FAB_EDGE, lw=1.3, zorder=1))
    ax.text((fab_x0 + fab_x1) / 2, 127.6, "Programmable logic  (Versal)",
            ha="center", va="bottom", fontsize=13, weight="bold", color=TXT)

    hier_x0, hier_x1 = 27.5, 107.5
    dma_x, dma_w = 31.0, 13.0
    ff_x, ff_w = 49.0, 14.0
    xxv_x, xxv_w = 68.0, 20.0
    bg_x, bg_w = 92.0, 13.5
    gt_x, gt_w = 111.0, 13.0
    gt_r = gt_x + gt_w

    # port 0 hierarchy in detail
    box(ax, hier_x0, P0[0] - 1.5, hier_x1 - hier_x0, P0[1] - P0[0] + 5.5, "none",
        C_HIER_EDGE, "", lw=1.2, ls=(0, (4, 2)), z=1.5)
    note(ax, hier_x0 + 1.0, P0[1] + 2.4, "sfp_port0  (hierarchy, one per SFP28 port)",
         fs=7.2, ha="left", color=TXT, weight="bold")
    p0h = P0[1] - P0[0]
    titled_box(ax, dma_x, P0[0], dma_w, p0h, C_DMA_FILL, C_DMA_EDGE, "AXI DMA",
               "scatter-gather\n64-bit\n\nMM2S = TX\nS2MM = RX",
               title_fs=8.6, body_fs=7.0, txtcolor="#FFFFFF", title_dy=2.6)
    harrow(ax, noc_x + noc_w, dma_x, row_yc(P0), "", C_AXARR_FILL, C_AXARR_EDGE,
           bh=1.5, hh=2.7, hl=1.3)
    note(ax, (noc_x + noc_w + dma_x) / 2, row_yc(P0) + 5.0, "3x\nAXI", fs=6.3)
    fh = p0h / 2 - 1.0
    titled_box(ax, ff_x, P0[1] - fh, ff_w, fh, C_MAC_FILL, C_MAC_EDGE, "TX FIFO",
               "AXIS data FIFO\npacket mode\n256 KB", title_fs=8.0, body_fs=6.6,
               title_dy=2.2)
    titled_box(ax, ff_x, P0[0], ff_w, fh, C_MAC_FILL, C_MAC_EDGE, "RX FIFO",
               "AXIS data FIFO\npacket mode\n256 KB", title_fs=8.0, body_fs=6.6,
               title_dy=2.2)
    harrow(ax, dma_x + dma_w, ff_x, P0_TX, "", C_AXARR_FILL, C_AXARR_EDGE,
           double=False, bh=1.3, hh=2.4, hl=1.4)
    harrow(ax, ff_x, dma_x + dma_w, P0_RX, "", C_AXARR_FILL, C_AXARR_EDGE,
           double=False, bh=1.3, hh=2.4, hl=1.4)
    titled_box(ax, xxv_x, P0[0], xxv_w, p0h, C_XXV_FILL, C_XXV_EDGE, "xxv_ethernet",
               "10G/25G Ethernet\nSubsystem, 1 core\nMAC + PCS/PMA\nBASE-R, 64-bit\n\n"
               "no FEC, no AN/LT\nstatistics counters",
               title_fs=8.4, body_fs=6.5, title_dy=2.4, lw=1.5)
    harrow(ax, ff_x + ff_w, xxv_x, P0_TX, "AXIS", C_AXARR_FILL, C_AXARR_EDGE,
           double=False, bh=1.3, hh=2.4, hl=1.4, fs=6.4, lab_dy=4.0)
    harrow(ax, xxv_x, ff_x + ff_w, P0_RX, "AXIS", C_AXARR_FILL, C_AXARR_EDGE,
           double=False, bh=1.3, hh=2.4, hl=1.4, fs=6.4, lab_dy=-4.0)
    titled_box(ax, bg_x, P0[1] - fh, bg_w, fh, C_CLK_FILL, C_CLK_EDGE, "BUFG_GT",
               "GT txoutclk →\nTX user clock\n156.25 / 390.625", title_fs=7.6, body_fs=6.3,
               title_dy=2.2)
    titled_box(ax, bg_x, P0[0], bg_w, fh, C_CLK_FILL, C_CLK_EDGE, "BUFG_GT",
               "GT rxoutclk →\nRX user clock\n156.25 / 390.625", title_fs=7.6, body_fs=6.3,
               title_dy=2.2)

    # compact rows for ports 1-3
    for p, r in enumerate(ROWS, start=1):
        yc, h = row_yc(r), r[1] - r[0]
        box(ax, hier_x0, r[0] - 1.0, hier_x1 - hier_x0, h + 2.0, "none",
            C_HIER_EDGE, "", lw=1.1, ls=(0, (4, 2)), z=1.5)
        note(ax, hier_x1 - 1.0, r[1] - 1.5, f"sfp_port{p}", fs=6.6, ha="right")
        box(ax, dma_x, r[0], dma_w, h, C_DMA_FILL, C_DMA_EDGE, "AXI DMA", fs=8.2,
            txtcolor="#FFFFFF", weight="bold")
        harrow(ax, noc_x + noc_w, dma_x, yc, "", C_AXARR_FILL, C_AXARR_EDGE,
               bh=1.5, hh=2.7, hl=1.3)
        box(ax, ff_x, r[0], ff_w, h, C_MAC_FILL, C_MAC_EDGE, "TX / RX\nFIFOs", fs=7.6)
        harrow(ax, dma_x + dma_w, ff_x, yc, "", C_AXARR_FILL, C_AXARR_EDGE,
               bh=1.5, hh=2.7, hl=1.2)
        box(ax, xxv_x, r[0], xxv_w, h, C_XXV_FILL, C_XXV_EDGE, "xxv_ethernet",
            fs=8.0, weight="bold", lw=1.5)
        harrow(ax, ff_x + ff_w, xxv_x, yc, "", C_AXARR_FILL, C_AXARR_EDGE,
               bh=1.5, hh=2.7, hl=1.2)
        box(ax, bg_x, r[0] + 3.4, bg_w, h - 6.6, C_CLK_FILL, C_CLK_EDGE,
            "BUFG_GT x2", fs=7.0)

    # shared GT quad
    titled_box(ax, gt_x, 29.0, gt_w, 84.0, C_GT_FILL, C_GT_EDGE, "gt_quad_\nbase_0",
               "\n\nGTY\n(VCK190,\nVMK180)\n\nGTYP\n(VEK280,\nVHK158,\nVPK120,\n"
               "VPK180)\n\n4 channels\nRPLL\n(forced)",
               title_fs=8.6, body_fs=6.6, title_dy=3.6)
    for p, r in enumerate([P0] + ROWS):
        yc = row_yc(r)
        if p:
            # route serdes interfaces past the BUFG_GT box (below it)
            harrow(ax, xxv_x + xxv_w, gt_x, r[0] + 1.4, "", C_AXARR_FILL,
                   C_AXARR_EDGE, bh=0.9, hh=1.7, hl=0.9)
        else:
            harrow(ax, xxv_x + xxv_w, gt_x, yc, "", C_AXARR_FILL, C_AXARR_EDGE,
                   bh=0.7, hh=1.0, hl=0.9)

    draw_fmc(ax, gt_r, 145.0, 167.0, "156.25 MHz\n(IBUFDSGTE)")

    # bottom strip: clocking, sideband, control plane
    titled_box(ax, 27.0, 5.0, 36.0, 21.0, C_CLK_FILL, C_CLK_EDGE,
               "Clocking (clk_wizard_0 from pl0_ref_clk)",
               "156.25 MHz: AXI-Lite, DMA SG, NoC,\nAXI IIC, AXI GPIO\n\n"
               "100 MHz: GT quad APB3,\nXXV GT reset free-run clock\n\n"
               "GT refclk: 156.25 MHz (Si5328)",
               title_fs=7.8, body_fs=6.6, title_dy=2.8)
    titled_box(ax, 65.0, 5.0, 30.0, 21.0, C_CTRL_FILL, C_CTRL_EDGE,
               "SFP sideband (per port)",
               "green LED = present AND no RX_LOS\nred LED = present AND RX_LOS\n\n"
               "TX_DISABLE, RATE_SEL0/1:\ntied low\nTX_FAULT: not used",
               title_fs=8.4, body_fs=6.5, title_dy=2.8)
    titled_box(ax, 97.0, 5.0, 42.0, 21.0, C_CTRL_FILL, C_CTRL_EDGE,
               "Control plane: AXI-Lite (axi_smc)",
               "per port: XXV + AXI DMA (local SmartConnect)\n"
               "AXI IIC (FMC I2C)\n"
               "AXI GPIO: MOD_ABS[3:0] (in)\n\n"
               "interrupts: 2 per DMA + IIC → pl_ps_irq",
               title_fs=8.2, body_fs=6.6, title_dy=2.8)
    route(ax, [(ps_r - 6.0, 31.0), (ps_r - 6.0, 28.4), (118.0, 28.4), (118.0, 26.0)],
          C_PS_EDGE, lw=1.6)
    note(ax, 42.0, 27.2, "M_AXI_LPD (AXI-Lite)", fs=6.6)
    route(ax, [(139.0, 15.5), (147.0, 15.5)], C_NOTE, lw=1.4)
    note(ax, 143.0, 17.6, "I2C", fs=6.3)

    fig.savefig(out, bbox_inches="tight", pad_inches=0.15, facecolor="white")
    plt.close(fig)
    print("wrote", out)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    zynqmp(os.path.join(here, "zynqmp-xxv-eth-block-diagram.png"))
    versal(os.path.join(here, "versal-xxv-eth-block-diagram.png"))


if __name__ == "__main__":
    main()
