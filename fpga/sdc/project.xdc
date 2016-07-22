#
# @brief DF4IAH project FPGA location constraints for the RedPitaya hardware V1.1
# SoC/FPGA device: XILINX 'xc7z010clg400-1'
# See package file of this device:  http://www.xilinx.com/support/packagefiles/z7packages/xc7z010clg400pkg.txt
#
# @Author Ulrich Habel, DF4IAH
#


############################################################################
# IO constraints                                                           #
############################################################################

### ADC

# ADC A data
set_property IOSTANDARD LVCMOS18       [get_ports {adc_dat_a_i[*]}]
#set_property IOB TRUE                  [get_ports {adc_dat_a_i[*]}]
#set_property PACKAGE_PIN V17           [get_ports {adc_dat_a_i[0]}]
#set_property PACKAGE_PIN U17           [get_ports {adc_dat_a_i[1]}]
set_property PACKAGE_PIN Y17           [get_ports {adc_dat_a_i[2]}]
set_property PACKAGE_PIN W16           [get_ports {adc_dat_a_i[3]}]
set_property PACKAGE_PIN Y16           [get_ports {adc_dat_a_i[4]}]
set_property PACKAGE_PIN W15           [get_ports {adc_dat_a_i[5]}]
set_property PACKAGE_PIN W14           [get_ports {adc_dat_a_i[6]}]
set_property PACKAGE_PIN Y14           [get_ports {adc_dat_a_i[7]}]
set_property PACKAGE_PIN W13           [get_ports {adc_dat_a_i[8]}]
set_property PACKAGE_PIN V12           [get_ports {adc_dat_a_i[9]}]
set_property PACKAGE_PIN V13           [get_ports {adc_dat_a_i[10]}]
set_property PACKAGE_PIN T14           [get_ports {adc_dat_a_i[11]}]
set_property PACKAGE_PIN T15           [get_ports {adc_dat_a_i[12]}]
set_property PACKAGE_PIN V15           [get_ports {adc_dat_a_i[13]}]
set_property PACKAGE_PIN T16           [get_ports {adc_dat_a_i[14]}]
set_property PACKAGE_PIN V16           [get_ports {adc_dat_a_i[15]}]

#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[0]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[1]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[2]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[3]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[4]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[5]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[6]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[7]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[8]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[9]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[10]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[11]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[12]}]
#set_property IOB TRUE                  [get_cells {adc_dat_a_reg[13]}]

# ADC B data
set_property IOSTANDARD LVCMOS18       [get_ports {adc_dat_b_i[*]}]
#set_property IOB TRUE                  [get_ports {adc_dat_b_i[*]}]
#set_property PACKAGE_PIN T17           [get_ports {adc_dat_b_i[0]}]
#set_property PACKAGE_PIN R16           [get_ports {adc_dat_b_i[1]}]
set_property PACKAGE_PIN R18           [get_ports {adc_dat_b_i[2]}]
set_property PACKAGE_PIN P16           [get_ports {adc_dat_b_i[3]}]
set_property PACKAGE_PIN P18           [get_ports {adc_dat_b_i[4]}]
set_property PACKAGE_PIN N17           [get_ports {adc_dat_b_i[5]}]
set_property PACKAGE_PIN R19           [get_ports {adc_dat_b_i[6]}]
set_property PACKAGE_PIN T20           [get_ports {adc_dat_b_i[7]}]
set_property PACKAGE_PIN T19           [get_ports {adc_dat_b_i[8]}]
set_property PACKAGE_PIN U20           [get_ports {adc_dat_b_i[9]}]
set_property PACKAGE_PIN V20           [get_ports {adc_dat_b_i[10]}]
set_property PACKAGE_PIN W20           [get_ports {adc_dat_b_i[11]}]
set_property PACKAGE_PIN W19           [get_ports {adc_dat_b_i[12]}]
set_property PACKAGE_PIN Y19           [get_ports {adc_dat_b_i[13]}]
set_property PACKAGE_PIN W18           [get_ports {adc_dat_b_i[14]}]
set_property PACKAGE_PIN Y18           [get_ports {adc_dat_b_i[15]}]

#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[0]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[1]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[2]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[3]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[4]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[5]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[6]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[7]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[8]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[9]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[10]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[11]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[12]}]
#set_property IOB TRUE                  [get_cells {adc_dat_b_reg[13]}]

set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports adc_clk_p_i]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports adc_clk_n_i]
set_property PACKAGE_PIN U18           [get_ports adc_clk_p_i]
set_property PACKAGE_PIN U19           [get_ports adc_clk_n_i]

