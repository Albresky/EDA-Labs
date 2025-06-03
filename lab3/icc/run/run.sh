#!/bin/bash

echo "Starting ICC flow..."

echo "source ./design_setup.tcl"
echo "exit" | source ./design_setup.tcl

echo "source ./floorplan.tcl"
echo "exit" | source ./floorplan.tcl

echo "source ./place.tcl"
echo "exit" | source ./place.tcl

echo "source ./cts.tcl"
echo "exit" | source ./cts.tcl

echo "source ./route.tcl"
echo "exit" | source ./route.tcl

echo "source ./spef_home.tcl"
echo "exit" | source ./spef_home.tcl

echo "pt_shell -f ./sdf_gen.tcl 2>&1 | tee ../logs/sdf_gen.log"
echo "exit" | pt_shell -f ./sdf_gen.tcl 2>&1 | tee ../logs/sdf_gen.log

