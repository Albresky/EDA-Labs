#!/bin/bash
if [ -f "../logs/cts.log" ]; then
    rm ../logs/cts.log
fi

stdbuf -o8192 icc_shell -64 -gui -f ../scripts/cts.tcl | tee -i ../logs/cts.log