# Output ADC clock
set_property IOSTANDARD LVCMOS18       [get_ports {adc_clk_o[*]}]
set_property SLEW SLOW                 [get_ports {adc_clk_o[*]}]
set_property DRIVE 4                   [get_ports {adc_clk_o[*]}]

set_property PACKAGE_PIN N20           [get_ports {adc_clk_o[0]}]
set_property PACKAGE_PIN P20           [get_ports {adc_clk_o[1]}]

#set_property IOB        TRUE           [get_ports {adc_clk_o[*]}]

# ADC clock stabilizer
set_property IOSTANDARD LVCMOS18       [get_ports adc_cdcs_o]
set_property PACKAGE_PIN V18           [get_ports adc_cdcs_o]
set_property SLEW SLOW                 [get_ports adc_cdcs_o]
set_property DRIVE 4                   [get_ports adc_cdcs_o]


### DAC
set_property IOSTANDARD LVCMOS33       [get_ports {dac_dat_o[*]}]
set_property IOSTANDARD LVCMOS33       [get_ports dac_clk_o]
set_property IOSTANDARD LVCMOS33       [get_ports dac_rst_o]
set_property IOSTANDARD LVCMOS33       [get_ports dac_sel_o]
set_property IOSTANDARD LVCMOS33       [get_ports dac_wrt_o]

set_property SLEW SLOW                 [get_ports {dac_dat_o[*]}]
set_property SLEW SLOW                 [get_ports dac_clk_o]
set_property SLEW SLOW                 [get_ports dac_rst_o]
set_property SLEW SLOW                 [get_ports dac_sel_o]
set_property SLEW SLOW                 [get_ports dac_wrt_o]

set_property DRIVE 4                   [get_ports {dac_dat_o[*]}]
set_property DRIVE 4                   [get_ports dac_clk_o]
set_property DRIVE 4                   [get_ports dac_rst_o]
set_property DRIVE 4                   [get_ports dac_sel_o]
set_property DRIVE 4                   [get_ports dac_wrt_o]

set_property PACKAGE_PIN M19           [get_ports {dac_dat_o[0]}]
set_property PACKAGE_PIN M20           [get_ports {dac_dat_o[1]}]
set_property PACKAGE_PIN L19           [get_ports {dac_dat_o[2]}]
set_property PACKAGE_PIN L20           [get_ports {dac_dat_o[3]}]
set_property PACKAGE_PIN K19           [get_ports {dac_dat_o[4]}]
set_property PACKAGE_PIN J19           [get_ports {dac_dat_o[5]}]
set_property PACKAGE_PIN J20           [get_ports {dac_dat_o[6]}]
set_property PACKAGE_PIN H20           [get_ports {dac_dat_o[7]}]
set_property PACKAGE_PIN G19           [get_ports {dac_dat_o[8]}]
set_property PACKAGE_PIN G20           [get_ports {dac_dat_o[9]}]
set_property PACKAGE_PIN F19           [get_ports {dac_dat_o[10]}]
set_property PACKAGE_PIN F20           [get_ports {dac_dat_o[11]}]
set_property PACKAGE_PIN D20           [get_ports {dac_dat_o[12]}]
set_property PACKAGE_PIN D19           [get_ports {dac_dat_o[13]}]

set_property PACKAGE_PIN M17           [get_ports dac_wrt_o]
set_property PACKAGE_PIN N16           [get_ports dac_sel_o]
set_property PACKAGE_PIN M18           [get_ports dac_clk_o]
set_property PACKAGE_PIN N15           [get_ports dac_rst_o]

#set_property IOB TRUE                  [get_ports dac_*_o]

### PWM DAC
set_property IOSTANDARD LVCMOS18       [get_ports {dac_pwm_o[*]}]
set_property SLEW SLOW                 [get_ports {dac_pwm_o[*]}]
set_property DRIVE 4                   [get_ports {dac_pwm_o[*]}]
#set_property IOB TRUE                  [get_ports {dac_pwm_o[*]}]

set_property PACKAGE_PIN T10           [get_ports {dac_pwm_o[0]}]
set_property PACKAGE_PIN T11           [get_ports {dac_pwm_o[1]}]
set_property PACKAGE_PIN P15           [get_ports {dac_pwm_o[2]}]
set_property PACKAGE_PIN U13           [get_ports {dac_pwm_o[3]}]

