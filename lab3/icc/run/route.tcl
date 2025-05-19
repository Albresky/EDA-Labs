#!/bin/bash
if [ -f "../logs/route.log" ]; then
    rm ../logs/route.log
fi

stdbuf -o8192 icc_shell -64 -gui -f ../scripts/route.tcl | tee -i ../logs/route.log