module ALU(
    input [3:0] ALU_In1, ALU_In2,
    input [1:0] Opcode,
    output [3:0] ALU_Out,
    output Error 
); 

    //OPCODE key 
    // 00 = add 01 = sub 10 = NAND 11 = XOR 
    //the 4 bit add and subtractor 
    wire [3:0]sum;
    four_bit_adder uut(
        .A(ALU_In1),
        .B(ALU_In2),
        .Sum(sum),
        .Ovfl(Error),
        .sub(Opcode[0])
    );

    wire [3:0] nand_v; 
    assign nand_v = ~(ALU_In1&ALU_In2);
    wire [3:0] xor_v;
    assign xor_v = ALU_In1 ^ ALU_In2;

    assign ALU_Out = (Opcode[1] == 0) ? sum:
                     (Opcode == 2'b10) ? nand_v:
                     (Opcode == 2'b11) ? xor_v:
                     sum; // default to catch X and Z 




endmodule 