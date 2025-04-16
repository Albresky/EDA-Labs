.PHONY: run clean vivado clean_vivado all

all: run vivado

run:
	vitis_hls -f run.tcl

runbd:
	vitis_hls -f runbd.tcl

vivado: run
	vivado -mode batch -source vivado_run.tcl

clean:
	rm -rf *_prj *.log waveform logs *.png

clean_vivado:
	rm -rf vivado_prj .Xil *.jou *.str _ide .wsdata

clean_all: clean clean_vivado