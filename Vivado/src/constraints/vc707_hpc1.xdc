#---------------------------------------------------------------------
# Constraints for Opsero Quad SFP28 FMC ref design for VC707-HPC1
#---------------------------------------------------------------------

# PL I2C signals
set_property PACKAGE_PIN F40 [get_ports i2c_scl_io]; # LA11_P
set_property PACKAGE_PIN F41 [get_ports i2c_sda_io]; # LA11_N
set_property IOSTANDARD LVCMOS18 [get_ports i2c_*]
set_property SLEW SLOW [get_ports i2c_*]
set_property DRIVE 4 [get_ports i2c_*]

# GT reference clock
set_property PACKAGE_PIN A10 [get_ports gt_ref_clk_clk_p]; # GBTCLK0_M2C_P

#############
# SFP SLOT 0
#############

# SFP slot 0: Gigabit transceivers
set_property PACKAGE_PIN E2 [get_ports {sfp_gt_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN E1 [get_ports {sfp_gt_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN D8 [get_ports {sfp_gt_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN D7 [get_ports {sfp_gt_grx_n[0]}]; # DP0_M2C_N

# SFP slot 0: SFP I/O and User LEDs
set_property PACKAGE_PIN L42 [get_ports tx_fault_sfp0]; # LA03_N
set_property PACKAGE_PIN M42 [get_ports {tx_disable_sfp0[0]}]; # LA03_P
set_property PACKAGE_PIN H41 [get_ports mod_abs_sfp0]; # LA04_N
set_property PACKAGE_PIN N41 [get_ports {rate_sel0_sfp0[0]}]; # LA02_N
set_property PACKAGE_PIN P41 [get_ports {rate_sel1_sfp0[0]}]; # LA02_P
set_property PACKAGE_PIN H40 [get_ports rx_los_sfp0]; # LA04_P
set_property PACKAGE_PIN J40 [get_ports {grn_led_sfp0[0]}]; # LA01_CC_P
set_property PACKAGE_PIN J41 [get_ports {red_led_sfp0[0]}]; # LA01_CC_N

#############
# SFP SLOT 1
#############

# SFP slot 1: Gigabit transceivers
set_property PACKAGE_PIN D4 [get_ports {sfp_gt_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN D3 [get_ports {sfp_gt_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN C6 [get_ports {sfp_gt_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN C5 [get_ports {sfp_gt_grx_n[1]}]; # DP1_M2C_N

# SFP slot 1: SFP I/O and User LEDs
set_property PACKAGE_PIN P40 [get_ports tx_fault_sfp1]; # LA12_N
set_property PACKAGE_PIN R40 [get_ports {tx_disable_sfp1[0]}]; # LA12_P
set_property PACKAGE_PIN G42 [get_ports mod_abs_sfp1]; # LA07_N
set_property PACKAGE_PIN M38 [get_ports {rate_sel0_sfp1[0]}]; # LA08_N
set_property PACKAGE_PIN M37 [get_ports {rate_sel1_sfp1[0]}]; # LA08_P
set_property PACKAGE_PIN G41 [get_ports rx_los_sfp1]; # LA07_P
set_property PACKAGE_PIN M41 [get_ports {grn_led_sfp1[0]}]; # LA05_P
set_property PACKAGE_PIN L41 [get_ports {red_led_sfp1[0]}]; # LA05_N

#############
# SFP SLOT 2
#############

# SFP slot 2: Gigabit transceivers
set_property PACKAGE_PIN C2 [get_ports {sfp_gt_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN C1 [get_ports {sfp_gt_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN B8 [get_ports {sfp_gt_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN B7 [get_ports {sfp_gt_grx_n[2]}]; # DP2_M2C_N

# SFP slot 2: SFP I/O and User LEDs
set_property PACKAGE_PIN M36 [get_ports tx_fault_sfp2]; # LA15_P
set_property PACKAGE_PIN L37 [get_ports {tx_disable_sfp2[0]}]; # LA15_N
set_property PACKAGE_PIN P42 [get_ports mod_abs_sfp2]; # LA09_N
set_property PACKAGE_PIN M39 [get_ports {rate_sel0_sfp2[0]}]; # LA10_N
set_property PACKAGE_PIN N38 [get_ports {rate_sel1_sfp2[0]}]; # LA10_P
set_property PACKAGE_PIN R42 [get_ports rx_los_sfp2]; # LA09_P
set_property PACKAGE_PIN K37 [get_ports {grn_led_sfp2[0]}]; # LA16_P
set_property PACKAGE_PIN K38 [get_ports {red_led_sfp2[0]}]; # LA16_N

#############
# SFP SLOT 3
#############

# SFP slot 3: Gigabit transceivers
set_property PACKAGE_PIN B4 [get_ports {sfp_gt_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN B3 [get_ports {sfp_gt_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN A6 [get_ports {sfp_gt_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN A5 [get_ports {sfp_gt_grx_n[3]}]; # DP3_M2C_N

# SFP slot 3: SFP I/O and User LEDs
set_property PACKAGE_PIN L31 [get_ports tx_fault_sfp3]; # LA17_CC_P
set_property PACKAGE_PIN K32 [get_ports {tx_disable_sfp3[0]}]; # LA17_CC_N
set_property PACKAGE_PIN L32 [get_ports mod_abs_sfp3]; # LA18_CC_N
set_property PACKAGE_PIN N40 [get_ports {rate_sel0_sfp3[0]}]; # LA14_N
set_property PACKAGE_PIN N39 [get_ports {rate_sel1_sfp3[0]}]; # LA14_P
set_property PACKAGE_PIN M32 [get_ports rx_los_sfp3]; # LA18_CC_P
set_property PACKAGE_PIN H39 [get_ports {grn_led_sfp3[0]}]; # LA13_P
set_property PACKAGE_PIN G39 [get_ports {red_led_sfp3[0]}]; # LA13_N

# SFP I/O IOSTANDARDs
set_property IOSTANDARD LVCMOS18 [get_ports tx_fault_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports tx_disable_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports mod_abs_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rate_sel0_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rate_sel1_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rx_los_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports grn_led_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports red_led_sfp*]

# Configuration via BPI flash for VC707
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE DISABLE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

