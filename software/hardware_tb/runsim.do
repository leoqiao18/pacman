##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# include netlist and testbench files
vlog +acc -incr ./vga_ball.sv
vlog +acc -incr ./vga_ball_tb.sv

# run simulation 
vsim -t ps -lib work testbench 
do waveformat.do   
run -all
