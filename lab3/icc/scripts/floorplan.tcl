source ../rm_setup/lcrm_setup.tcl
source -echo ../rm_setup/icc_setup.tcl
open_mw_lib cpu_pad.mw
copy_mw_cel -from data_setup -to floorplan
open_mw_cel floorplan

#########################################
# Create Corner and Power Pads
########################################
create_cell {cornerll cornerlr cornerul cornerur} PCORNER
create_cell {vss1left vss1right} PVSS1  ; # core ground
create_cell {vdd1left vdd1right} PVDD1  ; # core supply
create_cell {vss2top vss2bottom} PVSS2  ; # pad ground
create_cell {vdd2top vdd2bottom} PVDD2  ; # pad supply

# Place corner pads
set_pad_physical_constraints -pad_name "cornerul" -side 1
set_pad_physical_constraints -pad_name "cornerur" -side 2
set_pad_physical_constraints -pad_name "cornerlr" -side 3
set_pad_physical_constraints -pad_name "cornerll" -side 4

#########################################
# Place I/O Pads
########################################
# Top side (side 2)
set_pad_physical_constraints -pad_name "vdd2top" -side 2 -order 1
set_pad_physical_constraints -pad_name "vss2top" -side 2 -order 2
set_pad_physical_constraints -pad_name "i_data_out_7" -side 2 -order 3
set_pad_physical_constraints -pad_name "i_data_out_6" -side 2 -order 4
set_pad_physical_constraints -pad_name "i_data_out_5" -side 2 -order 5
set_pad_physical_constraints -pad_name "i_data_out_4" -side 2 -order 6

# Right side (side 3)
set_pad_physical_constraints -pad_name "vdd1right" -side 3 -order 1
set_pad_physical_constraints -pad_name "vss1right" -side 3 -order 2
set_pad_physical_constraints -pad_name "o_addr_4" -side 3 -order 3
set_pad_physical_constraints -pad_name "o_addr_3" -side 3 -order 4
set_pad_physical_constraints -pad_name "o_addr_2" -side 3 -order 5
set_pad_physical_constraints -pad_name "o_addr_1" -side 3 -order 6

# Bottom side (side 4)
set_pad_physical_constraints -pad_name "vdd2bottom" -side 4 -order 1
set_pad_physical_constraints -pad_name "vss2bottom" -side 4 -order 2
set_pad_physical_constraints -pad_name "o_addr_0" -side 4 -order 3
set_pad_physical_constraints -pad_name "o_rd" -side 4 -order 4
set_pad_physical_constraints -pad_name "o_wr" -side 4 -order 5
set_pad_physical_constraints -pad_name "i_data_out_3" -side 4 -order 6

# Left side (side 1)
set_pad_physical_constraints -pad_name "vdd1left" -side 1 -order 1
set_pad_physical_constraints -pad_name "vss1left" -side 1 -order 2
set_pad_physical_constraints -pad_name "i_rst_" -side 1 -order 3
set_pad_physical_constraints -pad_name "i_clock" -side 1 -order 4
set_pad_physical_constraints -pad_name "i_data_out_2" -side 1 -order 5
set_pad_physical_constraints -pad_name "i_data_out_1" -side 1 -order 6

# Place inout data_in pads (mixed on sides)
set_pad_physical_constraints -pad_name "io_data_in_7" -side 2 -order 7
set_pad_physical_constraints -pad_name "io_data_in_6" -side 2 -order 8
set_pad_physical_constraints -pad_name "io_data_in_5" -side 3 -order 7
set_pad_physical_constraints -pad_name "io_data_in_4" -side 3 -order 8
set_pad_physical_constraints -pad_name "io_data_in_3" -side 4 -order 7
set_pad_physical_constraints -pad_name "io_data_in_2" -side 4 -order 8
set_pad_physical_constraints -pad_name "io_data_in_1" -side 1 -order 7
set_pad_physical_constraints -pad_name "io_data_in_0" -side 1 -order 8

##########################################
# Create Floorplan
##########################################
create_floorplan -control_type aspect_ratio -core_aspect_ratio 1 -core_utilization 0.5 \
-left_io2core 30 -bottom_io2core 30 -right_io2core 30 -top_io2core 30 -start_first_row

save_mw_cel -as floorplaned

##########################################
# Insert Pad Fillers
##########################################
insert_pad_filler -cell "PFILL001 PFILL01 PFILL1 PFILL10 PFILL2 PFILL20 PFILL5 PFILL50"

##########################################
# Specify Unrouting Layers
##########################################
set_ignored_layers -max_routing_layer METAL6
report_ignored_layers

##########################################
# Create the Power Network
##########################################
# Define power strategy
set_power_plan_strategy core -core -nets {VDD VSS} \
-template ../scripts/basic_ring.tpl:basic_ring

# Compile power plan
compile_power_plan -ring
compile_power_plan

# Derive power connections
derive_pg_connection -create_net
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
derive_pg_connection -power_net VDD -ground_net VSS -tie

save_mw_cel -as floorplanafterpn

##########################################
# Route Standard Cell Rails
##########################################
set_preroute_drc_strategy -min_layer METAL3 -max_layer METAL8
preroute_standard_cells -nets "VDD VSS" -remove_floating_pieces -do_not_route_over_macros

create_fp_placement -congestion -timing -no_hierarchy_gravity
route_zrt_global -congestion_map_only true -exploration true
preroute_instances

save_mw_cel -as floorplaned
