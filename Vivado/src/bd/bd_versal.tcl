################################################################
# Block design build script for Versal designs
################################################################

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

# Returns true if str contains substr
proc str_contains {str substr} {
  if {[string first $substr $str] == -1} {
    return 0
  } else {
    return 1
  }
}

# Target board checks
set is_vck190 [str_contains $board_name "vck190"]
set is_vmk180 [str_contains $board_name "vmk180"]
set is_vek280 [str_contains $board_name "vek280"]
set is_vpk120 [str_contains $board_name "vpk120"]

# SGMII PHY addresses
set sgmii_phy_addr {2 4 13 14}

# Number of ports
set num_ports [llength $ports]

# List of interrupt pins
set intr_list {}

# Initialize the list of unused ports
set unused_ports {}

# Work out which ports of the Quad SFP28 FMC are not used in this design
foreach port {0 1 2 3} {
    # Check if the current port is not in the ports list
    if { [lsearch -exact $ports $port] == -1 } {
        # Add the port to the unused_ports list
        lappend unused_ports $port
    }
}

# Add the CIPS
create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0

# Configure the CIPS using automation feature
if {$is_vpk120 || $is_vek280} {
  apply_bd_automation -rule xilinx.com:bd_rule:cips -config { \
    board_preset {Yes} \
    boot_config {Custom} \
    configure_noc {Add new AXI NoC} \
    debug_config {JTAG} \
    design_flow {Full System} \
    mc_type {LPDDR} \
    num_mc_ddr {None} \
    num_mc_lpddr {1} \
    pl_clocks {None} \
    pl_resets {None} \
  }  [get_bd_cells versal_cips_0]
} else {
  apply_bd_automation -rule xilinx.com:bd_rule:cips -config { \
    board_preset {Yes} \
    boot_config {Custom} \
    configure_noc {Add new AXI NoC} \
    debug_config {JTAG} \
    design_flow {Full System} \
    mc_type {DDR} \
    num_mc_ddr {1} \
    num_mc_lpddr {None} \
    pl_clocks {None} \
    pl_resets {None} \
  }  [get_bd_cells versal_cips_0]
}

# Extra PS PMC config for this design
# -----------------------------------
# - Clocking -> Output clocks -> PMC domain clocks -> PL Fabric clocks -> PL CLK0: Enable 100MHz
# - Clocking -> Output clocks -> PMC domain clocks -> PL Fabric clocks -> PL CLK1: Enable 50MHz
# - PL resets: 1
# - M_AXI_LPD: enable
# - PL to PS interrupts: enable ALL (IRQ0-15)
if {$is_vpk120} {
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {100} \
      PMC_CRP_PL1_REF_CTRL_FREQMHZ {50} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 39 .. 40}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 1} {CH11 1} {CH12 1} {CH13 1} {CH14 1} {CH15 1} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 1} {CH7 1} {CH8 1} {CH9 1}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
      PS_PCIE_EP_RESET2_IO {PS_MIO 19} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {1} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_INTERFACE_TO_USE {I2C} \
      SMON_PMBUS_ADDRESS {0x18} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] [get_bd_cells versal_cips_0]
} elseif {$is_vek280} {
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {100} \
      PMC_CRP_PL1_REF_CTRL_FREQMHZ {50} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO12 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_OSPI_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 39 .. 40}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 1} {CH11 1} {CH12 1} {CH13 1} {CH14 1} {CH15 1} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 1} {CH7 1} {CH8 1} {CH9 1}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
      PS_PCIE_EP_RESET2_IO {PS_MIO 19} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {1} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      PS_USE_S_AXI_FPD {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_INTERFACE_TO_USE {I2C} \
      SMON_PMBUS_ADDRESS {0x18} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] [get_bd_cells versal_cips_0]
} else {
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {100} \
      PMC_CRP_PL1_REF_CTRL_FREQMHZ {50} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_QSPI_COHERENCY {0} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_COHERENCY {0} \
      PMC_SD1_DATA_TRANSFER_MODE {8Bit} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 40 .. 41}}} \
      PS_CRL_CAN1_REF_CTRL_FREQMHZ {160} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_ENET1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 12 .. 23}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 1} {CH11 1} {CH12 1} {CH13 1} {CH14 1} {CH15 1} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 1} {CH7 1} {CH8 1} {CH9 1}} \
      PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
      PS_PCIE_EP_RESET2_IO {PMC_MIO 39} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {1} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] [get_bd_cells versal_cips_0]
}

