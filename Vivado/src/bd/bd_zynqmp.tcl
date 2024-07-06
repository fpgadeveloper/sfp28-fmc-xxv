################################################################
# Block design build script for Zynq US+ designs
################################################################

# Returns true if str contains substr
proc str_contains {str substr} {
  if {[string first $substr $str] == -1} {
    return 0
  } else {
    return 1
  }
}

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $block_name

current_bd_design $block_name

set parentCell [get_bd_cells /]

# Get object for parentCell
set parentObj [get_bd_cells $parentCell]
if { $parentObj == "" } {
   puts "ERROR: Unable to find parent cell <$parentCell>!"
   return
}

# Make sure parentObj is hier blk
set parentType [get_property TYPE $parentObj]
if { $parentType ne "hier" } {
   puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
   return
}

# Save current instance; Restore later
set oldCurInst [current_bd_instance .]

# Set parent object as current
current_bd_instance $parentObj

# AXI Lite ports
set hpm0_lpd_ports {}

# List of interrupt pins (AXI Intc and direct PL-PS-IRQ1)
set intr_list {}
set priority_intr_list {}

# Add the Processor System and apply board preset
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]

# Configure the PS: Enable HP0 and HP1 (for dual designs) to DDR
set_property -dict [list CONFIG.PSU__USE__S_AXI_GP2 {1} \
CONFIG.PSU__USE__S_AXI_GP3 {0} \
CONFIG.PSU__USE__M_AXI_GP0 {0} \
CONFIG.PSU__USE__M_AXI_GP1 {0} \
CONFIG.PSU__USE__M_AXI_GP2 {1} \
CONFIG.PSU__USE__IRQ0 {1} \
CONFIG.PSU__HIGH_ADDRESS__ENABLE {1}] [get_bd_cells zynq_ultra_ps_e_0]

# Connect the PS clocks
#connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk]
#connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk]
#connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]

# Add proc system reset for PL clock 100MHz
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ps_100m
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins rst_ps_100m/slowest_sync_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins rst_ps_100m/ext_reset_in]

#########################################################
# 10G Ethernet core
#########################################################

# Add the 10G Ethernet
create_bd_cell -type ip -vlnv xilinx.com:ip:xxv_ethernet xxv_ethernet_0
set_property CONFIG.BASE_R_KR {BASE-R} [get_bd_cells xxv_ethernet_0]
lappend hpm0_lpd_ports [list "xxv_ethernet_0/s_axi_0" "zynq_ultra_ps_e_0/pl_clk0" "rst_ps_100m/peripheral_aresetn"]

# Clocks
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins xxv_ethernet_0/dclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins xxv_ethernet_0/s_axi_aclk_0]
connect_bd_net [get_bd_pins xxv_ethernet_0/rx_clk_out_0] [get_bd_pins xxv_ethernet_0/rx_core_clk_0]

# Resets
connect_bd_net [get_bd_pins rst_ps_100m/peripheral_reset] [get_bd_pins xxv_ethernet_0/sys_reset]
connect_bd_net [get_bd_pins rst_ps_100m/peripheral_aresetn] [get_bd_pins xxv_ethernet_0/s_axi_aresetn_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_not
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_not]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins logic_not/Op1]
connect_bd_net [get_bd_pins logic_not/Res] [get_bd_pins xxv_ethernet_0/gtwiz_reset_tx_datapath_0]
connect_bd_net [get_bd_pins logic_not/Res] [get_bd_pins xxv_ethernet_0/gtwiz_reset_rx_datapath_0]

# Constants for 10G Ethernet core
set const_low [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_low ]
set_property CONFIG.CONST_VAL {0} [get_bd_cells const_low]
connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins xxv_ethernet_0/ctl_tx_send_idle_0]
connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins xxv_ethernet_0/ctl_tx_send_lfi_0]
connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins xxv_ethernet_0/ctl_tx_send_rfi_0]

