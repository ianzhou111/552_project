module cpu(input clk, input rst_n, output hlt, output [15:0] pc);

wire [15:0] PC_in, PC_val;
wire [15:0] PC_inc, PC_br;
wire [15:0] Inst;
wire WriteReg;
wire [15:0] DstData;
wire [15:0] SrcData1, SrcData2;
wire [15:0] ALUOut;
wire [15:0] MemOut;
wire ALU2Mux; //0 - Reg 1 - Imm
wire addrCalc;
wire loadByteMux; //0 - Normal read into ALU 1 - Read into RegFile for byte load
wire [1:0] DstMux; //Write from - 00 - ALU; 01 - Memory; 10 - Immediate; 11 - PC
wire [1:0] BrMux; //Next PC - 00 - PC+2; 01 - PC+2+Imm; 10 - Rs
wire branch;
wire enableMem;
wire readWriteMem;
wire ZALU, ZOut, VALU, Vout, NALU, Nout;
wire Zen, Ven, Nen;

wire rst;
assign rst = ~rst_n;

/**** FETCH ****/

PC_ad inc (.Sum(PC_inc), .Ovfl(), .A(PC_val));

//assign PC_in = (&Inst[15:12]) ? PC_val : (BrMux[1] ? SrcData1 : (BrMux[0] ? PC_br : PC_inc));
assign PC_in = (BrMux[1] ? SrcData1 : (BrMux[0] ? PC_br : (&Inst[15:12])? PC_val : PC_inc));

assign BrMux = (Inst[15] & Inst[14] & ~Inst[13]) ? (branch ? (Inst[12] ? 2'b10 : 2'b01) : 2'b00) : 2'b00;

Register PC ( .clk(clk), .rst(rst), .D(PC_in), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(PC_val), .Bitline2());

memory1c IMem (.data_out(Inst), .data_in(16'b0), .addr(PC_val), .enable(1'b1), .wr(1'b0), .clk(clk), .rst(rst));

/**** DECODE ****/

wire [15:0] IF_ID_Inst, IF_ID_PC_inc;

Register IF_ID_Inst ( .clk(clk), .rst(rst), .D(Inst), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(IF_ID_Inst), .Bitline2());
Register IF_ID_PC_inc ( .clk(clk), .rst(rst), .D(PC_inc), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(IF_ID_PC_inc), .Bitline2());

br_control bcUnit (.condition(IF_ID_Inst[11:9]), .flags({ZOut, Vout, Nout}), .branch(branch)); 

control cUnit (.Opcode(IF_ID_Inst[15:12]), .WriteReg(WriteReg), .ALU2Mux(ALU2Mux), .addrCalc(addrCalc), .loadByteMux(loadByteMux), .DstMux(DstMux), .enableMem(enableMem), .readWriteMem(readWriteMem), .Zen(Zen), .Ven(Ven), .Nen(Nen));

BR_ad shift_and_add (.Sum(PC_br), .Ovfl(), .A(IF_ID_PC_inc), .B({{7{Inst[8]}}, Inst[8:0]}));

RegisterFile regFile (.clk(clk), .rst(rst), .SrcReg1(IF_ID_Inst[7:4]), .SrcReg2(loadByteMux ? IF_ID_Inst[11:8] : IF_ID_Inst[3:0]), .DstReg(IF_ID_Inst[11:8]), .WriteReg(WriteReg), .DstData(DstData), .SrcData1(SrcData1), .SrcData2(SrcData2));

wire [15:0] Operand1;
assign Operand1 = addrCalc ? (SrcData1 & 16'hFFFE) : SrcData1;

wire [15:0] Operand2;
assign Operand2 = addrCalc ? {{11{Inst[3]}}, Inst[3:0], 1'b0} : (ALU2Mux?{12'h000, Inst[3:0]}:SrcData2);

/**** EXECUTE ****/
wire [15:0] ID_EX_Operand1, ID_EX_Operand2, ID_EX_SrcData2, ID_EX_Inst, ID_EX_PC_inc;

Register ID_EX_Operand1 ( .clk(clk), .rst(rst), .D(Operand1), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_Operand1), .Bitline2());
Register ID_EX_Operand2 ( .clk(clk), .rst(rst), .D(Operand2), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_Operand2), .Bitline2());
Register ID_EX_SrcData2 ( .clk(clk), .rst(rst), .D(SrcData2), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_SrcData2), .Bitline2());
Register ID_EX_Inst ( .clk(clk), .rst(rst), .D(IF_ID_Inst), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_Inst), .Bitline2());
Register ID_EX_PC_inc ( .clk(clk), .rst(rst), .D(IF_ID_PC_inc), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_PC_inc), .Bitline2());

