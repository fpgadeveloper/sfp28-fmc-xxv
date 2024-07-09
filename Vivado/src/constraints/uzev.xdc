#---------------------------------------------------------------------
# Constraints for Opsero Quad SFP28 FMC ref design for UZED-EV
#---------------------------------------------------------------------

# PL I2C signals
set_property PACKAGE_PIN AC16 [get_ports i2c_scl_io]; # LA11_P
set_property PACKAGE_PIN AD16 [get_ports i2c_sda_io]; # LA11_N
set_property IOSTANDARD LVCMOS18 [get_ports i2c_*]
set_property SLEW SLOW [get_ports i2c_*]
set_property DRIVE 4 [get_ports i2c_*]

# GT reference clock
set_property PACKAGE_PIN L8 [get_ports gt_ref_clk_clk_p]; # GBTCLK0_M2C_P

#############
# SFP SLOT 0
#############

# SFP slot 0: Gigabit transceivers
set_property PACKAGE_PIN N4 [get_ports {sfp_gt_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN N3 [get_ports {sfp_gt_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN P6 [get_ports {sfp_gt_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN P5 [get_ports {sfp_gt_grx_n[0]}]; # DP0_M2C_N

# SFP slot 0: SFP I/O and User LEDs
set_property PACKAGE_PIN AF18 [get_ports tx_fault_sfp0]; # LA03_N
set_property PACKAGE_PIN AE18 [get_ports {tx_disable_sfp0[0]}]; # LA03_P
set_property PACKAGE_PIN AJ17 [get_ports mod_abs_sfp0]; # LA04_N
set_property PACKAGE_PIN AH18 [get_ports {rate_sel0_sfp0[0]}]; # LA02_N
set_property PACKAGE_PIN AG18 [get_ports {rate_sel1_sfp0[0]}]; # LA02_P
set_property PACKAGE_PIN AH17 [get_ports rx_los_sfp0]; # LA04_P
set_property PACKAGE_PIN AD17 [get_ports {grn_led_sfp0[0]}]; # LA01_CC_P
set_property PACKAGE_PIN AE17 [get_ports {red_led_sfp0[0]}]; # LA01_CC_N

#############
# SFP SLOT 1
#############

# SFP slot 1: Gigabit transceivers
set_property PACKAGE_PIN M2 [get_ports {sfp_gt_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN M1 [get_ports {sfp_gt_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN M6 [get_ports {sfp_gt_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN M5 [get_ports {sfp_gt_grx_n[1]}]; # DP1_M2C_N

# SFP slot 1: SFP I/O and User LEDs
set_property PACKAGE_PIN AK14 [get_ports tx_fault_sfp1]; # LA12_N
set_property PACKAGE_PIN AJ14 [get_ports {tx_disable_sfp1[0]}]; # LA12_P
set_property PACKAGE_PIN AB16 [get_ports mod_abs_sfp1]; # LA07_N
set_property PACKAGE_PIN AK16 [get_ports {rate_sel0_sfp1[0]}]; # LA08_N
set_property PACKAGE_PIN AJ16 [get_ports {rate_sel1_sfp1[0]}]; # LA08_P
set_property PACKAGE_PIN AA16 [get_ports rx_los_sfp1]; # LA07_P
set_property PACKAGE_PIN AD19 [get_ports {grn_led_sfp1[0]}]; # LA05_P
set_property PACKAGE_PIN AE19 [get_ports {red_led_sfp1[0]}]; # LA05_N

#############
# SFP SLOT 2
#############

# SFP slot 2: Gigabit transceivers
set_property PACKAGE_PIN K2 [get_ports {sfp_gt_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN K1 [get_ports {sfp_gt_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN L4 [get_ports {sfp_gt_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN L3 [get_ports {sfp_gt_grx_n[2]}]; # DP2_M2C_N

# SFP slot 2: SFP I/O and User LEDs
set_property PACKAGE_PIN AK13 [get_ports tx_fault_sfp2]; # LA15_P
set_property PACKAGE_PIN AK12 [get_ports {tx_disable_sfp2[0]}]; # LA15_N
set_property PACKAGE_PIN AK18 [get_ports mod_abs_sfp2]; # LA09_N
set_property PACKAGE_PIN AH16 [get_ports {rate_sel0_sfp2[0]}]; # LA10_N
set_property PACKAGE_PIN AG16 [get_ports {rate_sel1_sfp2[0]}]; # LA10_P
set_property PACKAGE_PIN AK17 [get_ports rx_los_sfp2]; # LA09_P
set_property PACKAGE_PIN AG13 [get_ports {grn_led_sfp2[0]}]; # LA16_P
set_property PACKAGE_PIN AH13 [get_ports {red_led_sfp2[0]}]; # LA16_N

#############
# SFP SLOT 3
#############

# SFP slot 3: Gigabit transceivers
set_property PACKAGE_PIN J4 [get_ports {sfp_gt_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN J3 [get_ports {sfp_gt_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN K6 [get_ports {sfp_gt_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN K5 [get_ports {sfp_gt_grx_n[3]}]; # DP3_M2C_N

# SFP slot 3: SFP I/O and User LEDs
set_property PACKAGE_PIN AG6 [get_ports tx_fault_sfp3]; # LA17_CC_P
set_property PACKAGE_PIN AG5 [get_ports {tx_disable_sfp3[0]}]; # LA17_CC_N
set_property PACKAGE_PIN AJ6 [get_ports mod_abs_sfp3]; # LA18_CC_N
set_property PACKAGE_PIN AG15 [get_ports {rate_sel0_sfp3[0]}]; # LA14_N
set_property PACKAGE_PIN AF15 [get_ports {rate_sel1_sfp3[0]}]; # LA14_P
set_property PACKAGE_PIN AH6 [get_ports rx_los_sfp3]; # LA18_CC_P
set_property PACKAGE_PIN AJ15 [get_ports {grn_led_sfp3[0]}]; # LA13_P
set_property PACKAGE_PIN AK15 [get_ports {red_led_sfp3[0]}]; # LA13_N

# SFP I/O IOSTANDARDs
set_property IOSTANDARD LVCMOS18 [get_ports tx_fault_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports tx_disable_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports mod_abs_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rate_sel0_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rate_sel1_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rx_los_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports grn_led_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports red_led_sfp*]