# Add clock wizard to generate 125MHz and 100MHz
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0
set_property -dict [list \
  CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
  CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
  CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
  CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
  CONFIG.CLKOUT_PORT {clk_156m25,clk_100m,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
  CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
  CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {156.25,100.000,100.000,100.000,100.000,100.000,100.000} \
  CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
  CONFIG.CLKOUT_USED {true,true,false,false,false,false,false} \
] [get_bd_cells clk_wizard_0]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins clk_wizard_0/clk_in1]

# System clock (100MHz)
set sys_clk "clk_wizard_0/clk_156m25"

# Add system clock and 4x3 input ports for the AXI DMAs to the NOC MC
set_property -dict [list CONFIG.NUM_CLKS {15} CONFIG.NUM_SI {18}] [get_bd_cells axi_noc_0]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S05_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S06_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S07_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S08_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S09_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S10_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S11_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S12_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S13_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S14_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S15_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S16_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S17_AXI]
connect_bd_net [get_bd_pins $sys_clk] [get_bd_pins axi_noc_0/aclk6]
set noc_port_index 6
set noc_clk_index 7

# Connect the AXI interface clocks
connect_bd_net [get_bd_pins $sys_clk] [get_bd_pins versal_cips_0/m_axi_lpd_aclk]

# Proc system reset for main clock
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_156m25
connect_bd_net [get_bd_pins $sys_clk] [get_bd_pins rst_156m25/slowest_sync_clk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_resetn] [get_bd_pins rst_156m25/ext_reset_in]

# Proc system reset for 100M clock
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_100m
connect_bd_net [get_bd_pins $sys_clk] [get_bd_pins rst_100m/slowest_sync_clk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_resetn] [get_bd_pins rst_100m/ext_reset_in]

# AXI SmartConnect for AXI Lite interfaces
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc
set_property -dict [list CONFIG.NUM_MI {5} CONFIG.NUM_SI {1} ] [get_bd_cells axi_smc]
connect_bd_net [get_bd_pins $sys_clk] [get_bd_pins axi_smc/aclk]
connect_bd_net [get_bd_pins rst_156m25/interconnect_aresetn] [get_bd_pins axi_smc/aresetn]
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_LPD] [get_bd_intf_pins axi_smc/S00_AXI]

# GT ref clock and utility buffer
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_ref_clk
set_property CONFIG.FREQ_HZ 156250000 [get_bd_intf_ports /gt_ref_clk]
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf_0
set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} [get_bd_cells util_ds_buf_0]
connect_bd_intf_net [get_bd_intf_ports gt_ref_clk] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]

# GT Quad base (Transceiver wizard)
create_bd_cell -type ip -vlnv xilinx.com:ip:gt_quad_base gt_quad_base_0
connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins gt_quad_base_0/GT_REFCLK0]
connect_bd_net [get_bd_pins clk_wizard_0/clk_100m] [get_bd_pins gt_quad_base_0/apb3clk]
connect_bd_net [get_bd_pins rst_100m/peripheral_aresetn] [get_bd_pins gt_quad_base_0/apb3presetn]

# SFP GT interface
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 sfp_gt
connect_bd_intf_net [get_bd_intf_pins gt_quad_base_0/GT_Serial] [get_bd_intf_ports sfp_gt]

#########################################################
# PL I2C
#########################################################

