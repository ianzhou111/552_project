module six_decode(
    input [5:0] in,
    output reg [63:0] out
);

always @(*) begin
    case (in)
        6'h00: out = 64'h1;
        6'h01: out = 64'h2;
        6'h02: out = 64'h4;
        6'h03: out = 64'h8;
        6'h04: out = 64'h10;
        6'h05: out = 64'h20;
        6'h06: out = 64'h40;
        6'h07: out = 64'h80;
        6'h08: out = 64'h100;
        6'h09: out = 64'h200;
        6'h0A: out = 64'h400;
        6'h0B: out = 64'h800;
        6'h0C: out = 64'h1000;
        6'h0D: out = 64'h2000;
        6'h0E: out = 64'h4000;
        6'h0F: out = 64'h8000;
        6'h10: out = 64'h10000;
        6'h11: out = 64'h20000;
        6'h12: out = 64'h40000;
        6'h13: out = 64'h80000;
        6'h14: out = 64'h100000;
        6'h15: out = 64'h200000;
        6'h16: out = 64'h400000;
        6'h17: out = 64'h800000;
        6'h18: out = 64'h1000000;
        6'h19: out = 64'h2000000;
        6'h1A: out = 64'h4000000;
        6'h1B: out = 64'h8000000;
        6'h1C: out = 64'h10000000;
        6'h1D: out = 64'h20000000;
        6'h1E: out = 64'h40000000;
        6'h1F: out = 64'h80000000;
        6'h20: out = 64'h100000000;
        6'h21: out = 64'h200000000;
        6'h22: out = 64'h400000000;
        6'h23: out = 64'h800000000;
        6'h24: out = 64'h1000000000;
        6'h25: out = 64'h2000000000;
        6'h26: out = 64'h4000000000;
        6'h27: out = 64'h8000000000;
        6'h28: out = 64'h10000000000;
        6'h29: out = 64'h20000000000;
        6'h2A: out = 64'h40000000000;
        6'h2B: out = 64'h80000000000;
        6'h2C: out = 64'h100000000000;
        6'h2D: out = 64'h200000000000;
        6'h2E: out = 64'h400000000000;
        6'h2F: out = 64'h800000000000;
        6'h30: out = 64'h1000000000000;
        6'h31: out = 64'h2000000000000;
        6'h32: out = 64'h4000000000000;
        6'h33: out = 64'h8000000000000;
        6'h34: out = 64'h10000000000000;
        6'h35: out = 64'h20000000000000;
        6'h36: out = 64'h40000000000000;
        6'h37: out = 64'h80000000000000;
        6'h38: out = 64'h100000000000000;
        6'h39: out = 64'h200000000000000;
        6'h3A: out = 64'h400000000000000;
        6'h3B: out = 64'h800000000000000;
        6'h3C: out = 64'h1000000000000000;
        6'h3D: out = 64'h2000000000000000;
        6'h3E: out = 64'h4000000000000000;
        6'h3F: out = 64'h8000000000000000;
        default: out = 64'h0; 
    endcase 
end

endmodule 