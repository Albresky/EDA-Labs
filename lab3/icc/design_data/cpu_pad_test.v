`timescale 1 ns / 1 ps

module cpu_pad_test;  

  reg     rst_;
  reg [(3*8):1] mnemonic;
  wire [4:0] addr;
  wire [7:0] data_in;
  wire [7:0] data_out;
  wire clock;
  wire rd, wr;
  
  // Set different clock periods based on frequency
  `ifdef SDF_150MHz
      parameter real CLK_PERIOD = 6.67; // 150MHz
  `elsif SDF_50MHz
      parameter real CLK_PERIOD = 20.0; // 50MHz
  `elsif SDF_1MHz
      parameter real CLK_PERIOD = 2000.0;// 5MHz
  `elsif SDF_100KHz
      parameter real CLK_PERIOD = 10000.0;// 100KHz = 10μs      
  `else
      parameter real CLK_PERIOD = 50.0; // Default 20MHz
  `endif

// Instantiate clock generator
  clock_gen #(.PERIOD(CLK_PERIOD)) clk_gen (
    .clk(clock)
  );

// Instantiate gate-level netlist CPU
  cpu_pad cpu_pad1 
  ( 
    .rst_(rst_),
    .clock(clock), 
    .rd(rd),
    .wr(wr),
    .data_in(data_in),
    .data_out(data_out),
    .addr(addr)
  );

// Instantiate memory
  mem mem1 
  ( 
    .data_in(data_in),
    .data_out(data_out),
    .addr(addr), 
    .read(rd), 
    .write(wr) 
  );

// Generate mnemonic
  reg [2:0] opcode;
  always @(*) begin
    // Extract opcode from CPU internal signals - Note: path may need adjustment for gate-level netlist
    // opcode = 3'h0; // Default value, may need adjustment in actual use
    opcode = cpu_pad1.i_cpu_opcode; // Adjusted to use the opcode from the CPU instance
    case (opcode)
      3'h0    : mnemonic = "HLT";
      3'h1    : mnemonic = "SKZ";
      3'h2    : mnemonic = "ADD";
      3'h3    : mnemonic = "AND";
      3'h4    : mnemonic = "XOR";
      3'h5    : mnemonic = "LDA";
      3'h6    : mnemonic = "STO";
      3'h7    : mnemonic = "JMP";
      default : mnemonic = "???";
    endcase
  end

// Monitor signals
  initial begin
    $timeformat(-9, 1, " ns", 12);
    // $monitor("Time=%0t, clk=%b, pc_addr=%h, opcode=%h", 
            //  $time, clock, cpu_pad1.i_cpu_pc_addr, cpu_pad1.i_cpu_opcode);
    // Load appropriate SDF file based on frequency
    `ifdef SDF_150MHz
      $display("Using 150MHz SDF file for timing back-annotation");
      $sdf_annotate("./cpu_pad.sdf", cpu_pad1);
    `elsif SDF_50MHz
      $display("Using 50MHz SDF file for timing back-annotation");
      $sdf_annotate("./cpu_pad.sdf", cpu_pad1);
    `elsif SDF_1MHz
      $display("Using 1MHz SDF file for timing back-annotation");
      $sdf_annotate("./cpu_pad.sdf", cpu_pad1);
    `elsif SDF_100KHz
      $display("Using 100KHz SDF file for timing back-annotation");
      $sdf_annotate("./cpu_pad.sdf", cpu_pad1);
    `endif
    
    // Create waveform file
    $dumpfile("cpu_pad_test.vcd");
    $dumpvars(0, cpu_pad_test);
  end

