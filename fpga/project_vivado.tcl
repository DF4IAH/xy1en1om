################################################################################
# Vivado tcl script for building RedPitaya FPGA in non project mode
#
# Usage:
# vivado -mode batch -source project_vivado.tcl
################################################################################


################################################################################
# define paths
################################################################################

set path_bd  bd
set path_ip  ip
set path_rtl rtl
set path_sdc sdc


################################################################################
# setup an in memory project
################################################################################

set part xc7z010clg400-1

create_project -part $part -force project ./project


################################################################################
# create PS BD (processing system block design)
################################################################################

# create PS BD
source                            $path_ip/system_bd.tcl

# generate SDK files
generate_target all               [get_files system.bd]

# generate system_wrapper.v file to the target directory
make_wrapper -files               [get_files project/project.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse              project/project.srcs/sources_1/bd/system/hdl/system_wrapper.v


################################################################################
# read files:
# 1. RTL design sources
# 2. IP database files
# 3. constraints
################################################################################

#read_bd                          [get_files system.bd]

add_files                         $path_rtl/axi_master.v
add_files                         $path_rtl/axi_pc2leds.v
add_files                         $path_rtl/axi_slave.v
add_files                         $path_rtl/axi_wr_fifo.v

add_files                         $path_rtl/red_pitaya_hk.v
add_files                         $path_rtl/red_pitaya_pll.sv
add_files                         $path_rtl/red_pitaya_ps.v
add_files                         $path_rtl/red_pitaya_rst_clken.sv
add_files                         $path_rtl/regs.sv
add_files                         $path_rtl/top.sv

add_files -fileset constrs_1      $path_sdc/project.xdc

#import_files -force

update_compile_order -fileset sources_1

################################################################################
################################################################################

#start_gui
