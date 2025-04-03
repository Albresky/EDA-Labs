open_project -reset sync_prj
set_top SignalSync
add_files TopFunc.cpp
add_files Transmitter.cpp
add_files -tb tb.cpp

open_solution -reset "solution1" -flow_target vivado
set_part {xc7z020clg400-1}
create_clock -period 10 -name default

set CSIM 1
set CSYNTH 1
set COSIM 1

if {$CSIM == 1} {
  puts "Starting Csim..."
  csim_design
}

if {$CSYNTH == 1} {
  puts "Starting Csynth..."
  csynth_design
}

if {$COSIM == 1} {
  puts "Starting Cosim..."
  cosim_design
}


exit