// Apply stimulus
  always begin
    `ifdef INCA
     $display("\n************************************************************");
     $display("*        THE FOLLOWING DEBUG TASKS ARE AVAILABLE:          *");
     $display("* Enter \"scope cpu_test; deposit test.N 1; task test; run\" *");
     $display("*         to run the 1st diagnostic program.               *");
     $display("* Enter \"scope cpu_test; deposit test.N 2; task test; run\" *");
     $display("*         to run the 2nd diagnostic program.               *");
     $display("* Enter \"scope cpu_test; deposit test.N 3; task test; run\" *");
     $display("*         to run the Fibonacci program.                    *");
     $display("* Enter \"scope cpu_test; deposit test.N 4; task test; run\" *");
     $display("*         to run the COUNTER program.               *");
     $display("* Enter \"scope cpu_test; deposit test.N 5; task test; run\" *");
     $display("*         to run the 2^n program.                    *");
     $display("************************************************************\n");
    `else
     $display("\n***********************************************************");
     $display("*        THE FOLLOWING DEBUG TASKS ARE AVAILABLE:         *");
     $display("* Enter \"call test(1);run\" to run the 1st diagnostic program.   *");
     $display("* Enter \"call test(2);run\" to run the 2nd diagnostic program.   *");
     $display("* Enter \"call test(3);run\" to run the Fibonacci program.        *");
     $display("* Enter \"call test(4);run\" to run the COUNTER program.        *");
     $display("* Enter \"call test(5);run\" to run the 2^n program.        *");
     $display("***********************************************************\n");
    `endif
    $stop;
    @ (negedge clock)
    rst_ = 0;
    @ (negedge clock)
    rst_ = 1;
    // @ (posedge cpu_pad1.i_cpu.ctl1.halt)
    @ (posedge cpu_pad1.halt)
    $display("HALTED AT PC = %h", cpu_pad1.i_cpu_pc_addr);
    $finish;
  end

// Define the test task
  task test ;
    input [2:0] N ;
    reg [12*8:1] testfile ;
    if ( 1<=N && N<=5 )
      begin
        testfile = { "CPUtest", 8'h30+N, ".dat" } ;
        $readmemb ( testfile, mem1.memory ) ;  //将指令读入存储器
        case ( N )
          1:
            begin
              $display ( "RUNNING THE BASIC DIAGOSTIC TEST" ) ;
              $display ( "THIS TEST SHOULD HALT WITH PC = 17" ) ;
              $display ( "PC INSTR OP DATA_IN DATA_OUT ADDR HALT" ) ;
              $display ( "---  ----  --  --- ---  --- --" ) ;
              forever @ ( cpu_pad1.i_cpu_opcode or cpu_pad1.i_cpu_ir_addr )
	        $strobe ( "%h  %s  %h  %h  %h  %h   %h",
                   cpu_pad1.i_cpu_pc_addr, mnemonic, cpu_pad1.i_cpu_opcode, cpu_pad1.data_in_pad, cpu_pad1.data_out_pad, cpu_pad1.i_cpu_ir_addr, cpu_pad1.halt) ;
            end
          2:
            begin
              $display ( "RUNNING THE ADVANCED DIAGOSTIC TEST" ) ;
              $display ( "THIS TEST SHOULD HALT WITH PC = 10" ) ;
              $display ( "PC INSTR OP DATA_IN DATA_OUT ADDR HALT" ) ;
              $display ( "---  ----  --  --- ---  --- --" ) ;
              forever @ ( cpu_pad1.i_cpu_opcode or cpu_pad1.i_cpu_ir_addr )
	        $strobe ( "%h %s   %h  %h  %h  %h  %h",
                        cpu_pad1.i_cpu_pc_addr, mnemonic, cpu_pad1.i_cpu_opcode, cpu_pad1.data_in_pad, cpu_pad1.data_out_pad, cpu_pad1.i_cpu_ir_addr, cpu_pad1.halt) ;
            end
           3:
              begin
                $display ( "RUNNING THE FIBONACCI CALCULATOR" ) ;
                $display ( "THIS PROGRAM SHOULD CALCULATE TO 144" ) ;
                $display ( "FIBONACCI NUMBER" ) ;
                $display ( " ---------------" ) ;
                forever @ ( cpu_pad1.i_cpu_opcode )
                  if (cpu_pad1.i_cpu_opcode == 3'h2)
                    $strobe ( "%d", mem1.memory[5'h1B] ) ;
              end
	  4:
             begin
                $display ( "RUNNING THE COUNTER CALCULATOR" ) ;
                $display ( "THIS PROGRAM IS A COUNTER" ) ;
                $display ( "COUNTER NUMBER" ) ;
                $display ( " ---------------" ) ;
                forever @ ( cpu_pad1.i_cpu_opcode )
                  if (cpu_pad1.i_cpu_opcode == 3'h4)
                    $strobe ( "%d", mem1.memory[5'h1D] ) ;
	     end
	  5:
             begin
                $display ( "RUNNING THE ODD CALCULATOR" ) ;
                $display ( "THIS PROGRAM IS A COUNTER" ) ;
                $display ( "COUNTER NUMBER" ) ;
                $display ( " ---------------" ) ;
                forever @ ( cpu_pad1.i_cpu_opcode )
                  if (cpu_pad1.i_cpu_opcode == 3'h3)
                    $strobe ( "%d", mem1.memory[5'h1A] ) ;
		
            end
        endcase
      end
    else
      begin
        $display("Not a valid test number. Please try again." ) ;
        $stop ;
      end
  endtask

endmodule

// Clock generator module
module clock_gen #(parameter real PERIOD = 20.0) (
  output reg clk
);
  initial begin
    clk = 0;
    forever #(PERIOD/2) clk = ~clk;
  end
endmodule 
