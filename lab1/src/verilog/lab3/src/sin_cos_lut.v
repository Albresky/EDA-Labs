// Sine/Cosine lookup table implementation
// This is included in generate_carrier.v

function signed [31:0] cos_lut;
    input [31:0] phase;
    reg [7:0] index;
    begin
        index = phase[31:24];
        
        case(index)
            8'd0: cos_lut = 32'h00100000;  // cos(0) = 1.0
            8'd1: cos_lut = 32'h00100000;  // cos(π/128) ≈ 1.0
            8'd64: cos_lut = 32'h00000000; // cos(π/2) = 0.0
            8'd128: cos_lut = 32'hFFF00000; // cos(π) = -1.0
            8'd192: cos_lut = 32'h00000000; // cos(3π/2) = 0.0
            8'd255: cos_lut = 32'h00100000; // cos(2π-π/128) ≈ 1.0
            default: cos_lut = 32'h00100000;
        endcase
    end
endfunction

function signed [31:0] sin_lut;
    input [31:0] phase;
    reg [7:0] index;
    begin
        index = phase[31:24];
        
        case(index)
            8'd0: sin_lut = 32'h00000000;  // sin(0) = 0.0
            8'd1: sin_lut = 32'h00000CCC;  // sin(π/128) ≈ 0.0245
            8'd64: sin_lut = 32'h00100000; // sin(π/2) = 1.0
            8'd128: sin_lut = 32'h00000000; // sin(π) = 0.0
            8'd192: sin_lut = 32'hFFF00000; // sin(3π/2) = -1.0
            8'd255: sin_lut = 32'hFFFFF334; // sin(2π-π/128) ≈ -0.0245
            default: sin_lut = 32'h00000000;
        endcase
    end
endfunction
