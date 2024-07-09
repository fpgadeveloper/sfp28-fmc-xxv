#---------------------------------------------------------------------
# Constraints for Opsero Quad SFP28 FMC ref design for VCU118-FMCP
#---------------------------------------------------------------------

# PL I2C signals
set_property PACKAGE_PIN AJ30 [get_ports i2c_scl_io]; # LA11_P
set_property PACKAGE_PIN AJ31 [get_ports i2c_sda_io]; # LA11_N
set_property IOSTANDARD LVCMOS18 [get_ports i2c_*]
set_property SLEW SLOW [get_ports i2c_*]
set_property DRIVE 4 [get_ports i2c_*]

# GT reference clock
set_property PACKAGE_PIN AK38 [get_ports gt_ref_clk_clk_p]; # GBTCLK0_M2C_P

#############
# SFP SLOT 0
#############

# SFP slot 0: Gigabit transceivers
set_property PACKAGE_PIN AT42 [get_ports {sfp_gt_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN AT43 [get_ports {sfp_gt_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN AR45 [get_ports {sfp_gt_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN AR46 [get_ports {sfp_gt_grx_n[0]}]; # DP0_M2C_N

# SFP slot 0: SFP I/O and User LEDs
set_property PACKAGE_PIN AT40 [get_ports tx_fault_sfp0]; # LA03_N
set_property PACKAGE_PIN AT39 [get_ports {tx_disable_sfp0[0]}]; # LA03_P
set_property PACKAGE_PIN AT37 [get_ports mod_abs_sfp0]; # LA04_N
set_property PACKAGE_PIN AK32 [get_ports {rate_sel0_sfp0[0]}]; # LA02_N
set_property PACKAGE_PIN AJ32 [get_ports {rate_sel1_sfp0[0]}]; # LA02_P
set_property PACKAGE_PIN AR37 [get_ports rx_los_sfp0]; # LA04_P
set_property PACKAGE_PIN AL30 [get_ports {grn_led_sfp0[0]}]; # LA01_CC_P
set_property PACKAGE_PIN AL31 [get_ports {red_led_sfp0[0]}]; # LA01_CC_N

#############
# SFP SLOT 1
#############

# SFP slot 1: Gigabit transceivers
set_property PACKAGE_PIN AP42 [get_ports {sfp_gt_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN AP43 [get_ports {sfp_gt_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN AN45 [get_ports {sfp_gt_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN AN46 [get_ports {sfp_gt_grx_n[1]}]; # DP1_M2C_N

# SFP slot 1: SFP I/O and User LEDs
set_property PACKAGE_PIN AH34 [get_ports tx_fault_sfp1]; # LA12_N
set_property PACKAGE_PIN AH33 [get_ports {tx_disable_sfp1[0]}]; # LA12_P
set_property PACKAGE_PIN AP37 [get_ports mod_abs_sfp1]; # LA07_N
set_property PACKAGE_PIN AK30 [get_ports {rate_sel0_sfp1[0]}]; # LA08_N
set_property PACKAGE_PIN AK29 [get_ports {rate_sel1_sfp1[0]}]; # LA08_P
set_property PACKAGE_PIN AP36 [get_ports rx_los_sfp1]; # LA07_P
set_property PACKAGE_PIN AP38 [get_ports {grn_led_sfp1[0]}]; # LA05_P
set_property PACKAGE_PIN AR38 [get_ports {red_led_sfp1[0]}]; # LA05_N

#############
# SFP SLOT 2
#############

# SFP slot 2: Gigabit transceivers
set_property PACKAGE_PIN AM42 [get_ports {sfp_gt_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN AM43 [get_ports {sfp_gt_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN AL45 [get_ports {sfp_gt_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN AL46 [get_ports {sfp_gt_grx_n[2]}]; # DP2_M2C_N

# SFP slot 2: SFP I/O and User LEDs
set_property PACKAGE_PIN AG32 [get_ports tx_fault_sfp2]; # LA15_P
set_property PACKAGE_PIN AG33 [get_ports {tx_disable_sfp2[0]}]; # LA15_N
set_property PACKAGE_PIN AK33 [get_ports mod_abs_sfp2]; # LA09_N
set_property PACKAGE_PIN AR35 [get_ports {rate_sel0_sfp2[0]}]; # LA10_N
set_property PACKAGE_PIN AP35 [get_ports {rate_sel1_sfp2[0]}]; # LA10_P
set_property PACKAGE_PIN AJ33 [get_ports rx_los_sfp2]; # LA09_P
set_property PACKAGE_PIN AG34 [get_ports {grn_led_sfp2[0]}]; # LA16_P
set_property PACKAGE_PIN AH35 [get_ports {red_led_sfp2[0]}]; # LA16_N

#############
# SFP SLOT 3
#############

# SFP slot 3: Gigabit transceivers
set_property PACKAGE_PIN AL40 [get_ports {sfp_gt_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN AL41 [get_ports {sfp_gt_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN AJ45 [get_ports {sfp_gt_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN AJ46 [get_ports {sfp_gt_grx_n[3]}]; # DP3_M2C_N

# SFP slot 3: SFP I/O and User LEDs
set_property PACKAGE_PIN R34 [get_ports tx_fault_sfp3]; # LA17_CC_P
set_property PACKAGE_PIN P34 [get_ports {tx_disable_sfp3[0]}]; # LA17_CC_N
set_property PACKAGE_PIN P31 [get_ports mod_abs_sfp3]; # LA18_CC_N
set_property PACKAGE_PIN AH31 [get_ports {rate_sel0_sfp3[0]}]; # LA14_N
set_property PACKAGE_PIN AG31 [get_ports {rate_sel1_sfp3[0]}]; # LA14_P
set_property PACKAGE_PIN R31 [get_ports rx_los_sfp3]; # LA18_CC_P
set_property PACKAGE_PIN AJ35 [get_ports {grn_led_sfp3[0]}]; # LA13_P
set_property PACKAGE_PIN AJ36 [get_ports {red_led_sfp3[0]}]; # LA13_N

# SFP I/O IOSTANDARDs
set_property IOSTANDARD LVCMOS18 [get_ports tx_fault_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports tx_disable_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports mod_abs_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rate_sel0_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rate_sel1_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rx_los_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports grn_led_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports red_led_sfp*]

# Configuration via Quad SPI flash for VCU118
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Timing constraints taken from the BSP
set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */addn_ui_clkout1}]
set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}]