set const_clksel [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_clksel ]
set_property -dict [list CONFIG.CONST_VAL {5} CONFIG.CONST_WIDTH {3} ] [get_bd_cells const_clksel]
connect_bd_net [get_bd_pins const_clksel/dout] [get_bd_pins xxv_ethernet_0/txoutclksel_in_0]
connect_bd_net [get_bd_pins const_clksel/dout] [get_bd_pins xxv_ethernet_0/rxoutclksel_in_0]

set const_preamble [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_preamble ]
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {56} ] [get_bd_cells const_preamble]
connect_bd_net [get_bd_pins const_preamble/dout] [get_bd_pins xxv_ethernet_0/tx_preamblein_0]

# Add MGT external port
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 eth0_gt
connect_bd_intf_net [get_bd_intf_pins xxv_ethernet_0/gt_serial_port] [get_bd_intf_ports eth0_gt]

# Add MGT ref clock port
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 eth0_ref_clk
set_property CONFIG.FREQ_HZ 156250000 [get_bd_intf_ports /eth0_ref_clk]
connect_bd_intf_net [get_bd_intf_pins xxv_ethernet_0/gt_ref_clk] [get_bd_intf_ports eth0_ref_clk]

#########################################################
# AXI DMA
#########################################################

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_dma_eth0
lappend hpm0_lpd_ports [list "axi_dma_eth0/S_AXI_LITE" "zynq_ultra_ps_e_0/pl_clk0" "rst_ps_100m/peripheral_aresetn"]

set_property -dict [list CONFIG.c_s_axis_s2mm_tdata_width.VALUE_SRC USER CONFIG.c_m_axi_s2mm_data_width.VALUE_SRC USER] [get_bd_cells axi_dma_eth0]
set_property -dict [list \
  CONFIG.c_include_sg {1} \
  CONFIG.c_m_axi_mm2s_data_width {64} \
  CONFIG.c_m_axis_mm2s_tdata_width {64} \
  CONFIG.c_mm2s_burst_size {64} \
  CONFIG.c_sg_include_stscntrl_strm {0} \
  CONFIG.c_sg_length_width {16} \
  CONFIG.c_include_mm2s_dre {1} \
  CONFIG.c_include_s2mm_dre {1} \
  CONFIG.c_m_axi_s2mm_data_width {64} \
  CONFIG.c_s_axis_s2mm_tdata_width {64} \
] [get_bd_cells axi_dma_eth0]

# Clocks
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_dma_eth0/s_axi_lite_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_dma_eth0/m_axi_sg_aclk]
connect_bd_net [get_bd_pins xxv_ethernet_0/tx_clk_out_0] [get_bd_pins axi_dma_eth0/m_axi_mm2s_aclk]
connect_bd_net [get_bd_pins xxv_ethernet_0/rx_clk_out_0] [get_bd_pins axi_dma_eth0/m_axi_s2mm_aclk]

# Resets
connect_bd_net [get_bd_pins rst_ps_100m/peripheral_aresetn] [get_bd_pins axi_dma_eth0/axi_resetn]

# DMA TX reset
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_dma_tx_rst_eth0
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_dma_tx_rst_eth0]
connect_bd_net [get_bd_pins axi_dma_eth0/mm2s_prmry_reset_out_n] [get_bd_pins logic_dma_tx_rst_eth0/Op1]
connect_bd_net [get_bd_pins logic_dma_tx_rst_eth0/Res] [get_bd_pins xxv_ethernet_0/tx_reset_0]

# DMA RX reset
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_dma_rx_rst_eth0
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_dma_rx_rst_eth0]
connect_bd_net [get_bd_pins axi_dma_eth0/s2mm_prmry_reset_out_n] [get_bd_pins logic_dma_rx_rst_eth0/Op1]
connect_bd_net [get_bd_pins logic_dma_rx_rst_eth0/Res] [get_bd_pins xxv_ethernet_0/rx_reset_0]

# Interrupts
lappend priority_intr_list "axi_dma_eth0/mm2s_introut"
lappend priority_intr_list "axi_dma_eth0/s2mm_introut"