# Add and configure AXI IIC
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0
connect_bd_intf_net [get_bd_intf_pins axi_smc/M04_AXI] [get_bd_intf_pins axi_iic_0/S_AXI]
connect_bd_net [get_bd_pins $sys_clk] [get_bd_pins axi_iic_0/s_axi_aclk]
connect_bd_net [get_bd_pins rst_156m25/peripheral_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn]
lappend intr_list "axi_iic_0/iic2intc_irpt"
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 i2c
connect_bd_intf_net [get_bd_intf_ports i2c] [get_bd_intf_pins axi_iic_0/IIC]

#########################################################
# SFP ports
#########################################################
#
# This procedure creates a hierarchical block that contains
# the 10G/25G Ethernet Subsystem, AXI DMA, the TX/RX FIFOs 
# and the SFP I/O logic for a single SFP slot.
# 
# User LED configuration:
# -------------------------------------------------------
#
# TX_FAULT --X
#               -----
# /MOD_ABS --->|     |
#              | AND |----> GREEN LED
#  /RX_LOS --->|     |
#               -----
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
#   * TX_FAULT signals are not connected (not used)
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
  create_bd_pin -dir I tx_fault
  create_bd_pin -dir O grn_led
  create_bd_pin -dir O red_led
  create_bd_pin -dir O dma_mm2s_introut
  create_bd_pin -dir O dma_s2mm_introut
  create_bd_pin -dir I sys_clk
  create_bd_pin -dir I txoutclk
  create_bd_pin -dir I rxoutclk
  create_bd_pin -dir O txusrclk
  create_bd_pin -dir O rxusrclk
  create_bd_pin -dir I periph_rstn
  create_bd_pin -dir I intercon_rstn
  create_bd_pin -dir I gtpowergood_in
  create_bd_pin -dir I apb3clk
  create_bd_pin -dir O -from 2 -to 0 gtwiz_loopback
  create_bd_pin -dir O -from 4 -to 0 gtwiz_txprecursor
  create_bd_pin -dir O -from 4 -to 0 gtwiz_txpostcursor
  create_bd_pin -dir O -from 6 -to 0 gtwiz_txmaincursor

  # Create interfaces for this block
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_sg
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mm2s
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_s2mm
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_tx_interface_rtl:1.0 gt_tx_serdes_interface
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rx_interface_rtl:1.0 gt_rx_serdes_interface

  #########################################################
  # AXI 10G/25G Ethernet Subsystem
  #########################################################
  create_bd_cell -type ip -vlnv xilinx.com:ip:xxv_ethernet xxv_ethernet
  set_property -dict [list \
    CONFIG.BASE_R_KR {BASE-R} \
    CONFIG.GT_REF_CLK_FREQ {156.25} \
    CONFIG.LINE_RATE {10} \
  ] [get_bd_cells xxv_ethernet]

  # Clocks and reset
  connect_bd_net [get_bd_pins sys_clk] [get_bd_pins xxv_ethernet/s_axi_aclk_0]
  connect_bd_net [get_bd_pins periph_rstn] [get_bd_pins xxv_ethernet/s_axi_aresetn_0]
  connect_bd_net [get_bd_pins apb3clk] [get_bd_pins xxv_ethernet/gtwiz_reset_clk_freerun_in_0]

  # GT connections
  connect_bd_net [get_bd_pins gtpowergood_in] [get_bd_pins xxv_ethernet/gtpowergood_in_0]
  connect_bd_net [get_bd_pins xxv_ethernet/gtwiz_loopback_0] [get_bd_pins gtwiz_loopback]
  connect_bd_net [get_bd_pins xxv_ethernet/gtwiz_txprecursor_0] [get_bd_pins gtwiz_txprecursor]
  connect_bd_net [get_bd_pins xxv_ethernet/gtwiz_txpostcursor_0] [get_bd_pins gtwiz_txpostcursor]
  connect_bd_net [get_bd_pins xxv_ethernet/gtwiz_txmaincursor_0] [get_bd_pins gtwiz_txmaincursor]

  #########################################################
  # AXI DMA
  #########################################################

  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_dma

  set_property -dict [list CONFIG.c_s_axis_s2mm_tdata_width.VALUE_SRC USER CONFIG.c_m_axi_s2mm_data_width.VALUE_SRC USER] [get_bd_cells axi_dma]
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
  ] [get_bd_cells axi_dma]

  # Clocks
  connect_bd_net [get_bd_pins sys_clk] [get_bd_pins axi_dma/s_axi_lite_aclk]
  connect_bd_net [get_bd_pins sys_clk] [get_bd_pins axi_dma/m_axi_sg_aclk]

  # BUFGTs
  create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_txoutclk
  set_property CONFIG.FREQ_HZ {156250000} [get_bd_cells bufg_gt_txoutclk]
  connect_bd_net [get_bd_pins txoutclk] [get_bd_pins bufg_gt_txoutclk/outclk]
  connect_bd_net [get_bd_pins bufg_gt_txoutclk/usrclk] [get_bd_pins axi_dma/m_axi_mm2s_aclk]
  connect_bd_net [get_bd_pins bufg_gt_txoutclk/usrclk] [get_bd_pins xxv_ethernet/tx_core_clk_0]
  connect_bd_net [get_bd_pins bufg_gt_txoutclk/usrclk] [get_bd_pins txusrclk]

  create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_rxoutclk
  set_property CONFIG.FREQ_HZ {156250000} [get_bd_cells bufg_gt_rxoutclk]
  connect_bd_net [get_bd_pins rxoutclk] [get_bd_pins bufg_gt_rxoutclk/outclk]
  connect_bd_net [get_bd_pins bufg_gt_rxoutclk/usrclk] [get_bd_pins axi_dma/m_axi_s2mm_aclk]
  connect_bd_net [get_bd_pins bufg_gt_rxoutclk/usrclk] [get_bd_pins xxv_ethernet/rx_core_clk_0]
  connect_bd_net [get_bd_pins bufg_gt_rxoutclk/usrclk] [get_bd_pins xxv_ethernet/rx_serdes_clk_0]
  connect_bd_net [get_bd_pins bufg_gt_rxoutclk/usrclk] [get_bd_pins rxusrclk]

  # Reset logic (txusrclk)
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_s2mm_prmry_reset_out
  set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_s2mm_prmry_reset_out]
  connect_bd_net [get_bd_pins axi_dma/s2mm_prmry_reset_out_n] [get_bd_pins logic_s2mm_prmry_reset_out/Op1]

  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_tx_resetdone_out
  set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_tx_resetdone_out]
  connect_bd_net [get_bd_pins xxv_ethernet/tx_resetdone_out_0] [get_bd_pins logic_tx_resetdone_out/Op1]

  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_txusrclk_or
  set_property -dict [list CONFIG.C_OPERATION {or} CONFIG.C_SIZE {1} ] [get_bd_cells logic_txusrclk_or]
  connect_bd_net [get_bd_pins logic_s2mm_prmry_reset_out/Res] [get_bd_pins logic_txusrclk_or/Op1]
  connect_bd_net [get_bd_pins logic_tx_resetdone_out/Res] [get_bd_pins logic_txusrclk_or/Op2]

  # Reset logic (rxusrclk)
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_mm2s_prmry_reset_out
  set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_mm2s_prmry_reset_out]
  connect_bd_net [get_bd_pins axi_dma/mm2s_prmry_reset_out_n] [get_bd_pins logic_mm2s_prmry_reset_out/Op1]

  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_rx_resetdone_out
  set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1} ] [get_bd_cells logic_rx_resetdone_out]
  connect_bd_net [get_bd_pins xxv_ethernet/rx_resetdone_out_0] [get_bd_pins logic_rx_resetdone_out/Op1]
  connect_bd_net [get_bd_pins logic_rx_resetdone_out/Res] [get_bd_pins xxv_ethernet/rx_serdes_reset_0]

  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic logic_rxusrclk_or
  set_property -dict [list CONFIG.C_OPERATION {or} CONFIG.C_SIZE {1} ] [get_bd_cells logic_rxusrclk_or]
  connect_bd_net [get_bd_pins logic_mm2s_prmry_reset_out/Res] [get_bd_pins logic_rxusrclk_or/Op1]
  connect_bd_net [get_bd_pins logic_rx_resetdone_out/Res] [get_bd_pins logic_rxusrclk_or/Op2]

  # Resets for txusrclk and rxusrclk
  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_txusrclk
  connect_bd_net [get_bd_pins bufg_gt_txoutclk/usrclk] [get_bd_pins rst_txusrclk/slowest_sync_clk]
  connect_bd_net [get_bd_pins logic_txusrclk_or/Res] [get_bd_pins rst_txusrclk/ext_reset_in]
  connect_bd_net [get_bd_pins rst_txusrclk/peripheral_reset] [get_bd_pins xxv_ethernet/tx_reset_0]

  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_rxusrclk
  connect_bd_net [get_bd_pins bufg_gt_rxoutclk/usrclk] [get_bd_pins rst_rxusrclk/slowest_sync_clk]
  connect_bd_net [get_bd_pins logic_rxusrclk_or/Res] [get_bd_pins rst_rxusrclk/ext_reset_in]
  connect_bd_net [get_bd_pins rst_rxusrclk/peripheral_reset] [get_bd_pins xxv_ethernet/rx_reset_0]

  # Resets
  connect_bd_net [get_bd_pins periph_rstn] [get_bd_pins axi_dma/axi_resetn]

  # Interrupts
  connect_bd_net [get_bd_pins axi_dma/mm2s_introut] [get_bd_pins dma_mm2s_introut]
  connect_bd_net [get_bd_pins axi_dma/s2mm_introut] [get_bd_pins dma_s2mm_introut]

  # AXI SmartConnect for AXI lite interfaces of AXI DMA and AXI Ethernet
  create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc
  set_property CONFIG.NUM_MI {2} [get_bd_cells axi_smc]
  connect_bd_net [get_bd_pins sys_clk] [get_bd_pins axi_smc/aclk]
  connect_bd_net [get_bd_pins intercon_rstn] [get_bd_pins axi_smc/aresetn]
  connect_bd_intf_net [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_smc/S00_AXI]

  # AXI Lite interface
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_dma/S_AXI_LITE] [get_bd_intf_pins axi_smc/M00_AXI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins xxv_ethernet/s_axi_0] [get_bd_intf_pins axi_smc/M01_AXI]

  # DMA Memory mapped interfaces (to NOC)
  connect_bd_intf_net [get_bd_intf_pins axi_dma/M_AXI_SG] -boundary_type upper [get_bd_intf_pins m_axi_sg]
  connect_bd_intf_net [get_bd_intf_pins axi_dma/M_AXI_MM2S] -boundary_type upper [get_bd_intf_pins m_axi_mm2s]
  connect_bd_intf_net [get_bd_intf_pins axi_dma/M_AXI_S2MM] -boundary_type upper [get_bd_intf_pins m_axi_s2mm]

  # TX AXI4-Stream Data FIFO
  create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo tx_data_fifo
  set_property -dict [list CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells tx_data_fifo]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {32768} \
    CONFIG.HAS_RD_DATA_COUNT {0} \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.HAS_WR_DATA_COUNT {0} \
    CONFIG.TDATA_NUM_BYTES {8} \
    CONFIG.FIFO_MODE {2} \
  ] [get_bd_cells tx_data_fifo]
  connect_bd_intf_net [get_bd_intf_pins axi_dma/M_AXIS_MM2S] [get_bd_intf_pins tx_data_fifo/S_AXIS]
  connect_bd_net [get_bd_pins rst_txusrclk/peripheral_aresetn] [get_bd_pins tx_data_fifo/s_axis_aresetn]
  connect_bd_net [get_bd_pins bufg_gt_txoutclk/usrclk] [get_bd_pins tx_data_fifo/s_axis_aclk]
  connect_bd_intf_net [get_bd_intf_pins tx_data_fifo/M_AXIS] [get_bd_intf_pins xxv_ethernet/axis_tx_0]

  # RX AXI4-Stream Data FIFO
  create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo rx_data_fifo
  set_property -dict [list CONFIG.HAS_TKEEP.VALUE_SRC USER CONFIG.TDATA_NUM_BYTES.VALUE_SRC USER CONFIG.HAS_TLAST.VALUE_SRC USER] [get_bd_cells rx_data_fifo]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {32768} \
    CONFIG.FIFO_MODE {2} \
    CONFIG.HAS_RD_DATA_COUNT {0} \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_WR_DATA_COUNT {0} \
    CONFIG.TDATA_NUM_BYTES {8} \
    CONFIG.TUSER_WIDTH {1} \
  ] [get_bd_cells rx_data_fifo]
  connect_bd_intf_net [get_bd_intf_pins xxv_ethernet/axis_rx_0] [get_bd_intf_pins rx_data_fifo/S_AXIS]
  connect_bd_net [get_bd_pins rst_rxusrclk/peripheral_aresetn] [get_bd_pins rx_data_fifo/s_axis_aresetn]
  connect_bd_net [get_bd_pins bufg_gt_rxoutclk/usrclk] [get_bd_pins rx_data_fifo/s_axis_aclk]
  connect_bd_intf_net [get_bd_intf_pins rx_data_fifo/M_AXIS] [get_bd_intf_pins axi_dma/S_AXIS_S2MM]
  
  # GT SERDES interfaces
  connect_bd_intf_net [get_bd_intf_pins xxv_ethernet/gt_tx_serdes_interface_0] [get_bd_intf_pins gt_tx_serdes_interface]
  connect_bd_intf_net [get_bd_intf_pins xxv_ethernet/gt_rx_serdes_interface_0] [get_bd_intf_pins gt_rx_serdes_interface]

  #########################################################
  # SFP I/O
  #########################################################

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
}