### XADC
set_property IOSTANDARD LVCMOS33       [get_ports {vinp_i[*]}]
set_property IOSTANDARD LVCMOS33       [get_ports {vinn_i[*]}]
#set_property LOC XADC_X0Y0             [get_cells i_ps/system_i/system_i/xadc_GP1/inst]
#AD0
#AD1
#AD8
#AD9
#V_0
set_property PACKAGE_PIN K9            [get_ports {vinp_i[4]}]
set_property PACKAGE_PIN L10           [get_ports {vinn_i[4]}]
set_property PACKAGE_PIN E18           [get_ports {vinp_i[3]}]
set_property PACKAGE_PIN E19           [get_ports {vinn_i[3]}]
set_property PACKAGE_PIN E17           [get_ports {vinp_i[2]}]
set_property PACKAGE_PIN D18           [get_ports {vinn_i[2]}]
set_property PACKAGE_PIN B19           [get_ports {vinp_i[0]}]
set_property PACKAGE_PIN A20           [get_ports {vinn_i[0]}]
set_property PACKAGE_PIN C20           [get_ports {vinp_i[1]}]
set_property PACKAGE_PIN B20           [get_ports {vinn_i[1]}]

### Expansion connector
set_property IOSTANDARD LVCMOS33       [get_ports {exp_p_io[*]}]
set_property IOSTANDARD LVCMOS33       [get_ports {exp_n_io[*]}]
set_property SLEW SLOW                 [get_ports {exp_p_io[*]}]
set_property SLEW SLOW                 [get_ports {exp_n_io[*]}]
set_property DRIVE 4                   [get_ports {exp_p_io[*]}]
set_property DRIVE 4                   [get_ports {exp_n_io[*]}]

set_property PACKAGE_PIN G17           [get_ports {exp_p_io[0]}]
set_property PACKAGE_PIN G18           [get_ports {exp_n_io[0]}]
set_property PACKAGE_PIN H16           [get_ports {exp_p_io[1]}]
set_property PACKAGE_PIN H17           [get_ports {exp_n_io[1]}]
set_property PACKAGE_PIN J18           [get_ports {exp_p_io[2]}]
set_property PACKAGE_PIN H18           [get_ports {exp_n_io[2]}]
set_property PACKAGE_PIN K17           [get_ports {exp_p_io[3]}]
set_property PACKAGE_PIN K18           [get_ports {exp_n_io[3]}]
set_property PACKAGE_PIN L14           [get_ports {exp_p_io[4]}]
set_property PACKAGE_PIN L15           [get_ports {exp_n_io[4]}]
set_property PACKAGE_PIN L16           [get_ports {exp_p_io[5]}]
set_property PACKAGE_PIN L17           [get_ports {exp_n_io[5]}]
set_property PACKAGE_PIN K16           [get_ports {exp_p_io[6]}]
set_property PACKAGE_PIN J16           [get_ports {exp_n_io[6]}]
set_property PACKAGE_PIN M14           [get_ports {exp_p_io[7]}]
set_property PACKAGE_PIN M15           [get_ports {exp_n_io[7]}]

#set_property PULLDOWN TRUE             [get_ports {exp_p_io[0]}]
#set_property PULLDOWN TRUE             [get_ports {exp_n_io[0]}]
#set_property PULLUP   TRUE             [get_ports {exp_p_io[7]}]
#set_property PULLUP   TRUE             [get_ports {exp_n_io[7]}]

### SATA connector
#  T12: IO_L2P_T0_34        #  U12: IO_L2N_T0_34         #  Bank: 34  #  I/O type: HR
#  U14: IO_L11P_T1_SRCC_34  #  U15: IO_L11N_T1_SRCC_34   #  Bank: 34  #  I/O type: HR
#  P14: IO_L6P_T0_34        #  R14: IO_L6N_T0_VREF_34    #  Bank: 34  #  I/O type: HR
#  N18: IO_L13P_T2_MRCC_34  #  P19: IO_L13N_T2_MRCC_34   #  Bank: 34  #  I/O type: HR
set_property IOSTANDARD LVCMOS18       [get_ports {daisy_p_o[*]}]
set_property IOSTANDARD LVCMOS18       [get_ports {daisy_n_o[*]}]
set_property IOSTANDARD LVCMOS18       [get_ports {daisy_p_i[*]}]
set_property IOSTANDARD LVCMOS18       [get_ports {daisy_n_i[*]}]

set_property PACKAGE_PIN T12           [get_ports {daisy_p_o[0]}]
set_property PACKAGE_PIN U12           [get_ports {daisy_n_o[0]}]
set_property PACKAGE_PIN U14           [get_ports {daisy_p_o[1]}]
set_property PACKAGE_PIN U15           [get_ports {daisy_n_o[1]}]
set_property PACKAGE_PIN P14           [get_ports {daisy_p_i[0]}]
set_property PACKAGE_PIN R14           [get_ports {daisy_n_i[0]}]
set_property PACKAGE_PIN N18           [get_ports {daisy_p_i[1]}]
set_property PACKAGE_PIN P19           [get_ports {daisy_n_i[1]}]

