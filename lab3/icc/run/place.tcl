#!/bin/bash
if [ -f "../logs/place.log" ]; then
    rm ../logs/place.log
fi

stdbuf -o8192 icc_shell -64 -gui -f ../scripts/place.tcl | tee -i ../logs/place.log