#source ../rm_setup/lcrm_setup.tcl
#source -echo ../rm_setup/icc_setup.tcl
#source -echo ../scripts/common_optimization_settings_icc.tcl
#source -echo ../scripts/common_placement_settings_icc.tcl

set link_library "/home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db"
read_verilog ../output/cpu_pad_final.v
current_design cpu_pad
read_db /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db
read_db /home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db
read_parasitics -pin_cap_included ../output/cpu_pad.spef
write_sdf ../output/cpu_pad.sdf
