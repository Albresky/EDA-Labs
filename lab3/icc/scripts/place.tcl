source ../rm_setup/lcrm_setup.tcl
source -echo ../rm_setup/icc_setup.tcl

open_mw_lib cpu_pad.mw
copy_mw_cel -from floorplaned -to place
open_mw_cel place

#######################################
source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl
#######################################

check_physical_design -stage pre_place_opt
set_ideal_network [all_fanout -flat -from [get_ports clock]]
set_separate_process_options -placement false
place_opt -area_recovery -congestion
psynopt -area_recovery -congestion
refine_placement -congestion_effort high
psynopt -area_recovery -congestion

create_qor_snapshot -name placed
query_qor_snapshot -name placed
save_mw_cel -as placed
