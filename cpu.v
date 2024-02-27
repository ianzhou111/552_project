module cpu(input clk, input rst_n, output hlt, output pc[15:0])

wire [15:0] PC_in, PC_val;
wire [15:0] PC_inc, PC_br;
wire [15:0] Inst;
wire WriteReg;
wire [15:0] DstData;
wire [15:0] SrcData1, SrcData2;
wire [15:0] ALUOut;
wire [15:0] MemOut;
wire ALU2Mux; //0 - Reg 1 - Imm
wire loadByteMux; //0 - Normal read into ALU 1 - Read into RegFile for byte load
wire [2:0] DstMux; //Write from - 00 - ALU; 01 - Memory; 10 - Immediate
wire [2:0] BrMux; //Next PC - 00 - PC+2; 01 - PC+2+Imm; 10 - Rs
wire branch;
wire enableMem;
wire readWriteMem;
wire ZALU, ZOut, VALU, Vout, NALU, Nout;

br_control bcUnit (.condition(Inst[11:9]), .flags({ZOut, Vout, Nout}), .branch(branch));

control cUnit (.Opcode(Inst[15:12]), .WriteReg(WriteReg), .ALU2Mux(ALU2Mux), .DstMux(DstMux), .enableMem(enableMem), .readWriteMem(readWriteMem));

PC_ad inc (.Sum(PC_inc), .Ovfl(), .A(PC_val));
BR_ad shift_and_add (.Sum(PC_br), .Ovfl(), .A(PC_inc), .B(Inst[8:0]));

assign PC_in = BrMux[1] ? SrcData1 : (BrMux[0] ? PC_br : PC_inc);

assign BrMux = (Inst[15] & Inst[14] & ~Inst[13]) ? (branch ? (Inst[12] ? 2'b10 : 2'b01) : 2'b00) : 2'b00;

Register PC ( .clk(clk), .rst(rst), .D(PC_in), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(PC_val), .Bitline2());

memory1c IMem (.data_out(Inst), .data_in(0), .addr(PC_val), .enable(1), .wr(0), .clk(clk), .rst(rst));

RegisterFile regFile (.clk(clk), .rst(rst), .SrcReg1(Inst[7:4]), .SrcReg2(loadByteMux ? Inst[11:8] : Inst[3:0]), .DstReg(Inst[11:8]), .WriteReg(WriteReg), .DstData(DstData), .SrcData1(SrcData1), .SrcData2(SrcData2));

ALU ALU (.op(Inst[14:12]), .a(SrcData1), .b(ALU2Mux?{12'h000, Inst[3:0]}:SrcData2), .out(ALUOut), .Z(ZALU), .V(VALU), .N(NALU));

dff Z (.q(ZOut), .d(ZALU), .wen(1'b1), .clk(clk), .rst(rst));
dff V (.q(Vout), .d(VALU), .wen(1'b1), .clk(clk), .rst(rst));
dff N (.q(Nout), .d(NALU), .wen(1'b1), .clk(clk), .rst(rst));

memory1c DMem (.data_out(MemOut), .data_in(SrcData2), .addr(ALUOut), .enable(enableMem), .wr(readWriteMem), .clk(clk), .rst(rst));

assign DstData = DstMux[1] ? (Inst[12] ? {Inst[7:0], SrcData2[7:0]} : {SrcData2[15:8], Inst[7:0]}) : (DstMux[0] ? MemOut : ALUOut); 

endmodule