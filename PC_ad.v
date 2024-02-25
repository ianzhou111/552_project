module full_adder_1bit (in1, in2, cin, out, cout);
input in1;
input in2;
input cin;
output out;
output cout;

wire sum;

assign sum = in1 ^ in2;
assign out = sum ^ cin;
assign cout = (in1 & in2) | (sum & cin);
endmodule


module add_4 (Sum, Ovfl, A);
input [15:0] A; //Input values
output [15:0] Sum; //sum output
output Ovfl; //To indicate overflow

wire [15:0] cout;
parameter  B = 16'h0002;


full_adder_1bit FA[15:0] (.in1(A), .in2(B), .cin({cout[14:0],1'b0}), .out(Sum), .cout(cout));

assign Ovfl = (A[15] ^ B[15]) ? 0 : (A[15] ^ Sum[15]);

endmodule

