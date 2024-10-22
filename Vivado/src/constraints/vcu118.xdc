#---------------------------------------------------------------------
# Constraints for Opsero Quad SFP28 FMC ref design for VCU118
#---------------------------------------------------------------------

# PL I2C signals
set_property PACKAGE_PIN BA16 [get_ports i2c_scl_io]; # LA11_P
set_property PACKAGE_PIN BA15 [get_ports i2c_sda_io]; # LA11_N
set_property IOSTANDARD LVCMOS18 [get_ports i2c_*]
set_property SLEW SLOW [get_ports i2c_*]
set_property DRIVE 4 [get_ports i2c_*]

#####################
# GT reference clock
#####################

# Using VCU118 Si570 (U32) clock oscillator for GT ref clock
# The device defaults to an output of 156.25MHz, the same frequency required by the ref design
set_property PACKAGE_PIN AJ9 [get_ports gt_ref_clk_clk_p]; # MGT_SI570_CLOCK1_C_P


#############
# SFP SLOT 0
#############

# SFP slot 0: Gigabit transceivers

# SFP slot 0: SFP I/O and User LEDs
set_property PACKAGE_PIN BE12 [get_ports tx_fault_sfp0]; # LA03_N
set_property PACKAGE_PIN BD12 [get_ports {tx_disable_sfp0[0]}]; # LA03_P
set_property PACKAGE_PIN BF11 [get_ports mod_abs_sfp0]; # LA04_N
set_property PACKAGE_PIN BD11 [get_ports {rate_sel0_sfp0[0]}]; # LA02_N
set_property PACKAGE_PIN BC11 [get_ports {rate_sel1_sfp0[0]}]; # LA02_P
set_property PACKAGE_PIN BF12 [get_ports rx_los_sfp0]; # LA04_P
set_property PACKAGE_PIN BF10 [get_ports {grn_led_sfp0[0]}]; # LA01_CC_P
set_property PACKAGE_PIN BF9 [get_ports {red_led_sfp0[0]}]; # LA01_CC_N

#############
# SFP SLOT 1
#############

# SFP slot 1: Gigabit transceivers

# SFP slot 1: SFP I/O and User LEDs
set_property PACKAGE_PIN BC13 [get_ports tx_fault_sfp1]; # LA12_N
set_property PACKAGE_PIN BC14 [get_ports {tx_disable_sfp1[0]}]; # LA12_P
set_property PACKAGE_PIN BD15 [get_ports mod_abs_sfp1]; # LA07_N
set_property PACKAGE_PIN BF15 [get_ports {rate_sel0_sfp1[0]}]; # LA08_N
set_property PACKAGE_PIN BE15 [get_ports {rate_sel1_sfp1[0]}]; # LA08_P
set_property PACKAGE_PIN BC15 [get_ports rx_los_sfp1]; # LA07_P
set_property PACKAGE_PIN BE14 [get_ports {grn_led_sfp1[0]}]; # LA05_P
set_property PACKAGE_PIN BF14 [get_ports {red_led_sfp1[0]}]; # LA05_N

#############
# SFP SLOT 2
#############

# SFP slot 2: Gigabit transceivers

# SFP slot 2: SFP I/O and User LEDs
set_property PACKAGE_PIN BB16 [get_ports tx_fault_sfp2]; # LA15_P
set_property PACKAGE_PIN BC16 [get_ports {tx_disable_sfp2[0]}]; # LA15_N
set_property PACKAGE_PIN BB14 [get_ports mod_abs_sfp2]; # LA09_N
set_property PACKAGE_PIN BB12 [get_ports {rate_sel0_sfp2[0]}]; # LA10_N
set_property PACKAGE_PIN BB13 [get_ports {rate_sel1_sfp2[0]}]; # LA10_P
set_property PACKAGE_PIN BA14 [get_ports rx_los_sfp2]; # LA09_P
set_property PACKAGE_PIN AV9 [get_ports {grn_led_sfp2[0]}]; # LA16_P
set_property PACKAGE_PIN AV8 [get_ports {red_led_sfp2[0]}]; # LA16_N

#############
# SFP SLOT 3
#############

# SFP slot 3: Gigabit transceivers

# SFP slot 3: SFP I/O and User LEDs
set_property PACKAGE_PIN AR14 [get_ports tx_fault_sfp3]; # LA17_CC_P
set_property PACKAGE_PIN AT14 [get_ports {tx_disable_sfp3[0]}]; # LA17_CC_N
set_property PACKAGE_PIN AR12 [get_ports mod_abs_sfp3]; # LA18_CC_N
set_property PACKAGE_PIN AW7 [get_ports {rate_sel0_sfp3[0]}]; # LA14_N
set_property PACKAGE_PIN AW8 [get_ports {rate_sel1_sfp3[0]}]; # LA14_P
set_property PACKAGE_PIN AP12 [get_ports rx_los_sfp3]; # LA18_CC_P
set_property PACKAGE_PIN AY8 [get_ports {grn_led_sfp3[0]}]; # LA13_P
set_property PACKAGE_PIN AY7 [get_ports {red_led_sfp3[0]}]; # LA13_N

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

