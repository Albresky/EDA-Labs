#!/bin/bash

echo "Starting ICC flow..."

echo "source ./design_setup.tcl"
source ./design_setup.tcl

echo "source ./floorplan.tcl"
source ./floorplan.tcl

echo "source ./place.tcl"
source ./place.tcl

echo "source ./cts.tcl"
source ./cts.tcl

echo "source ./route.tcl"
source ./route.tcl

echo "source ./spef_home.tcl"
source ./spef_home.tcl

echo "pt_shell -f ./sdf_gen.tcl 2>&1 | tee ../logs/sdf_gen.log"
pt_shell -f ./sdf_gen.tcl 2>&1 | tee ../logs/sdf_gen.log

