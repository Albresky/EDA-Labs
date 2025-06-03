LAB2_PATH=/home/b16/lab2
# Only low clock frequency is supported for SDF(100KHz below 
# is test and passed). In current design, higher frequencies 
# will not meet timing requirements (setup-time mainly).
FREQ=100KHz

.PHONY: run sim clean

run:
	@echo "Cleaning up previous runs..."
	cd run && rm -rf cpd_pre* cpu_pad.mw ctr_tmp snapshot *.log *.txt *.html && cd -
	@echo "Copying syn files from lab2..."
	cp -r $(LAB2_PATH)/syn/mapped/$(FREQ)/cpu_pad.* ./design_data/
	cd ./run && ./run.sh

sim: 
	cp ./design_data/cpu_pad_test.v ./output/
	cp $(LAB2_PATH)/cpu/mem.v ./output/
	cp $(LAB2_PATH)/cpu/CPUtest*.dat ./output/
	echo "./mem.v" > ./output/filelist.f
	cd ./output && \
	vcs -full64 \
	-f ./filelist.f \
	-R +v2k \
	-top cpu_pad_test \
	-debug_acc+all \
	-debug_all \
	+define+FSDB \
	+define+SDF_$(FREQ) \
	/home/eda/houfang/smic13g.v \
	/home/eda/houfang/SP013D3_V1p2.v \
	./cpu_pad_test.v \
	./cpu_pad_final.v \
	2>&1 | tee ../logs/sim.log

clean:
	rm -rf *.log *.txt
	rm -rf logs/*.log
	rm -rf ./run/cpu_pad.mw ./run/ctr_tmp ./run/pna_output ./run/snapshot ./run/.__tmp_pns_undo_file.tcl
	rm -rf ./run/*.txt ./run/*.html ./run/*.log
	rm -rf ./run/cpd_pre_* ./run/*.acts
	rm -rf ./run/.lock ./rpts/* ./work/*
	rm -rf ./output/*
	rm -rf ./design_data/cpu_pad.*
	rm -rf csrc simv.daidir simv *.vcd ucli.key

