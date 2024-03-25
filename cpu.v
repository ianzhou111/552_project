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
wire DstMux; //Write from - 0 - X stage result; 1 - Memory
wire [1:0] BrMux; //Next PC - 00 - PC+2; 01 - PC+2+Imm; 10 - Rs
wire branch;
wire enableMem;
wire readWriteMem;
wire ZALU, ZOut, VALU, Vout, NALU, Nout;
wire Zen, Ven, Nen;
wire stall;


wire [15:0] IF_ID_Inst, IF_ID_PC_inc; /*** DECODE ***/
wire MEM_WB_WriteReg; /*** WRITEBACK ***/

wire rst;
assign rst = ~rst_n;

/**** FETCH ****/

PC_ad inc (.Sum(PC_inc), .Ovfl(), .A(PC_val));

//assign PC_in = (&Inst[15:12]) ? PC_val : (BrMux[1] ? SrcData1 : (BrMux[0] ? PC_br : PC_inc));
assign PC_in = (BrMux[1] ? SrcData1 : (BrMux[0] ? PC_br : (&Inst[15:12])? PC_val : PC_inc));

assign BrMux = (IF_ID_Inst[15] & IF_ID_Inst[14] & ~IF_ID_Inst[13]) ? (branch ? (IF_ID_Inst[12] ? 2'b10 : 2'b01) : 2'b00) : 2'b00;

Register PC ( .clk(clk), .rst(rst|branch), .D(PC_in), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(PC_val), .Bitline2());

memory1c IMem (.data_out(Inst), .data_in(16'b0), .addr(PC_val), .enable(1'b1), .wr(1'b0), .clk(clk), .rst(rst));

/**** DECODE ****/

Register IF_ID_InstR ( .clk(clk), .rst(rst | branch), .D(Inst), .WriteReg(~stall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(IF_ID_Inst), .Bitline2());
Register IF_ID_PC_incR ( .clk(clk), .rst(rst | branch), .D(PC_inc), .WriteReg(~stall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(IF_ID_PC_inc), .Bitline2());

br_control bcUnit (.condition(IF_ID_Inst[11:9]), .flags({ZOut, Vout, Nout}), .branch(branch)); 

control cUnit (.Opcode(IF_ID_Inst[15:12]), .WriteReg(WriteReg), .ALU2Mux(ALU2Mux), .addrCalc(addrCalc), .loadByteMux(loadByteMux), .DstMux(DstMux), .enableMem(enableMem), .readWriteMem(readWriteMem), .Zen(Zen), .Ven(Ven), .Nen(Nen));

BR_ad shift_and_add (.Sum(PC_br), .Ovfl(), .A(IF_ID_PC_inc), .B({{7{Inst[8]}}, Inst[8:0]}));

RegisterFile regFile (.clk(clk), .rst(rst), .SrcReg1(IF_ID_Inst[7:4]), .SrcReg2(loadByteMux ? IF_ID_Inst[11:8] : IF_ID_Inst[3:0]), .DstReg(IF_ID_Inst[11:8]), .WriteReg(MEM_WB_WriteReg), .DstData(DstData), .SrcData1(SrcData1), .SrcData2(SrcData2));

//1st line is scenario of both rt and rs 
assign stall = ((IF_ID_Inst[15:12]==4'b1000)&&(Inst[15:14]==2'b00|Inst[15:12]==4'b0111)&&(IF_ID_Inst[11:8]==Inst[7:4]|IF_ID_Inst[11:8]==Inst[3:0])) ? 1:
                ((~Inst[15]|Inst[15]&~Inst[13]&Inst[12])&&IF_ID_Inst[11:8]==Inst[7:4]) ? 1:
                0;

/**** EXECUTE ****/
wire ID_EX_WriteReg , ID_EX_enableMem, ID_EX_readWriteMem, ID_EX_Zen, ID_EX_Ven, ID_EX_Nen, ID_EX_DstMux, ID_EX_addrCalc, ID_EX_ALU2Mux;

dff ID_EX_WriteRegR (.q(ID_EX_WriteReg), .d(WriteReg), .wen(1'b1), .clk(clk), .rst(rst|stall));
dff ID_EX_enableMemR (.q(ID_EX_enableMem), .d(enableMem), .wen(1'b1), .clk(clk), .rst(rst|stall));
dff ID_EX_readWriteMemR (.q(ID_EX_readWriteMem), .d(readWriteMem), .wen(1'b1), .clk(clk), .rst(rst|stall));
dff ID_EX_ZenR (.q(ID_EX_Zen), .d(Zen), .wen(1'b1), .clk(clk), .rst(rst|stall));
dff ID_EX_VenR (.q(ID_EX_Ven), .d(Ven), .wen(1'b1), .clk(clk), .rst(rst|stall));
dff ID_EX_NenR (.q(ID_EX_Nen), .d(Nen), .wen(1'b1), .clk(clk), .rst(rst|stall));
dff ID_EX_DstMuxR (.q(ID_EX_DstMux), .d(DstMux), .wen(1'b1), .clk(clk), .rst(rst|stall));
dff ID_EX_addrCalcR (.q(ID_EX_addrCalc), .d(addrCalc), .wen(1'b1), .clk(clk), .rst(rst|stall));
dff ID_EX_ALU2MuxR (.q(ID_EX_ALU2Mux), .d(ALU2Mux), .wen(1'b1), .clk(clk), .rst(rst|stall));

wire [15:0] ID_EX_SrcData1, ID_EX_SrcData2, ID_EX_Inst, ID_EX_PC_inc;

Register ID_EX_SrcData1R ( .clk(clk), .rst(rst|stall), .D(SrcData1), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_SrcData1), .Bitline2());
Register ID_EX_SrcData2R ( .clk(clk), .rst(rst|stall), .D(SrcData2), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_SrcData2), .Bitline2());
Register ID_EX_InstR ( .clk(clk), .rst(rst|stall), .D(IF_ID_Inst), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_Inst), .Bitline2());
Register ID_EX_PC_incR ( .clk(clk), .rst(rst|stall), .D(IF_ID_PC_inc), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_PC_inc), .Bitline2());

wire ALUInstAdd;
assign ALUInstAdd = (ID_EX_Inst[15] & ~ID_EX_Inst[14] & ~ID_EX_Inst[13]);

assign FwdOp1MX = (MEM_WB_Rd == ID_EX_Rs);
assign FwdOp2MX = (MEM_WB_Rd == ID_EX_Rt);

assign FwdOp1XX = (EX_MEM_Rd == ID_EX_Rs);
assign FwdOp2XX = (EX_MEM_Rd == ID_EX_Rt);

wire [15:0] Rs;
assign Rs = FwOp1XX ? EX_MEM_Result : (FwOp1MX ? DstData : ID_EX_SrcData1);

wire [15:0] Rt;
assign Rt = FwOp1XX ? EX_MEM_Result : (FwOp1MX ? DstData : ID_EX_SrcData2);

wire [15:0] Operand1;
assign Operand1 = ID_EX_addrCalc ? (Rs & 16'hFFFE) : Rs;

wire [15:0] Operand2;
assign Operand2 = ID_EX_addrCalc ? {{11{ID_EX_Inst[3]}}, ID_EX_Inst[3:0], 1'b0} : (ID_EX_ALU2Mux?{12'h000, Inst[3:0]}:Rt);


ALU ALU (.op(ALUInstAdd ? 3'b000 : ID_EX_Inst[14:12]), .a(Operand1), .b(Operand2), .out(ALUOut), .Z(ZALU), .V(VALU), .N(NALU));


wire loadImmediate;
assign loadImmediate = (ID_EX_Inst[15] & ~ID_EX_Inst[14] & ID_EX_Inst[13]);
wire loadPC;
assign loadPC = (ID_EX_Inst[15] & ID_EX_Inst[14] & ID_EX_Inst[13] & ~ID_EX_Inst[12]);
wire [15:0] Result;
assign Result = loadImmediate ? (ID_EX_Inst[12] ? {ID_EX_Inst[7:0], ID_EX_SrcData2[7:0]} : {ID_EX_SrcData2[15:8], ID_EX_Inst[7:0]}) : 
                loadPC ?        ID_EX_PC_inc :
                                ALUOut;

dff Z (.q(ZOut), .d(ZALU), .wen(ID_EX_Zen), .clk(clk), .rst(rst));
dff V (.q(Vout), .d(VALU), .wen(ID_EX_Ven), .clk(clk), .rst(rst));
dff N (.q(Nout), .d(NALU), .wen(ID_EX_Nen), .clk(clk), .rst(rst));

/**** MEMORY ****/
wire EX_MEM_WriteReg, EX_MEM_enableMem, EX_MEM_readWriteMem, EX_MEM_DstMux;

dff EX_MEM_WriteRegR (.q(EX_MEM_WriteReg), .d(ID_EX_WriteReg), .wen(1'b1), .clk(clk), .rst(rst));
dff EX_MEM_enableMemR (.q(EX_MEM_enableMem), .d(ID_EX_enableMem), .wen(1'b1), .clk(clk), .rst(rst));
dff EX_MEM_readWriteMemR (.q(EX_MEM_readWriteMem), .d(ID_EX_readWriteMem), .wen(1'b1), .clk(clk), .rst(rst));
dff EX_MEM_DstMuxR (.q(EX_MEM_DstMux), .d(ID_EX_DstMux), .wen(1'b1), .clk(clk), .rst(rst));

wire [15:0] EX_MEM_Result, EX_MEM_SrcData2, EX_MEM_Inst;

Register EX_MEM_ResultR ( .clk(clk), .rst(rst), .D(Result), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_Result), .Bitline2());
Register EX_MEM_SrcData2R ( .clk(clk), .rst(rst), .D(ID_EX_SrcData2), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_SrcData2), .Bitline2());
Register EX_MEM_InstR ( .clk(clk), .rst(rst), .D(ID_EX_Inst), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_Inst), .Bitline2());

memory1c DMem (.data_out(MemOut), .data_in(EX_MEM_SrcData2), .addr(EX_MEM_ALUOut), .enable(EX_MEM_enableMem), .wr(EX_MEM_readWriteMem), .clk(clk), .rst(rst));

/**** WRITEBACK ****/

wire MEM_WB_DstMux;

dff MEM_WB_WriteRegR (.q(MEM_WB_WriteReg), .d(EX_MEM_WriteReg), .wen(1'b1), .clk(clk), .rst(rst));
dff MEM_WB_DstMuxR (.q(MEM_WB_DstMux), .d(EX_MEM_DstMux), .wen(1'b1), .clk(clk), .rst(rst));

wire [15:0] MEM_WB_Result, MEM_WB_MemOut, MEM_WB_Inst;

Register MEM_WB_ResultR ( .clk(clk), .rst(rst), .D(EX_MEM_Result), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_Result), .Bitline2());
Register MEM_WB_MemOutR ( .clk(clk), .rst(rst), .D(MemOut), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_MemOut), .Bitline2());
Register MEM_WB_InstR ( .clk(clk), .rst(rst), .D(EX_MEM_Inst), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_Inst), .Bitline2());

//assign DstData = DstMux[1] ? (Inst[12] ? {Inst[7:0], SrcData2[7:0]} : {SrcData2[15:8], Inst[7:0]}) : (DstMux[0] ? MemOut : ALUOut);
assign DstData = (MEM_WB_DstMux) ? MEM_WB_Result : MEM_WB_MemOut ; //DstMux == 2'b11 (or xx etc.)

assign pc = PC_val;
assign hlt = (&MEM_WB_Inst[15:12]);

endmodule