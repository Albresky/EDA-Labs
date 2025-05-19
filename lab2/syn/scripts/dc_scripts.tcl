#dc_scripts.tcl template
set design_name cpu_pad
set top_module cpu_pad

read_verilog ../cpu/alu.v
read_verilog ../cpu/clock.v
read_verilog ../cpu/control.v
read_verilog ../cpu/counter.v
read_verilog ../cpu/cpu.v
read_verilog ../cpu/cpu_pad.v
read_verilog ../cpu/dffr.v
read_verilog ../cpu/mem.v
read_verilog ../cpu/mux.v
read_verilog ../cpu/register.v
read_verilog ../cpu/scale_mux.v

# Set Top
current_design cpu_pad

# Link
link

write -hierarchy -f ddc -out unmapped/default/cpu_pad.ddc
list designs
list_libs
set lib_name typical_1v2c25

puts "=== Available Ports ==="
puts [get_ports *]

#Create clock object and set uncertainty
create_clock -period 20 [get_ports clock]
set_clock_uncertainty 0.2 [get_clocks clock]

suppress_message UID-401

#Set constraints on input ports
set_input_delay 0.1 -max -clock clock [remove_from_collection [all_inputs] [get_ports clock]]

#Set constraints on output ports
set_output_delay 1 -max -clock clock [all_outputs]

set_driving_cell -library $lib_name -lib_cell AND2X4 [remove_from_collection [all_inputs] [get_ports clock]]
set_load [expr [load_of $lib_name/AND2X4/A]*15] [all_outputs]

set_dont_touch_network [get_ports clock]
set_dont_touch_network [get_ports rst_]
set_dont_touch_network [get_ports *]

set verilogout_no_tri true

compile_ultra

report_constraint > ./rpt/default/rpt_consitraints
report_timing > ./rpt/default/rpt_timing
report_area > ./rpt/default/rpt_area
report_power > ./rpt/default/rpt_power

write -hierarchy -format ddc -output ./mapped/default/cpu_pad.ddc
write -hierarchy -format verilog -output ./mapped/default/cpu_pad.v
write_sdc ./mapped/default/cpu_pad.sdc
write_sdf ./mapped/default/cpu_pad.sdf

list_designs
list_libs

exit
