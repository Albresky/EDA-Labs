FREQUENCIES := 20 50 150
SYN_DIR := syn
TCL_SOURCE := $(SYN_DIR)/scripts/dc_scripts.tcl
GEN_SCRIPT := $(SYN_DIR)/scripts/gen_tcl.sh
REPORT_DIRS := mapped rpt unmapped
SIM_DIR   := sim
LIBS      := /home/eda/houfang/smic13g.v /home/eda/houfang/SP013D3_V1p2.v
TOP       := cpu_pad_test
DEFINE    := +define+FSDB +define+SDF_$(1)MHz
VCS_FLAGS := -full64 -R +v2k -debug_all -timescale=1ns/1ps -debug_access

FREQ_DIRS := 	$(addprefix $(SYN_DIR)/mapped/,$(FREQUENCIES:%=%MHz)) \
       	 		$(addprefix $(SYN_DIR)/rpt/,$(FREQUENCIES:%=%MHz))    \
        		$(addprefix $(SYN_DIR)/unmapped/,$(FREQUENCIES:%=%MHz))

define SYNTH_TEMPLATE
synth_$(1)MHz: prepare_dirs $(SYN_DIR)/scripts/dc_$(1)MHz.tcl
	@echo "Running synthesis for $(1)MHz..."
	cd $(SYN_DIR) && dc_shell -f scripts/dc_$(1)MHz.tcl | tee logs/synth_$(1)MHz.log
	@echo "Synthesis for $(1)MHz completed"

$(SYN_DIR)/scripts/dc_$(1)MHz.tcl: $(TCL_SOURCE) $(GEN_SCRIPT)
	@echo "Generating dc_scripts with args: $(1), $(TCL_SOURCE), $(SYN_DIR)/scripts/dc_$(1)MHz.tcl" 
	$(GEN_SCRIPT) $(1) $(TCL_SOURCE) $(SYN_DIR)/scripts/dc_$(1)MHz.tcl
endef

$(foreach freq,$(FREQUENCIES),$(eval $(call SYNTH_TEMPLATE,$(freq))))

prepare_dirs:
	@mkdir -p $(FREQ_DIRS)
	@mkdir -p $(SYN_DIR)/logs
	@mkdir -p $(SIM_DIR)

define PREP_SIM
prepare_sim_$(1)MHz:
	@rm -rf $(SIM_DIR)/$(1)MHz/*
	@mkdir -p $(SIM_DIR)/$(1)MHz
	# 1) 拷映射网表到临时名
	@cp $(SYN_DIR)/mapped/$(1)MHz/cpu_pad.v \
	     $(SIM_DIR)/$(1)MHz/cpu_pad_mapped.v
	# 2) 拷入 RTL wrapper，命名为 cpu_pad.v
	@cp cpu/cpu_pad.v $(SIM_DIR)/$(1)MHz/cpu_pad.v
	# 3) 拷 testbench
	@cp cpu/cpu_pad_test.v  $(SIM_DIR)/$(1)MHz/
	# 4) 其余子模块
	@cp cpu/alu.v      $(SIM_DIR)/$(1)MHz/
	@cp cpu/clock.v      $(SIM_DIR)/$(1)MHz/
	@cp cpu/control.v      $(SIM_DIR)/$(1)MHz/
	@cp cpu/counter.v   $(SIM_DIR)/$(1)MHz/
	@cp cpu/cpu.v   $(SIM_DIR)/$(1)MHz/
	@cp cpu/dffr.v      $(SIM_DIR)/$(1)MHz/
	@cp cpu/mux.v       $(SIM_DIR)/$(1)MHz/
	@cp cpu/mem.v       $(SIM_DIR)/$(1)MHz/
	@cp cpu/register.v  $(SIM_DIR)/$(1)MHz/
	@cp cpu/scale_mux.v $(SIM_DIR)/$(1)MHz/
	@cp cpu/*.dat       $(SIM_DIR)/$(1)MHz/
endef


define SIM_TEMPLATE
sim_$(1)MHz: synth_$(1)MHz prepare_sim_$(1)MHz
	@echo ">>> Generating filelist for $(1)MHz ..."
	@find $(SIM_DIR)/$(1)MHz -name "*.v" > $(SIM_DIR)/$(1)MHz/filelist.f
	@echo ">>> Running VCS simulation for $(1)MHz ..."
	@vcs $(VCS_FLAGS) -f $(SIM_DIR)/$(1)MHz/filelist.f \
		$(LIBS) -top $(TOP) -o $(SIM_DIR)/$(1)MHz/sim_$(1)MHz \
		$(DEFINE)
	@echo ">>> Launching simulation $(1)MHz ..."
	@echo "$(1)MHz Sim projects are successfully created."
	@echo "Please cd '$(SIM_DIR)/$(1)MHz', and run './sim_$(1)MHz' to start simulation."
	@echo "After sim, we can analyze the waveform with file $(SIM_DIR)/$(1)MHz/$(TOP).vcd."
endef

$(foreach f,$(FREQUENCIES),$(eval $(call PREP_SIM,$(f))))
$(foreach f,$(FREQUENCIES),$(eval $(call SIM_TEMPLATE,$(f))))

syn_all: $(foreach f,$(FREQUENCIES),synth_$(f)MHz)

sim_all: $(foreach f,$(FREQUENCIES),sim_$(f)MHz)

all: syn_all sim_all

.PHONY: all syn_all sim_all

clean:
	rm -rf $(SYN_DIR)/mapped $(SYN_DIR)/rpt $(SYN_DIR)/unmapped $(SYN_DIR)/logs $(SYN_DIR)/alib-52 $(SYN_DIR)/command.log $(SYN_DIR)/default.svf $(SYN_DIR)/scripts/dc_*MHz.tcl sim
	rm -rf csrc *.vcd *.key *.dat