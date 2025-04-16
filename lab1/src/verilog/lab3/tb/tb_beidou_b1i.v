`timescale 1ns / 1ps

module tb_beidou_b1i;
    // Parameters
    parameter CLK_PERIOD = 10; // 10 ns (100 MHz clock)
    parameter B1I_SAMPLES_PER_CODE = 16368;
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg ap_start;
    reg signed [3:0] signal_buffer [0:B1I_SAMPLES_PER_CODE-1];
    reg [10:0] prn;
    wire ap_done;
    wire ap_idle;
    wire ap_ready;
    wire signal_detected;
    wire [10:0] code_phase;
    wire [7:0] doppler_bin;
    wire [31:0] peak_metric;
    wire [31:0] snr;
    
    // Instantiate the Unit Under Test (UUT)
    beidou_b1i_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .ap_start(ap_start),
        .signal_buffer(signal_buffer),
        .prn(prn),
        .ap_done(ap_done),
        .ap_idle(ap_idle),
        .ap_ready(ap_ready),
        .signal_detected(signal_detected),
        .code_phase(code_phase),
        .doppler_bin(doppler_bin),
        .peak_metric(peak_metric),
        .snr(snr)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Read test signal from file
    task load_signal_data;
        integer i, file, value;
        begin
            file = $fopen("test_signal.dat", "r");
            if (file == 0) begin
                $display("Error: Could not open test_signal.dat");
                $finish;
            end
            
            for (i = 0; i < B1I_SAMPLES_PER_CODE; i = i + 1) begin
                if ($fscanf(file, "%d", value) == 1) begin
                    signal_buffer[i] = value;
                end else begin
                    $display("Error: Unexpected end of file at index %d", i);
                    $finish;
                end
            end
            
            $fclose(file);
            $display("Test signal data loaded successfully");
        end
    endtask
    
    // Test procedure
    initial begin
        // Initialize signals
        rst_n = 0;
        ap_start = 0;
        prn = 11'd2; // Use PRN #2 for test
        
        // Load test data
        load_signal_data();
        
        // Apply reset
        #(CLK_PERIOD*5) rst_n = 1;
        #(CLK_PERIOD*5);
        
        // Start acquisition
        ap_start = 1;
        #(CLK_PERIOD);
        ap_start = 0;
        
        // Wait for acquisition to complete
        $display("Acquisition started, waiting for completion...");
        wait(ap_done);
        
        // Display results
        $display("Acquisition completed!");
        $display("Signal detected: %s", signal_detected ? "YES" : "NO");
        $display("Code phase: %d", code_phase);
        $display("Doppler bin: %d", doppler_bin);
        $display("Peak metric: %h", peak_metric);
        $display("SNR: %h", snr);
        
        // Add additional time to observe signals
        #(CLK_PERIOD*10);
        
        // End simulation
        $finish;
    end
    
    // Optional: Monitor key signals
    initial begin
        $monitor("Time = %t, State = %d, ap_idle = %b, ap_done = %b", 
                 $time, uut.state, ap_idle, ap_done);
    end
    
    // Generate VCD file for waveform viewing
    initial begin
        $dumpfile("tb_beidou_b1i.vcd");
        $dumpvars(0, tb_beidou_b1i);
    end
    
endmodule
