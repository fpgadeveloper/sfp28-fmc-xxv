#---------------------------------------------------------------------
# Constraints for Opsero Quad SFP28 FMC ref design for ZCU106-HPC1
#---------------------------------------------------------------------

# PL I2C signals
set_property PACKAGE_PIN A20 [get_ports i2c_scl_io]; # LA11_P
set_property PACKAGE_PIN A21 [get_ports i2c_sda_io]; # LA11_N
set_property IOSTANDARD LVCMOS18 [get_ports i2c_*]
set_property SLEW SLOW [get_ports i2c_*]
set_property DRIVE 4 [get_ports i2c_*]

#####################
# GT reference clock
#####################

# GT ref clock from the Quad FMC28 FMC Si5328
set_property PACKAGE_PIN Y8 [get_ports gt_ref_clk_clk_p]; # GBTCLK0_M2C_P

#############
# SFP SLOT 0
#############

# SFP slot 0: Gigabit transceivers
set_property PACKAGE_PIN AJ6 [get_ports {sfp_gt_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN AJ5 [get_ports {sfp_gt_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN AK4 [get_ports {sfp_gt_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN AK3 [get_ports {sfp_gt_grx_n[0]}]; # DP0_M2C_N

# SFP slot 0: SFP I/O and User LEDs
set_property PACKAGE_PIN J22 [get_ports tx_fault_sfp0]; # LA03_N
set_property PACKAGE_PIN J21 [get_ports {tx_disable_sfp0[0]}]; # LA03_P
set_property PACKAGE_PIN H24 [get_ports mod_abs_sfp0]; # LA04_N
set_property PACKAGE_PIN K23 [get_ports {rate_sel0_sfp0[0]}]; # LA02_N
set_property PACKAGE_PIN K22 [get_ports {rate_sel1_sfp0[0]}]; # LA02_P
set_property PACKAGE_PIN J24 [get_ports rx_los_sfp0]; # LA04_P
set_property PACKAGE_PIN E24 [get_ports {grn_led_sfp0[0]}]; # LA01_CC_P
set_property PACKAGE_PIN D24 [get_ports {red_led_sfp0[0]}]; # LA01_CC_N

#############
# SFP SLOT 1
#############

# SFP slot 1: Gigabit transceivers

# SFP slot 1: SFP I/O and User LEDs
set_property PACKAGE_PIN D19 [get_ports tx_fault_sfp1]; # LA12_N
set_property PACKAGE_PIN E19 [get_ports {tx_disable_sfp1[0]}]; # LA12_P
set_property PACKAGE_PIN C23 [get_ports mod_abs_sfp1]; # LA07_N
set_property PACKAGE_PIN H26 [get_ports {rate_sel0_sfp1[0]}]; # LA08_N
set_property PACKAGE_PIN J25 [get_ports {rate_sel1_sfp1[0]}]; # LA08_P
set_property PACKAGE_PIN D22 [get_ports rx_los_sfp1]; # LA07_P
set_property PACKAGE_PIN G25 [get_ports {grn_led_sfp1[0]}]; # LA05_P
set_property PACKAGE_PIN G26 [get_ports {red_led_sfp1[0]}]; # LA05_N

#############
# SFP SLOT 2
#############

# SFP slot 2: Gigabit transceivers

# SFP slot 2: SFP I/O and User LEDs
set_property PACKAGE_PIN A18 [get_ports tx_fault_sfp2]; # LA15_P
set_property PACKAGE_PIN A19 [get_ports {tx_disable_sfp2[0]}]; # LA15_N
set_property PACKAGE_PIN F20 [get_ports mod_abs_sfp2]; # LA09_N
set_property PACKAGE_PIN E22 [get_ports {rate_sel0_sfp2[0]}]; # LA10_N
set_property PACKAGE_PIN F22 [get_ports {rate_sel1_sfp2[0]}]; # LA10_P
set_property PACKAGE_PIN G20 [get_ports rx_los_sfp2]; # LA09_P
set_property PACKAGE_PIN C18 [get_ports {grn_led_sfp2[0]}]; # LA16_P
set_property PACKAGE_PIN C19 [get_ports {red_led_sfp2[0]}]; # LA16_N

#############
# SFP SLOT 3
#############

# SFP slot 3: Gigabit transceivers

# SFP slot 3: SFP I/O and User LEDs
# set_property PACKAGE_PIN NC [get_ports tx_fault_sfp3]; # LA17_CC_P
# set_property PACKAGE_PIN NC [get_ports {tx_disable_sfp3[0]}]; # LA17_CC_N
# set_property PACKAGE_PIN NC [get_ports mod_abs_sfp3]; # LA18_CC_N
set_property PACKAGE_PIN D21 [get_ports {rate_sel0_sfp3[0]}]; # LA14_N
set_property PACKAGE_PIN D20 [get_ports {rate_sel1_sfp3[0]}]; # LA14_P
# set_property PACKAGE_PIN NC [get_ports rx_los_sfp3]; # LA18_CC_P
set_property PACKAGE_PIN C21 [get_ports {grn_led_sfp3[0]}]; # LA13_P
set_property PACKAGE_PIN C22 [get_ports {red_led_sfp3[0]}]; # LA13_N

# SFP I/O IOSTANDARDs
set_property IOSTANDARD LVCMOS18 [get_ports tx_fault_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports tx_disable_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports mod_abs_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rate_sel0_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rate_sel1_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports rx_los_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports grn_led_sfp*]
set_property IOSTANDARD LVCMOS18 [get_ports red_led_sfp*]

