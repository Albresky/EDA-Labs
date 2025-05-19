#!/bin/bash
# run/design_setup.sh
if [ -f "../logs/design_setup.log" ]; then
    rm ../logs/design_setup.log
    rm -rf ./cpu_pad.mw
fi

stdbuf -o8192 icc_shell -64 -f ../scripts/design_setup.tcl | tee -i ../logs/design_setup.log