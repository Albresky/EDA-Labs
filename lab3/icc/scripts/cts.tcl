# cts. tcl
source ../rm_setup/lcrm_setup.tcl
source -echo ../rm_setup/icc_setup.tcl
open_mw_lib cpu_pad.mw
copy_mw_cel -from placed -to cts
open_mw_cel placed
source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

set_lib_cell_purpose -exclude [get_lib_cells */BUFX*] none
set_lib_cell_purpose -include [get_lib_cells "*/BUFX2 */BUFX3 */BUFX4 */BUFX6 */BUFX8"] cts

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
set_clock_tree_option -target_early_delay 1
set_clock_tree_options -target_skew 0.01
set_clock_tree_option -target_late_delay 2

set_clock_tree_options -optimize_for_hold true
set_clock_tree_options -optimize_for_setup true
set_clock_tree_options -buffer_relocation true
set_clock_tree_options -clock_gating_integrated_optimization true
set_clock_tree_options -use_default_skew_group false

set_clock_tree_options -setup_fixing true
set_clock_tree_options -logic_resynthesis true

# Enable force buffer sizing and gate sizing
set_clock_tree_options -buffer_sizing enable
set_clock_tree_options -gate_sizing enable

# Lowering the clock tree skew and transition
set_clock_tree_options -max_skew 0.1
set_clock_tree_options -max_trans 0.5

report_clock_tree -settings

# Control Buffer/ Inverter Selection
# If we dont define , all the Buffer/ Inverter cells can be used
#CTS and Timing Optimization

# Clock tree synthesis
clock_opt -no_clock_route -only_cts -optimize_hold_setup
update_clock_latency
report_clock_tree
report_clock_timing -type skew

# Post CTS Logic Optimization
set_fix_hold [all_clocks]
set_separate_process_options -placement false

clock_opt -only_psyn -no_clock_route -fix_setup_all_clocks
clock_opt -only_psyn -no_clock_route -fix_setup_all_clocks
clock_opt -only_psyn -no_clock_route -fix_setup_all_clocks
clock_opt -only_psyn -no_clock_route -fix_hold_all_clocks
clock_opt -only_psyn -no_clock_route -fix_setup_all_clocks
clock_opt -only_psyn -no_clock_route

report_clock_tree
report_clock_timing -type skew

# Clock Tree Routing
set_fix_hold [all_clocks]
route_zrt_group -all_clock_nets -reuse_existing_global_route true
report_clock_tree
report_clock_timing -type skew
save_mw_cel -as cts