# Create each SFP port
foreach label $ports {
  # Create the SFP port block
  create_sfp_port $label

  # Create external ports
  create_bd_port -dir O tx_disable_sfp$label
  create_bd_port -dir O rate_sel0_sfp$label
  create_bd_port -dir O rate_sel1_sfp$label
  create_bd_port -dir I mod_abs_sfp$label
  create_bd_port -dir I rx_los_sfp$label
  create_bd_port -dir I tx_fault_sfp$label
  create_bd_port -dir O grn_led_sfp$label
  create_bd_port -dir O red_led_sfp$label

  # Connect external ports to the block pins
  connect_bd_net [get_bd_pins sfp_port$label/tx_disable] [get_bd_ports tx_disable_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/rate_sel0] [get_bd_ports rate_sel0_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/rate_sel1] [get_bd_ports rate_sel1_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/mod_abs] [get_bd_ports mod_abs_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/rx_los] [get_bd_ports rx_los_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/tx_fault] [get_bd_ports tx_fault_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/grn_led] [get_bd_ports grn_led_sfp$label]
  connect_bd_net [get_bd_pins sfp_port$label/red_led] [get_bd_ports red_led_sfp$label]

  # Connect other block pins and interfaces
  connect_bd_net [get_bd_pins $sys_clk] [get_bd_pins sfp_port$label/sys_clk]
  connect_bd_net [get_bd_pins clk_wizard_0/clk_100m] [get_bd_pins sfp_port$label/apb3clk]
  connect_bd_net [get_bd_pins rst_156m25/interconnect_aresetn] [get_bd_pins sfp_port$label/intercon_rstn]
  connect_bd_net [get_bd_pins rst_156m25/peripheral_aresetn] [get_bd_pins sfp_port$label/periph_rstn]
  connect_bd_net [get_bd_pins gt_quad_base_0/gtpowergood] [get_bd_pins sfp_port$label/gtpowergood_in]
  #connect_bd_net [get_bd_pins sfp_port$label/gtwiz_rxcdrhold] [get_bd_pins gt_quad_base_0/ch${label}_rxcdrhold]
  connect_bd_net [get_bd_pins sfp_port$label/gtwiz_loopback] [get_bd_pins gt_quad_base_0/ch${label}_loopback]
  connect_bd_net [get_bd_pins sfp_port$label/gtwiz_txprecursor] [get_bd_pins gt_quad_base_0/ch${label}_txprecursor]
  connect_bd_net [get_bd_pins sfp_port$label/gtwiz_txpostcursor] [get_bd_pins gt_quad_base_0/ch${label}_txpostcursor]
  connect_bd_net [get_bd_pins sfp_port$label/gtwiz_txmaincursor] [get_bd_pins gt_quad_base_0/ch${label}_txmaincursor]

  # DMA MM interfaces to NOC
  set index_padded [format "%02d" $noc_port_index]
  connect_bd_intf_net [get_bd_intf_pins sfp_port$label/m_axi_sg] [get_bd_intf_pins axi_noc_0/S${index_padded}_AXI]
  set noc_port_index [expr {$noc_port_index + 1}]
  set index_padded [format "%02d" $noc_port_index]
  connect_bd_intf_net [get_bd_intf_pins sfp_port$label/m_axi_mm2s] [get_bd_intf_pins axi_noc_0/S${index_padded}_AXI]
  set noc_port_index [expr {$noc_port_index + 1}]
  set index_padded [format "%02d" $noc_port_index]
  connect_bd_intf_net [get_bd_intf_pins sfp_port$label/m_axi_s2mm] [get_bd_intf_pins axi_noc_0/S${index_padded}_AXI]
  set noc_port_index [expr {$noc_port_index + 1}]

  # Clocks for the NOC
  connect_bd_net [get_bd_pins sfp_port$label/txusrclk] [get_bd_pins axi_noc_0/aclk${noc_clk_index}]
  set noc_clk_index [expr {$noc_clk_index + 1}]
  connect_bd_net [get_bd_pins sfp_port$label/rxusrclk] [get_bd_pins axi_noc_0/aclk${noc_clk_index}]
  set noc_clk_index [expr {$noc_clk_index + 1}]

  # TX and RX outclks
  connect_bd_net [get_bd_pins gt_quad_base_0/ch${label}_txoutclk] [get_bd_pins sfp_port$label/txoutclk]
  connect_bd_net [get_bd_pins gt_quad_base_0/ch${label}_rxoutclk] [get_bd_pins sfp_port$label/rxoutclk]

  # TX and RX usrclks
  connect_bd_net [get_bd_pins sfp_port$label/txusrclk] [get_bd_pins gt_quad_base_0/ch${label}_txusrclk]
  connect_bd_net [get_bd_pins sfp_port$label/rxusrclk] [get_bd_pins gt_quad_base_0/ch${label}_rxusrclk]

  # GT SERDES interfaces
  connect_bd_intf_net [get_bd_intf_pins sfp_port$label/gt_tx_serdes_interface] [get_bd_intf_pins gt_quad_base_0/TX${label}_GT_IP_Interface]
  connect_bd_intf_net [get_bd_intf_pins sfp_port$label/gt_rx_serdes_interface] [get_bd_intf_pins gt_quad_base_0/RX${label}_GT_IP_Interface]

  # AXI LITE interface
  set index_padded [format "%02d" $label]
  connect_bd_intf_net [get_bd_intf_pins sfp_port$label/S_AXI_LITE] [get_bd_intf_pins axi_smc/M${index_padded}_AXI]

  # Interrupts
  lappend intr_list "sfp_port$label/dma_mm2s_introut"
  lappend intr_list "sfp_port$label/dma_s2mm_introut"
}

