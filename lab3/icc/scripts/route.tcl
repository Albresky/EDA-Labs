# route. tcl
source ../rm_setup/lcrm_setup.tcl
source -echo ../rm_setup/icc_setup.tcl
open_mw_lib cpu_pad.mw
copy_mw_cel -from cts -to route
open_mw_cel route

#######################################################
source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

set_lib_cell_purpose -exclude [get_lib_cells */BUFX*] none
set_lib_cell_purpose -include [get_lib_cells "*/BUFX2 */BUFX3 */BUFX4 */BUFX6 */BUFX8"] cts

insert_buffer -buffer_list "BUFX2 BUFX3 BUFX4" -number_of_buffers 200

##########################################################
# Pre- Routing Checks
########################################################
check_physical_design -stage pre_route_opt
all_ideal_nets
all_high_fanout -nets -threshold 20
report_preferred_routing_direction
#######################################################
# Pre- Routing Setup
###########
derive_pg_connection -power_net VDD -power_pin VDD \
	-ground_net VSS -ground_pin VSS -tie;# Connect P/G Pins to supply nets,
#######
# Route Clock Nets Before Signal Nets
##################################################################################
route_zrt_group -all_clock_nets -reuse_existing_global_route true
#########################################################
# Route the Signal Nets
########## ##############################
route_opt -initial_route_only
save_mw_cel -as signal_route
##########################################################
# Perform full post- route optimization
#####################################################
set_si_options -delta_delay true -static_noise true
route_opt -skip_initial_route -xtalk_reduction -power
#####################################################
# Incremental Optimization
########################################################
# Focus on hold time fixing only
set_fix_hold [all_clocks]

# 1st opt
route_opt -incremental -only_setup_time -effort high
# 2nd opt
route_opt -incremental -only_hold_time -effort high
route_opt -incremental -effort high

save_mw_cel -as routed

# Focus logical DRC violations
set_app_var routeopt_drc_over_timing true
route_opt -incremental -effort high
route_opt -incremental -only_design_rule -effort high
route_opt -incremental -only_setup_time -effort high
route_opt -incremental -effort high
############## ########
# Check and Fix Physical DRC Violations
##################################################
verify_zrt_route; # Uses Zroute DRC engine
set_route_zrt_detail_options -repair_shorts_over_macros_effort_level high
route_zrt_detail -incremental true; # Fix DRCs
save_mw_cel -as route
