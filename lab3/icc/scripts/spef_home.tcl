source ../rm_setup/lcrm_setup.tcl
source -echo ../rm_setup/icc_setup.tcl
open_mw_lib cpu_pad.mw
copy_mw_cel -from route -to spef
open_mw_cel spef

source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl
change_names -hierarchy -rules verilog
write_verilog -no_physical_only_cells \
		-no_unconnected_cells \
		-no_tap_cells       \
		../output/cpu_pad_final.v

extract_rc -coupling_cap
write_parasitics -output ../output/cpu_pad.spef \
		-format SPEF \
		-no_name_mapping