# AXI Interconnect for HP0 interface
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_int_hp0
set_property -dict [list \
  CONFIG.NUM_MI {1} \
  CONFIG.NUM_SI {3} \
] [get_bd_cells axi_int_hp0]
connect_bd_intf_net [get_bd_intf_pins axi_dma_eth0/M_AXI_SG] -boundary_type upper [get_bd_intf_pins axi_int_hp0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_eth0/M_AXI_MM2S] -boundary_type upper [get_bd_intf_pins axi_int_hp0/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_eth0/M_AXI_S2MM] -boundary_type upper [get_bd_intf_pins axi_int_hp0/S02_AXI]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_int_hp0/ACLK]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_int_hp0/S00_ACLK]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_int_hp0/M00_ACLK]
connect_bd_net [get_bd_pins rst_ps_100m/interconnect_aresetn] [get_bd_pins axi_int_hp0/ARESETN]
connect_bd_net [get_bd_pins rst_ps_100m/peripheral_aresetn] [get_bd_pins axi_int_hp0/S00_ARESETN]
connect_bd_net [get_bd_pins rst_ps_100m/peripheral_aresetn] [get_bd_pins axi_int_hp0/M00_ARESETN]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_int_hp0/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
connect_bd_net [get_bd_pins xxv_ethernet_0/tx_clk_out_0] [get_bd_pins axi_int_hp0/S01_ACLK]
connect_bd_net [get_bd_pins xxv_ethernet_0/rx_clk_out_0] [get_bd_pins axi_int_hp0/S02_ACLK]

# MAC TX reset
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_tx_rst_eth0
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_tx_rst_eth0]
connect_bd_net [get_bd_pins xxv_ethernet_0/user_tx_reset_0] [get_bd_pins logic_tx_rst_eth0/Op1]
connect_bd_net [get_bd_pins logic_tx_rst_eth0/Res] [get_bd_pins axi_int_hp0/S01_ARESETN]

# MAC RX reset
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_rx_rst_eth0
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_rx_rst_eth0]
connect_bd_net [get_bd_pins xxv_ethernet_0/user_rx_reset_0] [get_bd_pins logic_rx_rst_eth0/Op1]
connect_bd_net [get_bd_pins logic_rx_rst_eth0/Res] [get_bd_pins axi_int_hp0/S02_ARESETN]

# TX AXI4-Stream Data FIFO
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo tx_data_fifo_eth0
set_property -dict [list CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells tx_data_fifo_eth0]
set_property -dict [list \
  CONFIG.FIFO_DEPTH {32768} \
  CONFIG.HAS_RD_DATA_COUNT {1} \
  CONFIG.HAS_TKEEP {1} \
  CONFIG.HAS_TLAST {1} \
  CONFIG.HAS_WR_DATA_COUNT {1} \
  CONFIG.TDATA_NUM_BYTES {8} \
  CONFIG.FIFO_MODE {2} \
] [get_bd_cells tx_data_fifo_eth0]
connect_bd_intf_net [get_bd_intf_pins axi_dma_eth0/M_AXIS_MM2S] [get_bd_intf_pins tx_data_fifo_eth0/S_AXIS]
connect_bd_net [get_bd_pins logic_tx_rst_eth0/Res] [get_bd_pins tx_data_fifo_eth0/s_axis_aresetn]
connect_bd_net [get_bd_pins xxv_ethernet_0/tx_clk_out_0] [get_bd_pins tx_data_fifo_eth0/s_axis_aclk]
connect_bd_intf_net [get_bd_intf_pins tx_data_fifo_eth0/M_AXIS] [get_bd_intf_pins xxv_ethernet_0/axis_tx_0]

# RX AXI4-Stream Data FIFO
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo rx_data_fifo_eth0
set_property -dict [list CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells tx_data_fifo_eth0]
set_property -dict [list \
  CONFIG.FIFO_DEPTH {32768} \
  CONFIG.FIFO_MODE {2} \
  CONFIG.HAS_RD_DATA_COUNT {1} \
  CONFIG.HAS_TKEEP {1} \
  CONFIG.HAS_WR_DATA_COUNT {1} \
  CONFIG.TDATA_NUM_BYTES {8} \
  CONFIG.TUSER_WIDTH {1} \
] [get_bd_cells rx_data_fifo_eth0]
connect_bd_intf_net [get_bd_intf_pins xxv_ethernet_0/axis_rx_0] [get_bd_intf_pins rx_data_fifo_eth0/S_AXIS]
connect_bd_net [get_bd_pins logic_rx_rst_eth0/Res] [get_bd_pins rx_data_fifo_eth0/s_axis_aresetn]
connect_bd_net [get_bd_pins xxv_ethernet_0/rx_clk_out_0] [get_bd_pins rx_data_fifo_eth0/s_axis_aclk]
connect_bd_intf_net [get_bd_intf_pins rx_data_fifo_eth0/M_AXIS] [get_bd_intf_pins axi_dma_eth0/S_AXIS_S2MM]

