# Add this function at the beginning of the script to show available targets
proc show_available_targets {} {
    puts "\n=== Available FPGA Parts ==="
    set parts [get_parts]
    puts "Total parts available: [llength $parts]"
    puts "Sample parts (first 10):"
    foreach part [lrange $parts 0 9] {
        puts "  $part"
    }
    
    puts "\n=== Available Board Parts ==="
    set board_parts [get_board_parts]
    puts "Total board parts available: [llength $board_parts]"
    foreach board_part $board_parts {
        puts "  $board_part"
    }
    
    puts "\n=== Available Boards ==="
    set boards [get_boards]
    puts "Total boards available: [llength $boards]"
    foreach board $boards {
        puts "  $board"
    }
}

# Add a command-line argument check to run the show_targets function
if {$argc > 0} {
    set arg [lindex $argv 0]
    if {$arg == "show_targets"} {
        show_available_targets
        exit 0
    }
}

# Vivado project creation and simulation script
# This script creates a Vivado project that imports the HLS-generated RTL

# Set project directory and name
set proj_dir "./vivado_prj"
set proj_name "sync_vivado_prj"
set src_dir "./sync_prj/solution1/impl"
set top_module "TopFunc"
set target_part "xc7z020clg400-1"

# Create the project
create_project ${proj_name} ${proj_dir} -part ${target_part} -force

# Get and display project path
set proj_path [get_property DIRECTORY [current_project]]
puts "Project created at ${proj_path}"

# Use a board part that actually exists in your installation
# Changed from em.avnet.com:zed:part0:1.4 to xilinx.com:zc706:part0:1.4 based on available boards
set board_part "xilinx.com:zc706:part0:1.4"
set board_parts_list [get_board_parts]

if {[lsearch -exact $board_parts_list $board_part] != -1} {
    # Board part exists, set it
    set_property board_part $board_part [current_project]
    puts "Successfully set board part to $board_part"
} else {
    puts "WARNING: Board part '$board_part' is not available."
    puts "Available board parts:"
    foreach available_part $board_parts_list {
        puts "  $available_part"
    }
    puts "Continuing without setting board_part property..."
}

# Continue with the rest of your project setup
# Add source files, constraints, etc.
# REMOVED problematic direct file glob that was causing errors
# Rely on the more specific verilog/vhdl directory checks below instead

# Set the top module
set_property top $top_module [current_fileset]

puts "Project setup completed."

# Set project properties
set_property target_language VHDL [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib work [current_project]

# Create fileset sources
if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}
set source_set [get_filesets sources_1]

# Check if HLS output exists and import RTL files
set rtl_path "${src_dir}/verilog"
if {[file exists $rtl_path]} {
    puts "Importing HLS-generated RTL from ${rtl_path}"
    # Check if files exist before trying to add them
    set v_files [glob -nocomplain ${rtl_path}/*.v]
    if {[llength $v_files] > 0} {
        add_files -norecurse -fileset $source_set $v_files
        puts "Added [llength $v_files] Verilog files"
    } else {
        puts "WARNING: No Verilog files found in ${rtl_path}"
    }
} else {
    # If Verilog files not found, try VHDL
    set rtl_path "${src_dir}/vhdl"
    if {[file exists $rtl_path]} {
        puts "Importing HLS-generated RTL from ${rtl_path}"
        set vhd_files [glob -nocomplain ${rtl_path}/*.vhd]
        if {[llength $vhd_files] > 0} {
            add_files -norecurse -fileset $source_set $vhd_files
            puts "Added [llength $vhd_files] VHDL files"
        } else {
            puts "WARNING: No VHDL files found in ${rtl_path}"
        }
    } else {
        puts "ERROR: HLS-generated RTL not found. Please run HLS synthesis first."
        puts "Expected directory structure not found at: ${src_dir}/verilog or ${src_dir}/vhdl"
        puts "Current directory is: [pwd]"
        puts "Checking if base directory exists: [file exists $src_dir]"
        puts "Contents of src_dir (if it exists):"
        catch {puts [exec ls -la $src_dir]}
        exit 1
    }
}

# Create simulation fileset if it doesn't exist already
if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
    puts "Created simulation fileset sim_1"
} else {
    puts "Using existing simulation fileset sim_1"
}
set sim_set [get_filesets sim_1]
set_property top_lib xil_defaultlib $sim_set
set_property top ${top_module}_tb $sim_set

# Create a simple testbench file
set tb_file [file join $proj_dir "${top_module}_tb.v"]
set fp [open $tb_file "w"]
puts $fp "// Auto-generated testbench for ${top_module}"
puts $fp "\`timescale 1ns / 1ps"
puts $fp "module ${top_module}_tb();"
puts $fp ""
puts $fp "    // Clock and reset"
puts $fp "    reg ap_clk = 0;"
puts $fp "    reg ap_rst = 1;"
puts $fp "    wire ap_done;"
puts $fp "    wire ap_idle;"
puts $fp "    wire ap_ready;"
puts $fp ""
puts $fp "    // Input signals"
puts $fp "    reg [14:0] test_data = 14'b10101010101010;"
puts $fp "    reg [4:0] tx_m_state = 5'b10101;"
puts $fp "    reg [4:0] rx_m_state = 5'b01010;"
puts $fp "    reg ap_start = 0;"
puts $fp ""
puts $fp "    // Output signals"
puts $fp "    wire sync_flag;"
puts $fp ""
puts $fp "    // Clock generation"
puts $fp "    always #5 ap_clk = ~ap_clk;"
puts $fp ""
puts $fp "    // DUT instantiation"
puts $fp "    ${top_module} DUT ("
puts $fp "        .ap_clk(ap_clk),"
puts $fp "        .ap_rst(ap_rst),"
puts $fp "        .ap_start(ap_start),"
puts $fp "        .ap_done(ap_done),"
puts $fp "        .ap_idle(ap_idle),"
puts $fp "        .ap_ready(ap_ready),"
puts $fp "        .test_data(test_data),"
puts $fp "        .tx_m_state(tx_m_state),"
puts $fp "        .rx_m_state(rx_m_state),"
puts $fp "        .sync_flag(sync_flag)"
puts $fp "    );"
puts $fp ""
puts $fp "    // Test sequence"
puts $fp "    initial begin"
puts $fp "        // Reset sequence"
puts $fp "        #100 ap_rst = 0;"
puts $fp "        #10 ap_start = 1;"
puts $fp ""
puts $fp "        // Wait for completion"
puts $fp "        wait(ap_done);"
puts $fp ""
puts $fp "        // End simulation"
puts $fp "        #100 \$display(\"Simulation finished\");"
puts $fp "        #10 \$finish;"
puts $fp "    end"
puts $fp ""
puts $fp "    // Monitor outputs"
puts $fp "    initial begin"
puts $fp "        \$monitor(\"Time %t: sync_flag=%b\", \$time, sync_flag);"
puts $fp "    end"
puts $fp ""
puts $fp "endmodule"
close $fp

# Add the testbench file to simulation fileset
add_files -fileset $sim_set $tb_file

# Set simulation properties
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects $sim_set

# Define constraint file (empty for simulation-only)
set constr_file [file join $proj_dir "constraints.xdc"]
set fp [open $constr_file "w"]
puts $fp "# Empty constraint file for simulation"
close $fp
add_files -fileset constrs_1 $constr_file

# Save project
save_project_as ${proj_name} ${proj_dir} -force

# Run synthesis if needed
# Uncomment the following line to run synthesis automatically
# launch_runs synth_1 -jobs 4
# wait_on_run synth_1

# Launch simulation
launch_simulation
start_gui

puts "Vivado project created and simulation launched."