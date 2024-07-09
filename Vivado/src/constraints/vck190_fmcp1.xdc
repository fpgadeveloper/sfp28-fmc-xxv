#---------------------------------------------------------------------
# Constraints for Opsero Quad SFP28 FMC ref design for VCK190-FMCP1
#---------------------------------------------------------------------

# PL I2C signals
set_property PACKAGE_PIN BF23 [get_ports i2c_scl_io]; # LA11_P
set_property PACKAGE_PIN BE22 [get_ports i2c_sda_io]; # LA11_N
set_property IOSTANDARD LVCMOS15 [get_ports i2c_*]
set_property SLEW SLOW [get_ports i2c_*]
set_property DRIVE 4 [get_ports i2c_*]

#####################
# GT reference clock
#####################

# Using VCK190 Si570 (U192) clock oscillator for GT ref clock
# The device defaults to an output of 156.25MHz, the same frequency required by the ref design
set_property PACKAGE_PIN L39 [get_ports gt_ref_clk_clk_p]; # zSFP_SI570_CLK_C_P

# GT ref clock from the Quad FMC28 FMC Si5328 (uncomment to use it instead of the above)
# set_property PACKAGE_PIN M15 [get_ports gt_ref_clk_clk_p]; # GBTCLK0_M2C_P

#############
# SFP SLOT 0
#############

# SFP slot 0: Gigabit transceivers
set_property PACKAGE_PIN AB7 [get_ports {sfp_gt_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN AB6 [get_ports {sfp_gt_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN AB2 [get_ports {sfp_gt_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN AB1 [get_ports {sfp_gt_grx_n[0]}]; # DP0_M2C_N

# SFP slot 0: SFP I/O and User LEDs
set_property PACKAGE_PIN AW21 [get_ports tx_fault_sfp0]; # LA03_N
set_property PACKAGE_PIN AV22 [get_ports {tx_disable_sfp0[0]}]; # LA03_P
set_property PACKAGE_PIN AV21 [get_ports mod_abs_sfp0]; # LA04_N
set_property PACKAGE_PIN AY25 [get_ports {rate_sel0_sfp0[0]}]; # LA02_N
set_property PACKAGE_PIN AW24 [get_ports {rate_sel1_sfp0[0]}]; # LA02_P
set_property PACKAGE_PIN AU21 [get_ports rx_los_sfp0]; # LA04_P
set_property PACKAGE_PIN BC23 [get_ports {grn_led_sfp0[0]}]; # LA01_CC_P
set_property PACKAGE_PIN BD22 [get_ports {red_led_sfp0[0]}]; # LA01_CC_N

#############
# SFP SLOT 1
#############

# SFP slot 1: Gigabit transceivers
set_property PACKAGE_PIN AA9 [get_ports {sfp_gt_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN AA8 [get_ports {sfp_gt_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN AA4 [get_ports {sfp_gt_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN AA3 [get_ports {sfp_gt_grx_n[1]}]; # DP1_M2C_N

# SFP slot 1: SFP I/O and User LEDs
set_property PACKAGE_PIN BF22 [get_ports tx_fault_sfp1]; # LA12_N
set_property PACKAGE_PIN BG21 [get_ports {tx_disable_sfp1[0]}]; # LA12_P
set_property PACKAGE_PIN BD25 [get_ports mod_abs_sfp1]; # LA07_N
set_property PACKAGE_PIN BC21 [get_ports {rate_sel0_sfp1[0]}]; # LA08_N
set_property PACKAGE_PIN BC22 [get_ports {rate_sel1_sfp1[0]}]; # LA08_P
set_property PACKAGE_PIN BC25 [get_ports rx_los_sfp1]; # LA07_P
set_property PACKAGE_PIN BF24 [get_ports {grn_led_sfp1[0]}]; # LA05_P
set_property PACKAGE_PIN BG23 [get_ports {red_led_sfp1[0]}]; # LA05_N

#############
# SFP SLOT 2
#############

# SFP slot 2: Gigabit transceivers
set_property PACKAGE_PIN Y7 [get_ports {sfp_gt_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN Y6 [get_ports {sfp_gt_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN Y2 [get_ports {sfp_gt_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN Y1 [get_ports {sfp_gt_grx_n[2]}]; # DP2_M2C_N

# SFP slot 2: SFP I/O and User LEDs
set_property PACKAGE_PIN AY22 [get_ports tx_fault_sfp2]; # LA15_P
set_property PACKAGE_PIN AY23 [get_ports {tx_disable_sfp2[0]}]; # LA15_N
set_property PACKAGE_PIN BE24 [get_ports mod_abs_sfp2]; # LA09_N
set_property PACKAGE_PIN BG24 [get_ports {rate_sel0_sfp2[0]}]; # LA10_N
set_property PACKAGE_PIN BG25 [get_ports {rate_sel1_sfp2[0]}]; # LA10_P
set_property PACKAGE_PIN BE25 [get_ports rx_los_sfp2]; # LA09_P
set_property PACKAGE_PIN BF21 [get_ports {grn_led_sfp2[0]}]; # LA16_P
set_property PACKAGE_PIN BG20 [get_ports {red_led_sfp2[0]}]; # LA16_N

#############
# SFP SLOT 3
#############

# SFP slot 3: Gigabit transceivers
set_property PACKAGE_PIN W9 [get_ports {sfp_gt_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN W8 [get_ports {sfp_gt_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN W4 [get_ports {sfp_gt_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN W3 [get_ports {sfp_gt_grx_n[3]}]; # DP3_M2C_N

# SFP slot 3: SFP I/O and User LEDs
set_property PACKAGE_PIN BB16 [get_ports tx_fault_sfp3]; # LA17_CC_P
set_property PACKAGE_PIN BC16 [get_ports {tx_disable_sfp3[0]}]; # LA17_CC_N
set_property PACKAGE_PIN BD17 [get_ports mod_abs_sfp3]; # LA18_CC_N
set_property PACKAGE_PIN AU23 [get_ports {rate_sel0_sfp3[0]}]; # LA14_N
set_property PACKAGE_PIN AU24 [get_ports {rate_sel1_sfp3[0]}]; # LA14_P
set_property PACKAGE_PIN BE17 [get_ports rx_los_sfp3]; # LA18_CC_P
set_property PACKAGE_PIN BE21 [get_ports {grn_led_sfp3[0]}]; # LA13_P
set_property PACKAGE_PIN BE20 [get_ports {red_led_sfp3[0]}]; # LA13_N

# SFP I/O IOSTANDARDs
set_property IOSTANDARD LVCMOS15 [get_ports tx_fault_sfp*]
set_property IOSTANDARD LVCMOS15 [get_ports tx_disable_sfp*]
set_property IOSTANDARD LVCMOS15 [get_ports mod_abs_sfp*]
set_property IOSTANDARD LVCMOS15 [get_ports rate_sel0_sfp*]
set_property IOSTANDARD LVCMOS15 [get_ports rate_sel1_sfp*]
set_property IOSTANDARD LVCMOS15 [get_ports rx_los_sfp*]
set_property IOSTANDARD LVCMOS15 [get_ports grn_led_sfp*]
set_property IOSTANDARD LVCMOS15 [get_ports red_led_sfp*]