#########################################################
# PL I2C
#########################################################

# Add and configure AXI IIC
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0
lappend hpm0_lpd_ports [list "axi_iic_0/S_AXI" "zynq_ultra_ps_e_0/pl_clk0" "rst_ps_100m/peripheral_aresetn"]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_iic_0/s_axi_aclk]
connect_bd_net [get_bd_pins rst_ps_100m/peripheral_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn]
lappend priority_intr_list "axi_iic_0/iic2intc_irpt"
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 i2c
connect_bd_intf_net [get_bd_intf_ports i2c] [get_bd_intf_pins axi_iic_0/IIC]

#########################################################
# SFP ports
#########################################################
#
# User LED configuration:
# -------------------------------------------------------
#
#               -----
# /MOD_ABS --->|     |
#              | AND |----> GREEN LED
#  /RX_LOS --->|     |
#               -----
#
#               -----
# /MOD_ABS --->|     |
#              | AND |----> RED LED
#   RX_LOS --->|     |
#               -----
#
# User LED behavior:
# -------------------------------------------------------
#
#   * Both LEDs are OFF when no SFP module is present
#   * Green LED ON when SFP module present and no loss of signal
#   * Red LED ON when SFP module present and loss of signal
#

proc create_sfp_port {label} {

  # Create hierarchical block for the SFP port logic
  set hier_obj [create_bd_cell -type hier sfp_port$label]
  current_bd_instance $hier_obj

  # Create pins for this block
  create_bd_pin -dir O tx_disable
  create_bd_pin -dir O rate_sel0
  create_bd_pin -dir O rate_sel1
  create_bd_pin -dir I mod_abs
  create_bd_pin -dir I rx_los
  create_bd_pin -dir O grn_led
  create_bd_pin -dir O red_led

  # Create constants HIGH and LOW for the SFP I/Os
  set const_high [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_high ]
  set_property -dict [list CONFIG.CONST_VAL {1}] $const_high
  set const_low [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_low ]
  set_property -dict [list CONFIG.CONST_VAL {0}] $const_low

  # TX DISABLE - LOW
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins tx_disable]
  # RATE SEL 0 - LOW
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins rate_sel0]
  # RATE SEL 1 - LOW
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins rate_sel1]
  # MOD_ABS - Module absent input
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_not_mod_abs
  set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_not_mod_abs]
  connect_bd_net [get_bd_pins mod_abs] [get_bd_pins logic_not_mod_abs/Op1]
  # RX LOS - Receiver Loss of Signal input
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_not_rx_los
  set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_not_rx_los]
  connect_bd_net [get_bd_pins rx_los] [get_bd_pins logic_not_rx_los/Op1]
  # And gate to drive the green LED
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_and_grn_led
  set_property -dict [list CONFIG.C_OPERATION {and} CONFIG.C_SIZE {1} ] [get_bd_cells logic_and_grn_led]
  connect_bd_net [get_bd_pins logic_not_mod_abs/Res] [get_bd_pins logic_and_grn_led/Op1]
  connect_bd_net [get_bd_pins logic_not_rx_los/Res] [get_bd_pins logic_and_grn_led/Op2]
  connect_bd_net [get_bd_pins logic_and_grn_led/Res] [get_bd_pins grn_led]
  # And gate to drive the red LED
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_and_red_led
  set_property -dict [list CONFIG.C_OPERATION {and} CONFIG.C_SIZE {1} ] [get_bd_cells logic_and_red_led]
  connect_bd_net [get_bd_pins logic_not_mod_abs/Res] [get_bd_pins logic_and_red_led/Op1]
  connect_bd_net [get_bd_pins rx_los] [get_bd_pins logic_and_red_led/Op2]
  connect_bd_net [get_bd_pins logic_and_red_led/Res] [get_bd_pins red_led]

  # Restore current instance
  current_bd_instance \

  # Create external ports
  create_bd_port -dir O tx_disable_sfp$label
  create_bd_port -dir O rate_sel0_sfp$label
  create_bd_port -dir O rate_sel1_sfp$label
  create_bd_port -dir I mod_abs_sfp$label
  create_bd_port -dir I rx_los_sfp$label
  create_bd_port -dir O grn_led_sfp$label
  create_bd_port -dir O red_led_sfp$label

  # Connect external ports to the block pins
  connect_bd_net [get_bd_pins sfp_port$label/tx_disable] [get_bd_ports tx_disable_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/rate_sel0] [get_bd_ports rate_sel0_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/rate_sel1] [get_bd_ports rate_sel1_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/mod_abs] [get_bd_ports mod_abs_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/rx_los] [get_bd_ports rx_los_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/grn_led] [get_bd_ports grn_led_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/red_led] [get_bd_ports red_led_sfp$label]

}


