module PSA_16bit (Sum, Error, A, B);
input [15:0] A, B; 	// Input data values
output [15:0] Sum; 	// Sum output
output Error; 	// To indicate overflows

wire [3:0] a,b,c,d,e,f,g,h;
wire [3:0] ae,bf,cg,dh;
wire e1,e2,e3,e4;

assign a = A[15:12];
assign b = A[11:8];
assign c = A[7:4];
assign d = A[3:0];

assign e = B[15:12];
assign f = B[11:8];
assign g = B[7:4];
assign h = B[3:0];

four_bit_adder uut1(
        .A(a),
        .B(e),
        .Sum(ae),
        .Ovfl(e1),
        .sub(0)
    );

    four_bit_adder uut2(
        .A(b),
        .B(f),
        .Sum(bf),
        .Ovfl(e2),
        .sub(0)
    );

    four_bit_adder uut3(
        .A(c),
        .B(g),
        .Sum(cg),
        .Ovfl(e3),
        .sub(0)
    );

    four_bit_adder uut4(
        .A(d),
        .B(h),
        .Sum(dh),
        .Ovfl(e4),
        .sub(0)
    );

assign Error = e1|e2|e3|e4;
assign Sum = {ae,bf,cg,dh};



endmodule
