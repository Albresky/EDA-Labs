# cts. tcl
source ../rm_setup/lcrm_setup.tcl
source -echo ../rm_setup/icc_setup.tcl
open_mw_lib cpu_pad.mw
copy_mw_cel -from placed -to cts
open_mw_cel placed
source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl
# source -echo common_cts_settings_icc.tcl
# Check The Design Before CTS
check_physical_design -stage pre_clock_opt
check_clock_tree
# Remove all ideal network settings on clocks
remove_ideal_network [get_ports clock]
remove_clock_uncertainty [all_clocks]
# set_delay_calculation_options -routed_clock arnoldi
# Defining CTS- Specific DRC Values
# The default values are to be used
# Specifying CTS Targets: Skew and Insertion Delay
set_clock_tree_option -target_early_delay 0.9
set_clock_tree_options -target_skew 0.2
set_clock_tree_options -buffer_relocation true
report_clock_tree -settings
# Control Buffer/ Inverter Selection
# If we dont define , all the Buffer/ Inverter cells can be used
#CTS and Timing Optimization
# Clock tree synthesis
clock_opt -no_clock_route -only_cts
update_clock_latency
report_clock_tree
report_clock_timing -type skew
# Post CTS Logic Optimization
set_fix_hold [all_clocks]
set_separate_process_options -placement false
clock_opt -only_psyn -no_clock_route
report_clock_tree
report_clock_timing -type skew
# Clock Tree Routing
set_fix_hold [all_clocks]
route_zrt_group -all_clock_nets -reuse_existing_global_route true
report_clock_tree
report_clock_timing -type skew
save_mw_cel -as cts
