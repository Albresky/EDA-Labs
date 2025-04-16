TOP_MODULE = TopFunc_tb
SRC_FILES = TopFunc_tb.v TopFunc.v PhaseDetector.v LocalCarrier.v GenerateMCode.v CodeController.v DownConvert.v Integrator.v EnergyCalc.v Transmitter.v Receiver.v
VCD_FILE = $(TOP_MODULE).vcd

all: run

compile:
	iverilog -o $(TOP_MODULE).out $(SRC_FILES)

run: compile
	vvp $(TOP_MODULE).out

clean:
	rm -f *.out *.vcd