# Create each port
foreach label {0 1 2 3} {
  create_sfp_port $label
}


#########################################################
# AXI Interfaces and interrupts
#########################################################

# Add AXI Interconnect for the AXI Lite interfaces

proc create_axi_ic {label clk proc_rst master master_clk ports} {
  # Connect the master clock
  connect_bd_net [get_bd_pins $clk] [get_bd_pins $master_clk]
  # Create the AXI interconnect
  set n_periph_ports [llength $ports]
  set axi_ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect $label]
  set_property -dict [list CONFIG.NUM_MI $n_periph_ports] $axi_ic
  connect_bd_net [get_bd_pins $clk] [get_bd_pins $label/ACLK]
  connect_bd_net [get_bd_pins $clk] [get_bd_pins $label/S00_ACLK]
  connect_bd_net [get_bd_pins $proc_rst/interconnect_aresetn] [get_bd_pins $label/ARESETN]
  connect_bd_net [get_bd_pins $proc_rst/peripheral_aresetn] [get_bd_pins $label/S00_ARESETN]
  connect_bd_intf_net [get_bd_intf_pins $master] -boundary_type upper [get_bd_intf_pins $label/S00_AXI]
  # Attach all of the ports, their clocks and resets
  set port_num 0
  foreach port $ports {
    set port_label [lindex $port 0]
    connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $label/M0${port_num}_AXI] [get_bd_intf_pins $port_label]
    set port_clk [lindex $port 1]
    connect_bd_net [get_bd_pins $port_clk] [get_bd_pins $label/M0${port_num}_ACLK]
    set port_rst [lindex $port 2]
    connect_bd_net [get_bd_pins $port_rst] [get_bd_pins $label/M0${port_num}_ARESETN]
    set port_num [expr {$port_num+1}]
  }
}

# HPM0 LPD
create_axi_ic "ps_axi_periph" "zynq_ultra_ps_e_0/pl_clk0" "rst_ps_100m" \
  "zynq_ultra_ps_e_0/M_AXI_HPM0_LPD" "zynq_ultra_ps_e_0/maxihpm0_lpd_aclk" $hpm0_lpd_ports

#########################################################
# PL-to-PS interrupts
#########################################################

# Connect the interrupts (direct to PL-PS interrupt) to pl_ps_irq0
set p_intr_concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat p_intr_concat]
connect_bd_net [get_bd_pins p_intr_concat/dout] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]
set_property -dict [list CONFIG.NUM_PORTS 8] $p_intr_concat
set n_interrupts [llength $priority_intr_list]
set intr_index 0
foreach intr $priority_intr_list {
  connect_bd_net [get_bd_pins $intr] [get_bd_pins ${p_intr_concat}/In$intr_index]
  set intr_index [expr {$intr_index+1}]
}

# Assign addresses
assign_bd_address

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
