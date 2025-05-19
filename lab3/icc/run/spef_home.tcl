echo ok

if{[file exists [which spef_home.log]]} 
 rm ../logs/spef_home.log
stdbuf -o8192 icc_shell -64 -f ../scripts/spef_home.tcl | tee -i ../logs/spef_home.log
