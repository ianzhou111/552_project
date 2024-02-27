module CLA_4bit (
    input [3:0]a,
    input [3:0]b,
    input cin,
    output [3:0]sum,
    output cout
);

wire [3:0] p,g,c;

assign p=a^b;//propagate carry out 
assign g=a&b; //generate carry out 

assign c[0]=cin;
assign c[1]= g[0]|(p[0]&c[0]);
assign c[2]= g[1]|(p[1]&g[0])|p[1]&p[0]&c[0];
assign c[3]= g[2]|(p[2]&g[1])|p[2]&p[1]&g[0]|p[2]&p[1]&p[0]&c[0];
assign cout= g[3]|(p[3]&g[2])|p[3]&p[2]&g[1]|p[3]&p[2]&p[1]&g[0]|p[3]&p[2]&p[1]&p[0]&c[0];
assign sum=a^b^c;

endmodule 


module ALU(
    input [15:0]a,
    input [15:0]b,
    input [2:0] op,
    output reg [15:0]out,
    output reg Z,
    output reg V,
    output reg N
);


reg c1,c2,c3,c4;
reg cin1,cin2,cin3;
reg [3:0] a1,a2,a3,a4;
reg [3:0] b1,b2,b3,b4;
wire [15:0]sum;
reg sub,V;


reg [15:0] Shift_In; 	// This is the input data to perform shift operation on
reg [3:0] Shift_Val; 	// Shift amount (used to shift the input data)
reg  [1:0] Mode; 		// 00 Shift left, 01 is shift right, 10 is rotate right 
reg [15:0] Shift_Out; 	// Shifted output data

reg [11:0] red1,red2;
wire [15:0] reds;
wire red1c,red2c,red3c;
wire [15:0]Bin;

assign Bin = sub ? ~b : b;
always @* casex(op)
3'b000: begin 
        {a4,a3,a2,a1} = a;
        {b4,b3,b2,b1} = b;
        cin1 = c1;
        cin2 = c2;
        cin3 = c3;
        out = sum;
        V = (a[15]^Bin[15]) ? 0 : (a[15] ^ sum[15]);
        Z = ~(|out);
        N = out[15];
        end 
3'b001: begin 
        {a4,a3,a2,a1} = a;
        {b4,b3,b2,b1} = b;
        cin1 = c1;
        cin2 = c2;
        cin3 = c3;
        sub = 1;
        out = sum;
        V = (a[15]^Bin[15]) ? 0 : (a[15] ^ sum[15]);
        Z = ~(|out);
        N = out[15];
        end 
3'b011: begin 
        {a4,a3,a2,a1} = a;
        {b4,b3,b2,b1} = b;
        cin1 = c1;
        cin2 = 0;
        cin3 = c3;
        red1 = {{4{c2}},sum[7:0]};
        red2 = {{4{c4}},sum[15:8]};
        out = {{4{reds[11]}},reds};
        V = 0;
        Z = ~(|out);
        end 
3'b111: begin 
        {a4,a3,a2,a1} = a;
        {b4,b3,b2,b1} = b;
        cin1=0;
        cin2=0;
        cin3=0;
        V=0;
        out = sum;
        Z = ~(|out);
        end 
3'b010: begin 
        out = a^b;
        V = 0;
        Z = ~(|out);
        end 
3'b1xx: begin 
        out = Shift_Out;
        Shift_In = a;
        Shift_Val = b[3:0];
        Mode = op[1:0];
        Z = ~(|out);
        end 


endcase





CLA_4bit cla1 (.a(a1), .b(b1), .cin(sub), .sum(sum[3:0]), .cout(c1));
CLA_4bit cla2 (.a(a2), .b(b2), .cin(cin1), .sum(sum[7:4]), .cout(c2));
CLA_4bit cla3 (.a(a3), .b(b3), .cin(cin2), .sum(sum[11:8]), .cout(c3));
CLA_4bit cla4 (.a(a4), .b(b4), .cin(cin3), .sum(sum[15:12]), .cout(c4));

CLA_4bit cla5 (.a(red1[3:0]), .b(red2[3:0]), .cin(1'b0), .sum(reds[3:0]), .cout(red1c));
CLA_4bit cla6 (.a(red1[7:4]), .b(red2[7:4]), .cin(red1c), .sum(reds[7:4]), .cout(red2c));
CLA_4bit cla7 (.a(red1[11:8]), .b(red2[11:8]), .cin(red2c), .sum(reds[11:8]), .cout(red3c));

assign reds[15:12] = {4{reds[11]}};


Shifter shft(.Shift_Out(Shift_Out), .Shift_In(Shift_In), .Shift_Val(Shift_Val), .Mode(Mode));

//overflow saturation for add and sub 
assign out = (~op[2]&~op[1]&V) ? (sum[15]?16'h7fff:16'h8000)
            : sum;


endmodule
