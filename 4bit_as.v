module one_bit_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);

assign sum = a ^ b ^ cin;
assign cout = (a & b) | (a & cin) | (b & cin);

endmodule

module four_bit_adder(
    input [3:0] A,
    input [3:0] B,
    input sub,
    output [3:0] Sum,
    output Ovfl
);

wire [3:0] s;
wire c1, c2, c3,c4;
wire [3:0] b;

assign b = (sub) ? ~B : B;

one_bit_adder adder1(A[0], b[0], sub, s[0], c1);
one_bit_adder adder2(A[1], b[1], c1, s[1], c2);
one_bit_adder adder3(A[2], b[2], c2, s[2], c3);
one_bit_adder adder4(A[3], b[3], c3, s[3], c4);

assign Ovfl = (sub) ? ((A[3]&~B[3]&~s[3])|(A[3]&~B[3]&s[3])) : ((~A[3]&~B[3]&s[3])|(A[3]&B[3]&~s[3]));

assign Sum = s;


endmodule