# This procedure creates a hierarchical block that contains
# the SFP I/Os for a single *unused* SFP slot. We use this to properly
# tie off the SFP I/Os that are not being used in the design.

proc create_unused_sfp_port {label} {

  # Create hierarchical block for the SFP port logic
  set hier_obj [create_bd_cell -type hier unused_sfp_port$label]
  current_bd_instance $hier_obj

  # Create pins for this block
  create_bd_pin -dir O tx_disable
  create_bd_pin -dir O rate_sel0
  create_bd_pin -dir O rate_sel1
  create_bd_pin -dir I mod_abs
  create_bd_pin -dir I rx_los
  create_bd_pin -dir I tx_fault
  create_bd_pin -dir O grn_led
  create_bd_pin -dir O red_led

  #########################################################
  # SFP I/O
  #########################################################

  # Create constant LOW for the SFP I/Os
  set const_low [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_low ]
  set_property -dict [list CONFIG.CONST_VAL {0}] $const_low

  # TX DISABLE - LOW
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins tx_disable]
  # RATE SEL 0 - LOW
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins rate_sel0]
  # RATE SEL 1 - LOW
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins rate_sel1]
  # Green LED - OFF
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins grn_led]
  # Red LED - OFF
  connect_bd_net [get_bd_pins const_low/dout] [get_bd_pins red_led]

  # Restore current instance
  current_bd_instance \
}