### LED
set_property IOSTANDARD LVCMOS33       [get_ports {led_o[*]}]
set_property SLEW SLOW                 [get_ports {led_o[*]}]
set_property DRIVE 4                   [get_ports {led_o[*]}]

set_property PACKAGE_PIN F16           [get_ports {led_o[0]}]
set_property PACKAGE_PIN F17           [get_ports {led_o[1]}]
set_property PACKAGE_PIN G15           [get_ports {led_o[2]}]
set_property PACKAGE_PIN H15           [get_ports {led_o[3]}]
set_property PACKAGE_PIN K14           [get_ports {led_o[4]}]
set_property PACKAGE_PIN G14           [get_ports {led_o[5]}]
set_property PACKAGE_PIN J15           [get_ports {led_o[6]}]
set_property PACKAGE_PIN J14           [get_ports {led_o[7]}]


## Timing Assertions Section (UG911 - Constraint Sequence)
# Primary clocks
create_clock -period 64.000  -name dna_clk  [get_nets  i_hk/dna_clk]
create_clock -period  4.000  -name rx_clk   [get_ports {daisy_p_i[1]}]

# Virtual clocks
create_clock -period  4.000  -name VIRTUAL_clk_dac_2x_adc_clk_pll -waveform {0.000 2.000}
create_clock -period  4.000  -name VIRTUAL_clk_dac_2p_adc_clk_pll -waveform {3.000 5.000}

# Generated clocks
create_generated_clock -name dac_clk_o  -source [get_pins oddr_dac_clk/C]  -divide_by 1  -invert  [get_ports dac_clk_o]
create_generated_clock -name dac_wrt_o  -source [get_pins oddr_dac_wrt/C]  -divide_by 1  -invert  [get_ports dac_wrt_o]
create_generated_clock -name dac_sel_o  -source [get_pins oddr_dac_sel/C]  -divide_by 1           [get_ports dac_sel_o]

# Clock Groups
set_clock_groups -name async_clkfpga0_adcclk -asynchronous  -group [get_clocks -include_generated_clocks clk_fpga_0]  -group [get_clocks -include_generated_clocks adc_clk_p_i]
set_clock_groups -name async_clkfpga0_dnaclk -asynchronous  -group [get_clocks -include_generated_clocks clk_fpga_0]  -group [get_clocks -include_generated_clocks dna_clk]
set_clock_groups -name async_clkfpga0_rxclk  -asynchronous  -group [get_clocks -include_generated_clocks clk_fpga_0]  -group [get_clocks -include_generated_clocks rx_clk]

# Input and output delay constraints
set_input_delay  -clock [get_clocks adc_clk_p_i]                                -min             2.000  [get_ports {adc_dat_a_i[*]}]
set_input_delay  -clock [get_clocks adc_clk_p_i]                                -max             3.000  [get_ports {adc_dat_a_i[*]}]
set_input_delay  -clock [get_clocks adc_clk_p_i]                                -min             2.000  [get_ports {adc_dat_b_i[*]}]
set_input_delay  -clock [get_clocks adc_clk_p_i]                                -max             3.000  [get_ports {adc_dat_b_i[*]}]

set_input_delay  -clock [get_clocks rx_clk]                                     -min             2.000  [get_ports {daisy_p_i[0]}]
set_input_delay  -clock [get_clocks rx_clk]                                     -max             3.000  [get_ports {daisy_p_i[0]}]

set_input_delay  -clock [get_clocks clk_fpga_0]                                 -min             2.000  [get_ports {exp_n_io[*]}]
set_input_delay  -clock [get_clocks clk_fpga_0]                                 -max             3.000  [get_ports {exp_n_io[*]}]
set_input_delay  -clock [get_clocks clk_fpga_0]                                 -min             2.000  [get_ports {exp_p_io[*]}]
set_input_delay  -clock [get_clocks clk_fpga_0]                                 -max             3.000  [get_ports {exp_p_io[*]}]

set_output_delay -clock [get_clocks clk_fpga_0]                                 -min            -1.000  [get_ports {exp_n_io[*]}]
set_output_delay -clock [get_clocks clk_fpga_0]                                 -max             1.000  [get_ports {exp_n_io[*]}]
set_output_delay -clock [get_clocks clk_fpga_0]                                 -min            -1.000  [get_ports {exp_p_io[*]}]
set_output_delay -clock [get_clocks clk_fpga_0]                                 -max             1.000  [get_ports {exp_p_io[*]}]

