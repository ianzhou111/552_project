module five_decode(
    input [4:0] in,
    output reg [31:0] out
);

always @(*) begin
    case (in)
        5'h00: out = 32'h1;
        5'h01: out = 32'h2;
        5'h02: out = 32'h4;
        5'h03: out = 32'h8;
        5'h04: out = 32'h10;
        5'h05: out = 32'h20;
        5'h06: out = 32'h40;
        5'h07: out = 32'h80;
        5'h08: out = 32'h100;
        5'h09: out = 32'h200;
        5'h0A: out = 32'h400;
        5'h0B: out = 32'h800;
        5'h0C: out = 32'h1000;
        5'h0D: out = 32'h2000;
        5'h0E: out = 32'h4000;
        5'h0F: out = 32'h8000;
        5'h10: out = 32'h10000;
        5'h11: out = 32'h20000;
        5'h12: out = 32'h40000;
        5'h13: out = 32'h80000;
        5'h14: out = 32'h100000;
        5'h15: out = 32'h200000;
        5'h16: out = 32'h400000;
        5'h17: out = 32'h800000;
        5'h18: out = 32'h1000000;
        5'h19: out = 32'h2000000;
        5'h1A: out = 32'h4000000;
        5'h1B: out = 32'h8000000;
        5'h1C: out = 32'h10000000;
        5'h1D: out = 32'h20000000;
        5'h1E: out = 32'h40000000;
        5'h1F: out = 32'h80000000;
        default: out = 32'h0; 
    endcase 
end

endmodule 