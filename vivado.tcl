# vivado.tcl
#	MicroZed simple build script
#	Version 1.0
# 
# Copyright (C) 2013 H.Poetzl

set ODIR .

# set_param project.enableVHDL2008 1

# STEP#1: setup design sources and constraints

read_vhdl -vhdl2008 ../top.vhd
read_vhdl -vhdl2008 ../ps7_stub.vhd
read_vhdl -vhdl2008 ../axi_lite.vhd
read_vhdl -vhdl2008 ../axi_lite_slave.vhd

read_vhdl -vhdl2008 ../axi3_pkg.vhd
read_vhdl -vhdl2008 ../axi3_lite_pkg.vhd
read_vhdl -vhdl2008 ../vivado_pkg.vhd

# read_xdc ../top.xdc
read_xdc ../fclk.xdc
read_xdc ../pin_i2c.xdc
read_xdc ../pin_rf.xdc

set_property PART xc7z020clg400-1 [current_project]
set_property BOARD_PART em.avnet.com:microzed_7020:part0:1.1 [current_project]
set_property TARGET_LANGUAGE VHDL [current_project]

# STEP#2: run synthesis, write checkpoint design

synth_design -top top -flatten rebuilt    
write_checkpoint -force $ODIR/post_synth

# STEP#3: run placement and logic optimzation, write checkpoint design

opt_design -propconst -sweep -retarget -remap

place_design
phys_opt_design -critical_cell_opt -critical_pin_opt -placement_opt -hold_fix -rewire -retime
power_opt_design
write_checkpoint -force $ODIR/post_place

# STEP#4: run router, write checkpoint design

route_design 
write_checkpoint -force $ODIR/post_route

report_timing -no_header -path_type summary -max_paths 1000 -slack_lesser_than 0 -setup
report_timing -no_header -path_type summary -max_paths 1000 -slack_lesser_than 0 -hold

# STEP#4b: load and route probes

#source ../vivado_probes.tcl
#route_design -preserve

# STEP#5: generate a bitstream

set_property BITSTREAM.GENERAL.COMPRESS True [current_design]
set_property BITSTREAM.CONFIG.USERID "DEADC0DE" [current_design]
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property BITSTREAM.READBACK.ACTIVERECONFIG Yes [current_design]

write_bitstream -force $ODIR/i2cmin_axi_slave_reg.bit

# STEP#6: generate reports

report_clocks

report_utilization -hierarchical -file utilization.rpt
report_clock_utilization -file utilization.rpt -append
report_datasheet -file datasheet.rpt
report_timing_summary -file timing.rpt

puts "all done."