wire ALUInstAdd;
assign ALUInstAdd = (ID_EX_Inst[15] & ~ID_EX_Inst[14] & ~ID_EX_Inst[13]);


ALU ALU (.op(ALUInstAdd ? 3'b000 : ID_EX_Inst[14:12]), .a(ID_EX_Operand1), .b(ID_EX_Operand2), .out(ALUOut), .Z(ZALU), .V(VALU), .N(NALU));

dff Z (.q(ZOut), .d(ZALU), .wen(Zen), .clk(clk), .rst(rst));
dff V (.q(Vout), .d(VALU), .wen(Ven), .clk(clk), .rst(rst));
dff N (.q(Nout), .d(NALU), .wen(Nen), .clk(clk), .rst(rst));

/**** MEMORY ****/
wire [15:0] EX_MEM_ALUOut, EX_MEM_SrcData2, EX_MEM_Inst, EX_MEM_PC_inc;

Register EX_MEM_ALUOut ( .clk(clk), .rst(rst), .D(ALUOut), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_ALUOut), .Bitline2());
Register EX_MEM_SrcData2 ( .clk(clk), .rst(rst), .D(ID_EX_SrcData2), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_SrcData2), .Bitline2());
Register EX_MEM_Inst ( .clk(clk), .rst(rst), .D(ID_EX_Inst), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_Inst), .Bitline2());
Register EX_MEM_PC_inc ( .clk(clk), .rst(rst), .D(ID_EX_PC_inc), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_PC_inc), .Bitline2());

memory1c DMem (.data_out(MemOut), .data_in(EX_MEM_SrcData2), .addr(EX_MEM_ALUOut), .enable(enableMem), .wr(readWriteMem), .clk(clk), .rst(rst));

/**** WRITEBACK ****/
wire [15:0] MEM_WB_ALUOut, MEM_WB_MemOut, MEM_WB_SrcData2, MEM_WB_Inst, MEM_WB_PC_inc;

Register MEM_WB_ALUOut ( .clk(clk), .rst(rst), .D(EX_MEM_ALUOut), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_ALUOut), .Bitline2());
Register MEM_WB_MemOut ( .clk(clk), .rst(rst), .D(MemOut), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_MemOut), .Bitline2());
Register MEM_WB_SrcData2 ( .clk(clk), .rst(rst), .D(EX_MEM_SrcData2), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_SrcData2), .Bitline2());
Register MEM_WB_Inst ( .clk(clk), .rst(rst), .D(EX_MEM_Inst), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_Inst), .Bitline2());
Register MEM_WB_PC_inc ( .clk(clk), .rst(rst), .D(EX_MEM_PC_inc), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_PC_inc), .Bitline2());

//assign DstData = DstMux[1] ? (Inst[12] ? {Inst[7:0], SrcData2[7:0]} : {SrcData2[15:8], Inst[7:0]}) : (DstMux[0] ? MemOut : ALUOut);
assign DstData = (DstMux == 2'b00) ? MEM_WB_ALUOut :
                 (DstMux == 2'b01) ? MEM_WB_MemOut :
                 (DstMux == 2'b10) ? (MEM_WB_Inst[12] ? {MEM_WB_Inst[7:0], MEM_WB_SrcData2[7:0]} : {MEM_WB_SrcData2[15:8], MEM_WB_Inst[7:0]}) :
                                     MEM_WB_PC_inc; //DstMux == 2'b11 (or xx etc.)

assign pc = PC_val;
assign hlt = (&MEM_WB_Inst[15:12]);

endmodule