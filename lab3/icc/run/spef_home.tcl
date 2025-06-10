#!/bin/bash
if [ -f "../logs/spef_home.log" ]; then
    rm ../logs/spef_home.log
fi
stdbuf -o8192 icc_shell -64 -f ../scripts/spef_home.tcl | tee -i ../logs/spef_home.log
