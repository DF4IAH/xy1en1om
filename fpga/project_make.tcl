################################################################################
# Vivado tcl script for building RedPitaya FPGA in non project mode
#
# Usage:
# vivado -mode tcl -source project_make.tcl
################################################################################


################################################################################
# define paths
################################################################################

set path_bd  bd
set path_ip  ip
set path_rtl rtl
set path_sdc sdc

set path_out out
set path_sdk sdk

file mkdir $path_out
file mkdir $path_sdk


################################################################################
# setup an in memory project
################################################################################

set part xc7z010clg400-1

create_project -in_memory -part $part

# experimental attempts to avoid a warning
#get_projects
#get_designs
#list_property  [current_project]
#set_property FAMILY 7SERIES [current_project]
#set_property SIM_DEVICE 7SERIES [current_project]


################################################################################
# create PS BD (processing system block design)
################################################################################

# file was created from GUI using "write_bd_tcl -force ip/system_bd.tcl"
# create PS BD
source                            $path_ip/system_bd.tcl

# generate SDK files
generate_target all               [get_files system.bd]
write_hwdef    -force -file       $path_sdk/project.hwdef

# generate system_wrapper.v file to the target directory
make_wrapper -files               [get_files project/.srcs/sources_1/bd/system/system.bd] -top
read_verilog                      .srcs/sources_1/bd/system/hdl/system_wrapper.v


################################################################################
# read files:
# 1. RTL design sources
# 2. IP database files
# 3. constraints
################################################################################

# template
#read_verilog                     $path_rtl/...

#read_bd                          [get_files system.bd]

read_verilog                      $path_rtl/axi_master.v
read_verilog                      $path_rtl/axi_pc2leds.v
read_verilog                      $path_rtl/axi_slave.v
read_verilog                      $path_rtl/axi_wr_fifo.v

read_verilog                      $path_rtl/red_pitaya_hk.v
read_verilog   -sv                $path_rtl/red_pitaya_pll.sv
read_verilog                      $path_rtl/red_pitaya_ps.v
read_verilog   -sv                $path_rtl/red_pitaya_rst_clken.sv
read_verilog   -sv                $path_rtl/regs.sv
read_verilog   -sv                $path_rtl/top.sv

read_xdc                          $path_sdc/project.xdc


################################################################################
# run synthesis
# report utilization and timing estimates
# write checkpoint design
################################################################################

synth_ip                          [get_ips clk_adc_pll]

synth_design -top top -directive AreaOptimized_high
#synth_design -top top -flatten_hierarchy none -bufg 16 -keep_equivalent_registers

write_checkpoint         -force   $path_out/post_synth
report_timing_summary    -file    $path_out/post_synth_timing_summary.rpt
report_power             -file    $path_out/post_synth_power.rpt


################################################################################
# run placement and logic optimization
# report utilization and timing estimates
# write checkpoint design
################################################################################

opt_design -directive ExploreArea
power_opt_design
place_design
phys_opt_design
write_checkpoint         -force   $path_out/post_place
report_timing_summary    -file    $path_out/post_place_timing_summary.rpt
#write_hwdef      -force -file    $path_sdk/project.hwdef


################################################################################
# run router
# report actual utilization and timing,
# write checkpoint design
# run drc, write verilog and xdc out
################################################################################

route_design
write_checkpoint         -force   $path_out/post_route
report_timing_summary    -file    $path_out/post_route_timing_summary.rpt
report_timing            -file    $path_out/post_route_timing.rpt -sort_by group -max_paths 100 -path_type summary
report_clock_utilization -file    $path_out/clock_util.rpt
report_utilization       -file    $path_out/post_route_util.rpt
report_power             -file    $path_out/post_route_power.rpt
report_drc               -file    $path_out/post_imp_drc.rpt
#write_verilog            -force   $path_out/bft_impl_netlist.v
#write_xdc -no_fixed_only -force   $path_out/bft_impl.xdc


################################################################################
# generate a bitstream
################################################################################

write_bitstream -force $path_out/project.bit


################################################################################
# generate system definition
################################################################################

write_sysdef -force      -hwdef   $path_sdk/project.hwdef \
                         -bitfile $path_out/project.bit \
                         -file    $path_sdk/project.sysdef

exit
