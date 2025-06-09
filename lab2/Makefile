FREQUENCIES := 100KHz 1MHz 20MHz
SYN_DIR := syn
TCL_SOURCE := $(SYN_DIR)/scripts/dc_scripts.tcl
GEN_SCRIPT := $(SYN_DIR)/scripts/gen_tcl.sh
REPORT_DIRS := mapped rpt unmapped
SIM_DIR   := sim
LIBS      := /home/eda/houfang/smic13g.v /home/eda/houfang/SP013D3_V1p2.v
TOP       := cpu_pad_test
DEFINE    := +define+FSDB +define+SDF_$(1)
VCS_FLAGS := -full64 -R +v2k -debug_all -timescale=1ns/1ps -debug_access

FREQ_DIRS := 	$(addprefix $(SYN_DIR)/mapped/,$(FREQUENCIES)) \
       	 		$(addprefix $(SYN_DIR)/rpt/,$(FREQUENCIES))    \
        		$(addprefix $(SYN_DIR)/unmapped/,$(FREQUENCIES))

define SYNTH_TEMPLATE
synth_$(1): prepare_dirs $(SYN_DIR)/scripts/dc_$(1).tcl
	@echo "Running synthesis for $(1)..."
	cd $(SYN_DIR) && dc_shell -f scripts/dc_$(1).tcl | tee logs/synth_$(1).log
	@echo "Synthesis for $(1) completed"

$(SYN_DIR)/scripts/dc_$(1).tcl: $(TCL_SOURCE) $(GEN_SCRIPT)
	@echo "Generating dc_scripts with args: $(1), $(TCL_SOURCE), $(SYN_DIR)/scripts/dc_$(1).tcl" 
	$(GEN_SCRIPT) $(1) $(TCL_SOURCE) $(SYN_DIR)/scripts/dc_$(1).tcl
endef

$(foreach freq,$(FREQUENCIES),$(eval $(call SYNTH_TEMPLATE,$(freq))))

prepare_dirs:
	@mkdir -p $(FREQ_DIRS)
	@mkdir -p $(SYN_DIR)/logs
	@mkdir -p $(SIM_DIR)

define PREP_SIM
prepare_sim_$(1):
	@rm -rf $(SIM_DIR)/$(1)/*
	@mkdir -p $(SIM_DIR)/$(1)
	@cp $(SYN_DIR)/mapped/$(1)/cpu_pad.v \
	     $(SIM_DIR)/$(1)/cpu_pad_mapped.v
	@cp cpu/cpu_pad.v $(SIM_DIR)/$(1)/cpu_pad.v
	@cp cpu/cpu_pad_test.v  $(SIM_DIR)/$(1)/
	@cp cpu/alu.v      $(SIM_DIR)/$(1)/
	@cp cpu/clock.v      $(SIM_DIR)/$(1)/
	@cp cpu/control.v      $(SIM_DIR)/$(1)/
	@cp cpu/counter.v   $(SIM_DIR)/$(1)/
	@cp cpu/cpu.v   $(SIM_DIR)/$(1)/
	@cp cpu/dffr.v      $(SIM_DIR)/$(1)/
	@cp cpu/mux.v       $(SIM_DIR)/$(1)/
	@cp cpu/mem.v       $(SIM_DIR)/$(1)/
	@cp cpu/register.v  $(SIM_DIR)/$(1)/
	@cp cpu/scale_mux.v $(SIM_DIR)/$(1)/
	@cp cpu/*.dat       $(SIM_DIR)/$(1)/
endef


define SIM_TEMPLATE
sim_$(1): synth_$(1) prepare_sim_$(1)
	@echo ">>> Generating filelist for $(1) ..."
	@find $(SIM_DIR)/$(1) -name "*.v" > $(SIM_DIR)/$(1)/filelist.f
	@echo ">>> Running VCS simulation for $(1) ..."
	@vcs $(VCS_FLAGS) -f $(SIM_DIR)/$(1)/filelist.f \
		$(LIBS) -top $(TOP) -o $(SIM_DIR)/$(1)/sim_$(1) \
		$(DEFINE)
	@echo ">>> Launching simulation $(1) ..."
	@echo "========================================================"
	@echo "$(1) Sim projects are successfully created."
	@echo "Please cd '$(SIM_DIR)/$(1)', and run './sim_$(1)' to start simulation."
	@echo "After sim, we can analyze the waveform with file $(SIM_DIR)/$(1)/$(TOP).vcd."
endef

$(foreach f,$(FREQUENCIES),$(eval $(call PREP_SIM,$(f))))
$(foreach f,$(FREQUENCIES),$(eval $(call SIM_TEMPLATE,$(f))))

syn_all: $(foreach f,$(FREQUENCIES),synth_$(f))

sim_all: $(foreach f,$(FREQUENCIES),sim_$(f))

all: syn_all sim_all

.PHONY: all syn_all sim_all

clean:
	rm -rf $(SYN_DIR)/{mapped,rpt,unmapped,logs,alib-52,command.log,default.svf} $(SYN_DIR)/scripts/dc_*Hz.tcl sim
	rm -rf csrc *.vcd *.key *.dat *.log
	rm -rf $(SYN_DIR)/*.pvl $(SYN_DIR)/*.syn $(SYN_DIR)/*.mr $(SYN_DIR)/*.log