# Correctly tie off the unused ports
foreach label $unused_ports {
  create_unused_sfp_port $label

  # Create external ports
  create_bd_port -dir O tx_disable_sfp$label
  create_bd_port -dir O rate_sel0_sfp$label
  create_bd_port -dir O rate_sel1_sfp$label
  create_bd_port -dir I mod_abs_sfp$label
  create_bd_port -dir I rx_los_sfp$label
  create_bd_port -dir I tx_fault_sfp$label
  create_bd_port -dir O grn_led_sfp$label
  create_bd_port -dir O red_led_sfp$label

  # Connect external ports to the block pins
  connect_bd_net [get_bd_pins unused_sfp_port$label/tx_disable] [get_bd_ports tx_disable_sfp$label]
  connect_bd_net [get_bd_pins unused_sfp_port$label/rate_sel0] [get_bd_ports rate_sel0_sfp$label]
  connect_bd_net [get_bd_pins unused_sfp_port$label/rate_sel1] [get_bd_ports rate_sel1_sfp$label]
  connect_bd_net [get_bd_pins unused_sfp_port$label/mod_abs] [get_bd_ports mod_abs_sfp$label]
  connect_bd_net [get_bd_pins unused_sfp_port$label/rx_los] [get_bd_ports rx_los_sfp$label]
  connect_bd_net [get_bd_pins unused_sfp_port$label/tx_fault] [get_bd_ports tx_fault_sfp$label]
  connect_bd_net [get_bd_pins unused_sfp_port$label/grn_led] [get_bd_ports grn_led_sfp$label]
  connect_bd_net [get_bd_pins unused_sfp_port$label/red_led] [get_bd_ports red_led_sfp$label]
}

# Configure the GT quad protocols
set_property -dict [list \
  CONFIG.PROT1_ENABLE.VALUE_MODE MANUAL \
  CONFIG.PROT3_ENABLE.VALUE_MODE MANUAL \
  CONFIG.PROT2_ENABLE.VALUE_MODE MANUAL \
  CONFIG.PROT0_NO_OF_LANES.VALUE_MODE MANUAL \
  ] [get_bd_cells gt_quad_base_0]
set_property -dict [list \
  CONFIG.PROT0_NO_OF_LANES {1} \
  CONFIG.PROT1_ENABLE {true} \
  CONFIG.PROT2_ENABLE {true} \
  CONFIG.PROT3_ENABLE {true} \
] [get_bd_cells gt_quad_base_0]
connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins gt_quad_base_0/GT_REFCLK1]

# Connect the interrupts
set intr_index 0
foreach intr $intr_list {
  connect_bd_net [get_bd_pins $intr] [get_bd_pins versal_cips_0/pl_ps_irq$intr_index]
  set intr_index [expr {$intr_index+1}]
}

# Assign any addresses that haven't already been assigned
assign_bd_address

validate_bd_design
save_bd_design
