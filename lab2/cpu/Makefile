ll: clean com sim verdi

clean:
	rm -rf csrc simv.daidir *.log ucli.key simv verdi* *.dump

com:
	vcs -full64              \
    -f rtl.f -R +v2k         \
    -debug_access+all        \
    -timescale=1ns/1ns     \
    -debug_access +define+FSDB       \
    -l com.log

sim:
	./simv -l sim.log

verdi:
	verdi -f rtl.f -ssf *.fsdb -nologo &
