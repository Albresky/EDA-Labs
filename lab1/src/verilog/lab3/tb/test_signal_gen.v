`timescale 1ns / 1ps

// This module generates test signal data for the Beidou B1I acquisition testbench
module test_signal_gen;
    // Parameters
    parameter B1I_CODE_LENGTH = 2046;
    parameter B1I_SAMPLES_PER_CHIP = 8;
    parameter B1I_SAMPLES_PER_CODE = B1I_CODE_LENGTH * B1I_SAMPLES_PER_CHIP;
    
    // Internal variables
    reg signed [3:0] signal_buffer [0:B1I_SAMPLES_PER_CODE-1];
    real carrier_phase = 0.0;
    real code_phase = 0.0;
    real doppler_freq = 2500.0; // Hz
    real sampling_freq = 16368000.0; // Hz
    real carrier_freq = 0.0; // Base-band signal (doppler only)
    integer code_idx = 0;
    integer prn = 2; // PRN #2
    integer i, file;
    
    // Simplified B1I code generation (just for test signal generation)
    function integer get_prn_chip;
        input integer prn_number;
        input integer chip_idx;
        begin
            // This is a very simplified PRN generator for test signals only
            // A real implementation would use the correct G1/G2 polynomials
            get_prn_chip = ((chip_idx * prn_number) % 11 > 5) ? 1 : -1;
        end
    endfunction
    
    initial begin
        // Create output file
        file = $fopen("test_signal.dat", "w");
        
        if (file == 0) begin
            $display("Error: Could not open output file");
            $finish;
        end
        
        // Generate test signal
        for (i = 0; i < B1I_SAMPLES_PER_CODE; i = i + 1) begin
            // Calculate current code chip
            code_idx = $floor(code_phase) % B1I_CODE_LENGTH;
            
            // Generate sample with code + carrier + noise
            real code_value = get_prn_chip(prn, code_idx);
            real carrier_value = $cos(2.0 * 3.14159265 * carrier_phase);
            real noise = $random % 100 / 200.0; // Random noise between -0.25 and +0.25
            
            // Combine components and convert to 4-bit sample (-8 to +7)
            real combined = 3.0 * code_value * carrier_value + noise;
            integer sample = $floor(combined);
            
            // Limit to 4-bit range
            if (sample > 7) sample = 7;
            if (sample < -8) sample = -8;
            
            // Store sample
            signal_buffer[i] = sample;
            
            // Write to file
            $fdisplay(file, "%d", sample);
            
            // Update phases
            carrier_phase = carrier_phase + (carrier_freq + doppler_freq) / sampling_freq;
            if (carrier_phase >= 1.0) carrier_phase = carrier_phase - 1.0;
            
            code_phase = code_phase + 1.0 / B1I_SAMPLES_PER_CHIP;
        end
        
        $fclose(file);
        $display("Test signal generation completed");
        $finish;
    end
endmodule
