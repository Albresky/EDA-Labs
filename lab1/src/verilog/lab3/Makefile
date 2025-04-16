# Makefile for Beidou B1I acquisition Verilog implementation

# Directory structure
SRC_DIR  = src
TB_DIR   = tb
BUILD_DIR = build
REPORTS_DIR = reports

# Tools and flags
IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave
YOSYS    = yosys
NEXTPNR  = nextpnr-ice40
ICEPACK  = icepack
VFLAGS   = -Wall -g2012 -I$(SRC_DIR)

# Source files
SRC_FILES = $(wildcard $(SRC_DIR)/*.v)
TB_FILES  = $(wildcard $(TB_DIR)/*.v)

# Target names
SIM_TARGET = $(BUILD_DIR)/beidou_b1i_sim
SYNTH_TARGET = $(BUILD_DIR)/beidou_b1i_synth.v
BIN_TARGET = $(BUILD_DIR)/beidou_b1i.bin

.PHONY: all clean sim test_signal synth bin view_wave lint help

# Default target
all: directories sim

# Create build directories
directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(REPORTS_DIR)

# Generate test signal
test_signal: directories
	@echo "Generating test signal data..."
	$(IVERILOG) $(VFLAGS) -o $(BUILD_DIR)/test_signal_gen $(TB_DIR)/test_signal_gen.v
	cd $(BUILD_DIR) && $(VVP) test_signal_gen
	@echo "Test signal generated: $(BUILD_DIR)/test_signal.dat"

# Compile and run simulation
sim: directories test_signal
	@echo "Compiling simulation..."
	$(IVERILOG) $(VFLAGS) -o $(SIM_TARGET) $(SRC_FILES) $(TB_DIR)/tb_beidou_b1i.v
	@echo "Running simulation..."
	cd $(BUILD_DIR) && $(VVP) $(notdir $(SIM_TARGET))
	@echo "Simulation complete. Check waveform data in $(BUILD_DIR)/tb_beidou_b1i.vcd"

# View waveform
view_wave: $(BUILD_DIR)/tb_beidou_b1i.vcd
	$(GTKWAVE) $< &

# Synthesize design using Yosys
synth: directories
	@echo "Synthesizing design with Yosys..."
	$(YOSYS) -q -l $(REPORTS_DIR)/yosys.log -p "read_verilog -sv $(SRC_FILES); hierarchy -top beidou_b1i_top; proc; opt; fsm; opt; memory; opt; synth; abc -liberty $(SRC_DIR)/cells.lib; clean; write_verilog $(SYNTH_TARGET)"
	@echo "Synthesis complete: $(SYNTH_TARGET)"
	@grep -A 10 "Printing statistics" $(REPORTS_DIR)/yosys.log

# Generate binary bitstream (for FPGA implementation)
bin: synth
	@echo "Generating bitstream using nextpnr and icepack..."
	$(NEXTPNR) --hx8k --json $(BUILD_DIR)/beidou_b1i.json --asc $(BUILD_DIR)/beidou_b1i.asc --pcf $(SRC_DIR)/constraints.pcf
	$(ICEPACK) $(BUILD_DIR)/beidou_b1i.asc $(BIN_TARGET)
	@echo "Bitstream generated: $(BIN_TARGET)"

# Run linter on Verilog code
lint: directories
	@echo "Running Verilator lint on source files..."
	verilator --lint-only -Wall $(SRC_FILES)
	@echo "Lint complete."

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -rf $(REPORTS_DIR)

# Help message
help:
	@echo "Beidou B1I Acquisition Makefile"
	@echo "Usage:"
	@echo "  make                 - Build and run simulation"
	@echo "  make test_signal     - Generate test signal data only"
	@echo "  make sim             - Run simulation only"
	@echo "  make view_wave       - View waveform with GTKWave"
	@echo "  make synth           - Synthesize using Yosys"
	@echo "  make bin             - Generate bitstream for FPGA"
	@echo "  make lint            - Run Verilator linting"
	@echo "  make clean           - Remove build artifacts"
	@echo "  make help            - Show this help message"