set_output_delay -clock [get_clocks clk_dac_2p_adc_clk_pll]                     -min            -1.000  [get_ports dac_clk_o]
set_output_delay -clock [get_clocks clk_dac_2p_adc_clk_pll]                     -max             2.000  [get_ports dac_clk_o]
set_output_delay -clock [get_clocks clk_dac_2p_adc_clk_pll]         -clock_fall -min -add_delay -1.000  [get_ports dac_clk_o]
set_output_delay -clock [get_clocks clk_dac_2p_adc_clk_pll]         -clock_fall -max -add_delay  2.000  [get_ports dac_clk_o]

set_output_delay -clock [get_clocks dac_clk_o]                                  -min             0.350  [get_ports dac_wrt_o]
set_output_delay -clock [get_clocks dac_clk_o]                                  -max             0.640  [get_ports dac_wrt_o]
set_output_delay -clock [get_clocks dac_clk_o]                      -clock_fall -min -add_delay  0.350  [get_ports dac_wrt_o]
set_output_delay -clock [get_clocks dac_clk_o]                      -clock_fall -max -add_delay  0.640  [get_ports dac_wrt_o]

set_output_delay -clock [get_clocks adc_clk_p_i]                                -min            -1.000  [get_ports dac_sel_o]
set_output_delay -clock [get_clocks adc_clk_p_i]                                -max             0.800  [get_ports dac_sel_o]
set_output_delay -clock [get_clocks adc_clk_p_i]                    -clock_fall -min -add_delay -1.000  [get_ports dac_sel_o]
set_output_delay -clock [get_clocks adc_clk_p_i]                    -clock_fall -max -add_delay  0.800  [get_ports dac_sel_o]

set_output_delay -clock [get_clocks adc_clk_p_i]                                -min            -1.000  [get_ports dac_rst_o]
set_output_delay -clock [get_clocks adc_clk_p_i]                                -max             0.800  [get_ports dac_rst_o]
set_output_delay -clock [get_clocks adc_clk_p_i]                    -clock_fall -min -add_delay -1.000  [get_ports dac_rst_o]
set_output_delay -clock [get_clocks adc_clk_p_i]                    -clock_fall -max -add_delay  0.800  [get_ports dac_rst_o]

set_output_delay -clock [get_clocks adc_clk_p_i]                                -min            -1.000  [get_ports {dac_dat_o[*]}]
set_output_delay -clock [get_clocks adc_clk_p_i]                                -max             0.800  [get_ports {dac_dat_o[*]}]
set_output_delay -clock [get_clocks adc_clk_p_i]                    -clock_fall -min -add_delay -1.000  [get_ports {dac_dat_o[*]}]
set_output_delay -clock [get_clocks adc_clk_p_i]                    -clock_fall -max -add_delay  0.800  [get_ports {dac_dat_o[*]}]

## Timing Exceptions Section (sorted by precedence)
# False Paths
set_false_path  -from [get_pins dac_rst_reg/C]  -to [get_pins  oddr_dac_sel/R]
set_false_path  -from [get_pins dac_rst_reg/C]  -to [get_pins {oddr_dac_dat[*]/R}]

# Max Delay / Min Delay
#set_min_delay -rise_from [get_pins {i_ps/axi_slave_gp0/wr_wdata_reg[*]/C}] -rise_to [get_pins {i_regs/*_reg[*][0]/D}]  0.000
#set_max_delay -rise_from [get_pins {i_ps/axi_slave_gp0/wr_wdata_reg[*]/C}] -rise_to [get_pins {i_regs/*_reg[*][0]/D}]  9.000

# Multicycle Paths
set_multicycle_path -setup 3  -from [get_clocks clk_dac_2p_adc_clk_pll]  -to [get_ports dac_clk_o]
set_multicycle_path -hold  2  -from [get_clocks clk_dac_2p_adc_clk_pll]  -to [get_ports dac_clk_o]

set_multicycle_path -setup 3  -from [get_clocks dac_clk_o]               -to [get_clocks clk_dac_2p_adc_clk_pll]
set_multicycle_path -hold  2  -from [get_clocks dac_clk_o]               -to [get_clocks clk_dac_2p_adc_clk_pll]

# Case Analysis

# Disable Timing

## Physical Constraints Section
# located anywhere in the file, preferably before or after the timing constraints
# or stored in a separate XDC file
set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.GENERAL.XADCENHANCEDLINEARITY On [current_design]
