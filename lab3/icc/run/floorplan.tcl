#!/bin/bash
if [ -f "../logs/floorplan.log" ]; then
    rm ../logs/floorplan.log
fi

stdbuf -o8192 icc_shell -64 -gui -f ../scripts/floorplan.tcl | tee -i ../logs/floorplan.log