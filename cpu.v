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
wire branchValid;
wire branch;
wire enableMem;
wire readWriteMem;
wire ZALU, ZOut, VALU, Vout, NALU, Nout;
wire Zen, Ven, Nen;
wire stall,tstall,count;
wire fsm_busy, cstall;
wire Ifsm_busy, Icstall;
wire miss_detected;
wire memory_data_valid;
wire [15:0] mainMemOut;
wire [15:0] IcurrBlockAdd;

wire [15:0] IF_ID_Inst, IF_ID_PC_inc; /*** DECODE ***/
wire MEM_WB_WriteReg; wire [15:0] MEM_WB_Result, MEM_WB_MemOut, MEM_WB_Inst; /*** WRITEBACK ***/
wire [15:0] ID_EX_SrcData1, ID_EX_SrcData2, ID_EX_Inst, ID_EX_PC_inc; /*** EXECUTE ***/
wire EX_MEM_WriteReg, EX_MEM_enableMem, EX_MEM_readWriteMem, EX_MEM_DstMux; wire [15:0] EX_MEM_Result, EX_MEM_SrcData2, EX_MEM_Inst; /*** MEMORY ***/


wire rst;
assign rst = ~rst_n;

/**** FETCH ****/

PC_ad inc (.Sum(PC_inc), .Ovfl(), .A(PC_val));

//assign PC_in = (&Inst[15:12]) ? PC_val : (BrMux[1] ? SrcData1 : (BrMux[0] ? PC_br : PC_inc));
assign PC_in = (BrMux[1] ? SrcData1 : (BrMux[0] ? PC_br : (&Inst[15:12])? PC_val : PC_inc));

assign BrMux = (IF_ID_Inst[15] & IF_ID_Inst[14] & ~IF_ID_Inst[13]) ? (branchValid ? (IF_ID_Inst[12] ? 2'b10 : 2'b01) : 2'b00) : 2'b00;

Register PC ( .clk(clk), .rst(rst), .D(PC_in), .WriteReg(~stall & ~cstall & ~Icstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(PC_val), .Bitline2());


//memory1c IMem (.data_out(Inst), .data_in(16'b0), .addr(PC_val), .enable(1'b1), .wr(1'b0), .clk(clk), .rst(rst));
wire [9:0] IInMeta1, IInMeta2, IInMeta3, IInMeta4, IWay1Out, IWay2Out,IWay3Out, IWay4Out;
wire IWriteWay1, IWriteWay2,IWriteWay3, IWriteWay4;
wire [31:0] IBlockEn;
wire [7:0] IPCWordEn;
wire [7:0] IMainWordEn;
wire Iwrite_data_array, Iwrite_tag_array;
//six_decode ISD (.in(PC_val[9:4]), .out(IBlockEn));
five_decode ISDfive (.in(PC_val[8:4]), .out(IBlockEn));

three_decode ITD1 (.in(PC_val[3:1]), .out(IPCWordEn));
three_decode ITD2 (.in(IcurrBlockAdd[3:1]), .out(IMainWordEn));

wire IvalidWay1, IvalidWay2, IvalidWay3, IvalidWay4;
wire [1:0] ILRUWay1, ILRUWay2, ILRUWay3, ILRUWay4;
dff IvalidWay1R (.q(IvalidWay1), .d(IWay1Out[2]), .wen(1'b1), .clk(clk), .rst(rst));
dff IvalidWay2R(.q(IvalidWay2), .d(IWay2Out[2]), .wen(1'b1), .clk(clk), .rst(rst));
dff IvalidWay3R(.q(IvalidWay3), .d(IWay3Out[2]), .wen(1'b1), .clk(clk), .rst(rst));
dff IvalidWay4R(.q(IvalidWay4), .d(IWay4Out[2]), .wen(1'b1), .clk(clk), .rst(rst));

dff ILRUWay1R [1:0] (.q(ILRUWay1), .d(IWay1Out[1:0]), .wen(1'b1), .clk(clk), .rst(rst));
dff ILRUWay2R [1:0] (.q(ILRUWay2), .d(IWay1Out[1:0]), .wen(1'b1), .clk(clk), .rst(rst));
dff ILRUWay3R [1:0] (.q(ILRUWay3), .d(IWay1Out[1:0]), .wen(1'b1), .clk(clk), .rst(rst));
dff ILRUWay4R [1:0] (.q(ILRUWay4), .d(IWay1Out[1:0]), .wen(1'b1), .clk(clk), .rst(rst));
wire all_valid;
assign all_valid = IvalidWay1 & IvalidWay2 & IvalidWay3 & IvalidWay4;

//assign to first way always when it is invalid or when its LRU bits is 11
assign IWriteWay1 = (Iwrite_tag_array) & (~IvalidWay1 | (all_valid & (&ILRUWay1))); 
assign IWriteWay2 = (Iwrite_tag_array) & (~IvalidWay2&IvalidWay1 | (all_valid & (&ILRUWay2))); 
assign IWriteWay3 = (Iwrite_tag_array) & (~IvalidWay3&IvalidWay1&IvalidWay2 | (all_valid & (&ILRUWay3))); 
assign IWriteWay4 = (Iwrite_tag_array) & (~IvalidWay4&IvalidWay1&IvalidWay2&IvalidWay3 (all_valid & (&ILRUWay4))); 

// assign IWriteWay1 = (Iwrite_tag_array) & (~IvalidWay1 | (IvalidWay1 & ILRUWay1 & IvalidWay2));
// assign IWriteWay2 = (Iwrite_tag_array) & ~IWriteWay1;

wire [6:0] Itagv1, Itagv2, Itagv3, Itagv4;
dff Itagv1R [6:0] (.q(Itagv1), .d(IWay1Out[9:3]), .wen(1'b1), .clk(clk), .rst(rst));
dff Itagv2R [6:0] (.q(Itagv2), .d(IWay2Out[9:3]), .wen(1'b1), .clk(clk), .rst(rst));
dff Itagv3R [6:0] (.q(Itagv3), .d(IWay3Out[9:3]), .wen(1'b1), .clk(clk), .rst(rst));
dff Itagv4R [6:0] (.q(Itagv4), .d(IWay4Out[9:3]), .wen(1'b1), .clk(clk), .rst(rst));

wire[1:0]next_stored = (all_valid&IWriteWay1) ? IWay1Out[1:0]:
                    (all_valid&IWriteWay2) ? IWay2Out[1:0]:
                    (all_valid&IWriteWay3) ? IWay3Out[1:0]:
                    (all_valid&IWriteWay4) ? IWay4Out[1:0]:
                    z;

wire[1:0] way1LRU,way2LRU,way3LRU,way4LRU;
assign way1LRU = (IWay1Out[1:0]>=next_stored) ? IWay1Out[1:0]+1:
                 IWay1Out[1:0];
assign way2LRU = (IWay2Out[1:0]>=next_stored) ? IWay2Out[1:0]+1:
                 IWay2Out[1:0];
assign way3LRU = (IWay3Out[1:0]>=next_stored) ? IWay3Out[1:0]+1:
                 IWay3Out[1:0];
assign way4LRU = (IWay4Out[1:0]>=next_stored) ? IWay4Out[1:0]+1:
                 IWay4Out[1:0];



assign IInMeta1 = IWriteWay1 ? {PC_val[15:9], 3'b100} : {Itagv1, way1LRU};
assign IInMeta2 = IWriteWay2 ? {PC_val[15:9], 3'b100} : {Itagv2, way2LRU};
assign IInMeta3 = IWriteWay3 ? {PC_val[15:9], 3'b100} : {Itagv3, way3LRU};
assign IInMeta4 = IWriteWay4 ? {PC_val[15:9], 3'b100} : {Itagv4, way4LRU};


// assign IInMeta1 = IWriteWay1 ? {PC_val[15:10], 2'b10} : {Itagv1, 1'b1};
// assign IInMeta2 = IWriteWay2 ? {PC_val[15:10], 2'b10} : {Itagv2, 1'b1};

MetaDataArray IMeta1 (.clk(clk), .rst(rst), .DataIn(IInMeta1), .Write(Iwrite_tag_array), .BlockEnable(IBlockEn), .DataOut(IWay1Out));
MetaDataArray IMeta2 (.clk(clk), .rst(rst), .DataIn(IInMeta2), .Write(Iwrite_tag_array), .BlockEnable(IBlockEn), .DataOut(IWay2Out));
MetaDataArray IMeta3 (.clk(clk), .rst(rst), .DataIn(IInMeta3), .Write(Iwrite_tag_array), .BlockEnable(IBlockEn), .DataOut(IWay3Out));
MetaDataArray IMeta4 (.clk(clk), .rst(rst), .DataIn(IInMeta4), .Write(Iwrite_tag_array), .BlockEnable(IBlockEn), .DataOut(IWay4Out));
//change till here
wire Imiss_detected, Imiss_detected1, Imiss_detected2;
wire IWay1TagMatch, IWay2TagMatch;
wire sameCycleMiss;
assign sameCycleMiss = Imiss_detected & miss_detected;
assign Icstall = Ifsm_busy | Imiss_detected | sameCycleMiss;
assign Imiss_detected1 = (~IWay1TagMatch & ~IWay2TagMatch & ~IWay3TagMatch & ~IWay4TagMatch);
dff ImissEdge (.q(Imiss_detected2), .d(Imiss_detected1), .wen(1'b1), .clk(clk), .rst(rst));
assign Imiss_detected = Imiss_detected1 & ~Imiss_detected2;

//Metadata Bits[7:2] are tag; Bit[1] is valid bit; Bit[0] is LRU bit :(
assign IWay1TagMatch = (PC_val[15:9] == IWay1Out[9:3]) & IWay1Out[2] & ~Iwrite_tag_array;
assign IWay2TagMatch = (PC_val[15:9] == IWay2Out[9:3]) & IWay2Out[2] & ~Iwrite_tag_array;
assign IWay3TagMatch = (PC_val[15:9] == IWay3Out[9:3]) & IWay3Out[2] & ~Iwrite_tag_array;
assign IWay4TagMatch = (PC_val[15:9] == IWay4Out[9:3]) & IWay4Out[2] & ~Iwrite_tag_array;

wire [1:0]Iway, ImatchWay;
assign ImatchWay = (IWay1TagMatch) ? 2'b00:
                    (IWay2TagMatch)? 2'b01:
                    (IWay3TagMatch)? 2'b10:
                    2'b11;

//assign Iway = Ifsm_busy ? ~(~IvalidWay1 | (IvalidWay1 & ILRUWay1 & IvalidWay2)): ImatchWay;//question
assign Iway = ImatchWay;
wire [7:0] ICacheWord;
wire [127:0] ICBlockEn;
wire [15:0] ICacheIn;
seven_decode ISeD (.in({PC_val[8:4], Iway}), .out(ICBlockEn));
assign ICacheWrite = Iwrite_data_array;
assign ICacheWord = Ifsm_busy ? IMainWordEn : IPCWordEn;
assign ICacheIn = mainMemOut;

wire [127:0] ICBlockEnDel;
dff ICBlockEnDelR [127:0] (.q(ICBlockEnDel), .d(ICBlockEn), .wen(1'b1), .clk(clk), .rst(rst));
wire ICacheWriteDel;
dff ICacheWriteDelR (.q(ICacheWriteDel), .d(ICacheWrite), .wen(1'b1), .clk(clk), .rst(rst));
wire [7:0] ICacheWordDel;
dff ICacheWordDelR [7:0] (.q(ICacheWordDel), .d(ICacheWord), .wen(1'b1), .clk(clk), .rst(rst));

DataArray ICache (.clk(clk), .rst(rst), .DataIn(ICacheIn), .Write(Ifsm_busy? ICacheWriteDel: ICacheWrite), .BlockEnable(Ifsm_busy ? ICBlockEnDel : ICBlockEn), .WordEnable(Ifsm_busy ? ICacheWordDel: ICacheWord), .DataOut(Inst));

cache_fill_FSM IcacheFSM(.clk(clk), .rst_n(rst_n), .miss_detected(Imiss_detected), .miss_address(PC_val), .fsm_busy(Ifsm_busy), .write_data_array(Iwrite_data_array),
.write_tag_array(Iwrite_tag_array), .memory_address(IcurrBlockAdd), .memory_data_valid(memory_data_valid), .memBusy(sameCycleMiss));

/**** DECODE ****/

Register IF_ID_InstR ( .clk(clk), .rst(rst | (branch & ~stall) | Icstall), .D(Inst), .WriteReg(~stall & ~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(IF_ID_Inst), .Bitline2());
Register IF_ID_PC_incR ( .clk(clk), .rst(rst | (branch & ~stall) | Icstall), .D(PC_inc), .WriteReg(~stall & ~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(IF_ID_PC_inc), .Bitline2());

br_control bcUnit (.condition(IF_ID_Inst[11:9]), .flags({ZOut, Vout, Nout}), .branch(branchValid));
assign branch = BrMux[1] | BrMux[0];

control cUnit (.Opcode(IF_ID_Inst[15:12]), .WriteReg(WriteReg), .ALU2Mux(ALU2Mux), .addrCalc(addrCalc), .loadByteMux(loadByteMux), .DstMux(DstMux), .enableMem(enableMem), .readWriteMem(readWriteMem), .Zen(Zen), .Ven(Ven), .Nen(Nen));

BR_ad shift_and_add (.Sum(PC_br), .Ovfl(), .A(IF_ID_PC_inc), .B({{7{IF_ID_Inst[8]}}, IF_ID_Inst[8:0]}));

RegisterFile regFile (.clk(clk), .rst(rst), .SrcReg1(IF_ID_Inst[7:4]), .SrcReg2(loadByteMux ? IF_ID_Inst[11:8] : IF_ID_Inst[3:0]), .DstReg(MEM_WB_Inst[11:8]), .WriteReg(MEM_WB_WriteReg), .DstData(DstData), .SrcData1(SrcData1), .SrcData2(SrcData2));

assign tstall = (ID_EX_Inst[15:12]==4'b1000)&&(IF_ID_Inst[15:12]==4'b1101)&&(ID_EX_Inst[11:8]==IF_ID_Inst[7:4])? 1://double stall
                0;
                //add tstall for load to save
//1st line is scenario of both rt and rs 
assign stall = ((ID_EX_Inst[15:12]==4'b1000)&&(IF_ID_Inst[15:14]==2'b00|IF_ID_Inst[15:12]==4'b0111)&&(ID_EX_Inst[11:8]==IF_ID_Inst[7:4]|ID_EX_Inst[11:8]==IF_ID_Inst[3:0])) ? 1: // load to use for normal arithmetic instruction
                //((ID_EX_Inst[15:12]==4'b1000)&&(~IF_ID_Inst[15]|ID_EX_Inst[15:12]==4'b1001)&&ID_EX_Inst[11:8]==IF_ID_Inst[7:4]) ? 1: // load to use for instructions with immediate operands
                ((ID_EX_Inst[15:12]==4'b1000)&&(~IF_ID_Inst[15])&&ID_EX_Inst[11:8]==IF_ID_Inst[7:4]) ? 1: // load to use for instructions with immediate operands
                //((EX_MEM_Inst[15:12]==4'b1000)&&(IF_ID_Inst[15:12]==4'b1001)&&ID_EX_Inst[11:8]==IF_ID_Inst[7:4])? 1://branch with 1 cycle apart
                ((EX_MEM_Inst[15:12]==4'b1000)&&(IF_ID_Inst[15:12]==4'b1001)&&EX_MEM_Inst[11:8]==IF_ID_Inst[11:8])? 1://load to save with one cycle in between
                ((ID_EX_Inst[15:12]==4'b0000 || ID_EX_Inst[15:12]==4'b0001 || ID_EX_Inst[15:12]==4'b0010 || ID_EX_Inst[15:12]==4'b0100 || ID_EX_Inst[15:12]==4'b0101 || ID_EX_Inst[15:12]==4'b0110)&&(ID_EX_Inst!=16'h0000)&&(IF_ID_Inst[15:12]==4'b1100 || IF_ID_Inst[15:12]==4'b1101))? 1://stall branch to let flag registers update
                tstall|count ? 1://stall 2 cycles for L followed immediately by BR
                0;

dff onebcount (.q(count), .d(tstall), .wen(1'b1), .clk(clk), .rst(rst));

/**** EXECUTE ****/
wire ID_EX_WriteReg , ID_EX_enableMem, ID_EX_readWriteMem, ID_EX_Zen, ID_EX_Ven, ID_EX_Nen, ID_EX_DstMux, ID_EX_addrCalc, ID_EX_ALU2Mux, ID_EX_loadByteMux;

dff ID_EX_WriteRegR (.q(ID_EX_WriteReg), .d(WriteReg), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_enableMemR (.q(ID_EX_enableMem), .d(enableMem), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_readWriteMemR (.q(ID_EX_readWriteMem), .d(readWriteMem), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_ZenR (.q(ID_EX_Zen), .d(Zen), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_VenR (.q(ID_EX_Ven), .d(Ven), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_NenR (.q(ID_EX_Nen), .d(Nen), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_DstMuxR (.q(ID_EX_DstMux), .d(DstMux), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_addrCalcR (.q(ID_EX_addrCalc), .d(addrCalc), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_ALU2MuxR (.q(ID_EX_ALU2Mux), .d(ALU2Mux), .wen(~cstall), .clk(clk), .rst(rst|stall));
dff ID_EX_loadByteMuxR (.q(ID_EX_loadByteMux), .d(loadByteMux), .wen(~cstall), .clk(clk), .rst(rst|stall));

Register ID_EX_SrcData1R ( .clk(clk), .rst(rst|stall), .D(SrcData1), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_SrcData1), .Bitline2());
Register ID_EX_SrcData2R ( .clk(clk), .rst(rst|stall), .D(SrcData2), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_SrcData2), .Bitline2());
Register ID_EX_InstR ( .clk(clk), .rst(rst|stall), .D(IF_ID_Inst), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_Inst), .Bitline2());
Register ID_EX_PC_incR ( .clk(clk), .rst(rst|stall), .D(IF_ID_PC_inc), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ID_EX_PC_inc), .Bitline2());

wire ALUInstAdd;
assign ALUInstAdd = (ID_EX_Inst[15] & ~ID_EX_Inst[14] & ~ID_EX_Inst[13]);

wire [3:0] ID_EX_Rt;
assign ID_EX_Rt = ID_EX_loadByteMux ? ID_EX_Inst[11:8] : ID_EX_Inst[3:0];

wire FwdOp1MX, FwdOp2MX, FwdOp1XX, FwdOp2XX;
assign FwdOp1MX = MEM_WB_WriteReg && (MEM_WB_Inst[11:8] == ID_EX_Inst[7:4]) && (MEM_WB_Inst[11:8] != 4'b0000);
assign FwdOp2MX = MEM_WB_WriteReg && (MEM_WB_Inst[11:8] == ID_EX_Rt) & (MEM_WB_Inst[11:8] != 4'b0000);

assign FwdOp1XX = EX_MEM_WriteReg && (EX_MEM_Inst[11:8] == ID_EX_Inst[7:4]) && (EX_MEM_Inst[11:8] != 4'b0000);
assign FwdOp2XX = EX_MEM_WriteReg && (EX_MEM_Inst[11:8] == ID_EX_Rt) && (EX_MEM_Inst[11:8] != 4'b0000);

wire [15:0] Rs;
assign Rs = FwdOp1XX ? EX_MEM_Result : (FwdOp1MX ? DstData : ID_EX_SrcData1);

wire [15:0] Rt;
assign Rt = FwdOp2XX ? EX_MEM_Result : (FwdOp2MX ? DstData : ID_EX_SrcData2);

wire [15:0] Operand1;
assign Operand1 = ID_EX_addrCalc ? (Rs & 16'hFFFE) : Rs;

wire [15:0] Operand2;
assign Operand2 = ID_EX_addrCalc ? {{11{ID_EX_Inst[3]}}, ID_EX_Inst[3:0], 1'b0} : (ID_EX_ALU2Mux ? {12'h000, ID_EX_Inst[3:0]}:Rt);


ALU ALU (.op(ALUInstAdd ? 3'b000 : ID_EX_Inst[14:12]), .a(Operand1), .b(Operand2), .out(ALUOut), .Z(ZALU), .V(VALU), .N(NALU));


wire loadImmediate;
assign loadImmediate = (ID_EX_Inst[15] & ~ID_EX_Inst[14] & ID_EX_Inst[13]);
wire loadPC;
assign loadPC = (ID_EX_Inst[15] & ID_EX_Inst[14] & ID_EX_Inst[13] & ~ID_EX_Inst[12]);
wire [15:0] Result;
assign Result = loadImmediate ? (ID_EX_Inst[12] ? {ID_EX_Inst[7:0], Rt[7:0]} : {Rt[15:8], ID_EX_Inst[7:0]}) : 
                loadPC ?        ID_EX_PC_inc :
                                ALUOut;

dff Z (.q(ZOut), .d(ZALU), .wen(ID_EX_Zen&(ID_EX_Inst[15:0]!=16'h0000)), .clk(clk), .rst(rst));
dff V (.q(Vout), .d(VALU), .wen(ID_EX_Ven), .clk(clk), .rst(rst));
dff N (.q(Nout), .d(NALU), .wen(ID_EX_Nen), .clk(clk), .rst(rst));

/**** MEMORY ****/

dff EX_MEM_WriteRegR (.q(EX_MEM_WriteReg), .d(ID_EX_WriteReg), .wen(~cstall), .clk(clk), .rst(rst));
dff EX_MEM_enableMemR (.q(EX_MEM_enableMem), .d(ID_EX_enableMem), .wen(~cstall), .clk(clk), .rst(rst));
dff EX_MEM_readWriteMemR (.q(EX_MEM_readWriteMem), .d(ID_EX_readWriteMem), .wen(~cstall), .clk(clk), .rst(rst));
dff EX_MEM_DstMuxR (.q(EX_MEM_DstMux), .d(ID_EX_DstMux), .wen(~cstall), .clk(clk), .rst(rst));

Register EX_MEM_ResultR ( .clk(clk), .rst(rst), .D(Result), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_Result), .Bitline2());
Register EX_MEM_SrcData2R ( .clk(clk), .rst(rst), .D(ID_EX_SrcData2), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_SrcData2), .Bitline2());
Register EX_MEM_InstR ( .clk(clk), .rst(rst), .D(ID_EX_Inst), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(EX_MEM_Inst), .Bitline2());


wire FwdMM;
assign FwdMM = (MEM_WB_Inst[15:12] == 4'b1000) ? ((MEM_WB_Inst[11:8] == EX_MEM_Inst[11:8]) ? 1'b1 : 1'b0) : 1'b0; // don't need to check if current M is store instruction since write to memory is only enabled for store instructions
wire [15:0] MemIn;
assign MemIn = (FwdMM && (MEM_WB_Inst[11:8] != 4'b0000)) ? DstData : EX_MEM_SrcData2;

//memory1c DMem (.data_out(MemOut), .data_in(MemIn), .addr(EX_MEM_Result), .enable(EX_MEM_enableMem), .wr(EX_MEM_readWriteMem), .clk(clk), .rst(rst));
wire [7:0] DInMeta1, DInMeta2, DWay1Out, DWay2Out;
wire DWriteWay1, DWriteWay2;
wire [63:0] DBlockEn;
wire [7:0] DWordEn, DMainWordEn;
wire [15:0] currBlockAdd;
wire write_data_array, write_tag_array;
six_decode SD (.in(EX_MEM_Result[9:4]), .out(DBlockEn));
three_decode TD1 (.in(EX_MEM_Result[3:1]), .out(DWordEn));
three_decode TD2 (.in(currBlockAdd[3:1]), .out(DMainWordEn));

wire validWay1, validWay2, LRUWay1;
dff validWay1R (.q(validWay1), .d(DWay1Out[1]), .wen(1'b1), .clk(clk), .rst(rst));
dff validWay2R(.q(validWay2), .d(DWay2Out[1]), .wen(1'b1), .clk(clk), .rst(rst));
dff LRUWay1R (.q(LRUWay1), .d(DWay1Out[0]), .wen(1'b1), .clk(clk), .rst(rst));
assign DWriteWay1 = (write_tag_array) & (~validWay1 | (validWay1 & LRUWay1 & validWay2));
assign DWriteWay2 = (write_tag_array) & ~DWriteWay1;

wire [6:0] tagv1, tagv2;
dff tagv1R [6:0] (.q(tagv1), .d(DWay1Out[7:1]), .wen(1'b1), .clk(clk), .rst(rst));
dff tagv2R [6:0] (.q(tagv2), .d(DWay2Out[7:1]), .wen(1'b1), .clk(clk), .rst(rst));

assign DInMeta1 = DWriteWay1 ? {EX_MEM_Result[15:10], 2'b10} : {tagv1, 1'b1};
assign DInMeta2 = DWriteWay2 ? {EX_MEM_Result[15:10], 2'b10} : {tagv2, 1'b1};

MetaDataArray DMeta1 (.clk(clk), .rst(rst), .DataIn(DInMeta1), .Write(write_tag_array), .BlockEnable(DBlockEn), .DataOut(DWay1Out));
MetaDataArray DMeta2 (.clk(clk), .rst(rst), .DataIn(DInMeta2), .Write(write_tag_array), .BlockEnable(DBlockEn), .DataOut(DWay2Out));

wire miss_detected1, miss_detected2;
wire Way1TagMatch, Way2TagMatch;
assign cstall = fsm_busy | miss_detected | (miss_detected & Ifsm_busy);
assign miss_detected1 = EX_MEM_enableMem & (~Way1TagMatch & ~Way2TagMatch);
dff missEdge (.q(miss_detected2), .d(miss_detected1), .wen(1'b1), .clk(clk), .rst(rst));
assign miss_detected = miss_detected1 & ~miss_detected2;

//Metadata Bits[7:2] are tag; Bit[1] is valid bit; Bit[0] is LRU bit :)
assign Way1TagMatch = (EX_MEM_Result[15:10] == DWay1Out[7:2]) & DWay1Out[1] & ~write_tag_array;
assign Way2TagMatch = (EX_MEM_Result[15:10] == DWay2Out[7:2]) & DWay2Out[1] & ~write_tag_array;

wire way, matchWay;
assign matchWay = (Way1TagMatch) ? 1'b0 : 1'b1;
assign way = fsm_busy ? ~(~validWay1 | (validWay1 & LRUWay1 & validWay2)): matchWay;
wire [7:0] DCacheWord;
wire [127:0] DCBlockEn;
wire [15:0] mainMemIn, mainMemAdd, DCacheIn;
seven_decode SeD (.in({EX_MEM_Result[9:4], way}), .out(DCBlockEn));
assign DCacheWrite = write_data_array | (EX_MEM_readWriteMem & ~miss_detected1);
assign DCacheWord = fsm_busy ? DMainWordEn : DWordEn;
assign DCacheIn = fsm_busy ? mainMemOut : MemIn;
DataArray DCache (.clk(clk), .rst(rst), .DataIn(DCacheIn), .Write(DCacheWrite), .BlockEnable(DCBlockEn), .WordEnable(DCacheWord), .DataOut(MemOut));

cache_fill_FSM cacheFSM(.clk(clk), .rst_n(rst_n), .miss_detected(miss_detected), .miss_address(EX_MEM_Result), .fsm_busy(fsm_busy), .write_data_array(write_data_array),
.write_tag_array(write_tag_array), .memory_address(currBlockAdd), .memory_data_valid(memory_data_valid), .memBusy(Ifsm_busy));

wire mainMemEn, mainMemWR;
assign mainMemAdd = (Ifsm_busy & ~sameCycleMiss) ? IcurrBlockAdd : fsm_busy ? currBlockAdd : EX_MEM_Result; 
assign mainMemEn = EX_MEM_readWriteMem | fsm_busy | Ifsm_busy;
assign mainMemWR = (EX_MEM_readWriteMem & ~miss_detected1) & ~fsm_busy & ~Ifsm_busy;
assign mainMemIn = MemIn;
memory4c mainMem (.data_out(mainMemOut), .data_in(mainMemIn), .addr(mainMemAdd), .enable(mainMemEn), .wr(mainMemWR), .clk(clk), .rst(rst), .data_valid(memory_data_valid));

/**** WRITEBACK ****/

wire MEM_WB_DstMux;

dff MEM_WB_WriteRegR (.q(MEM_WB_WriteReg), .d(EX_MEM_WriteReg), .wen(~cstall), .clk(clk), .rst(rst));
dff MEM_WB_DstMuxR (.q(MEM_WB_DstMux), .d(EX_MEM_DstMux), .wen(~cstall), .clk(clk), .rst(rst)); 
//Don't want to flush WB on cstall because it breaks MX forwarding; shouldn't matter because cstall only happens on LW or SW
//SW doesn't do anything in WB and LW writes will be overwritten once we stop cstalling anyways

Register MEM_WB_ResultR ( .clk(clk), .rst(rst), .D(EX_MEM_Result), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_Result), .Bitline2());
Register MEM_WB_MemOutR ( .clk(clk), .rst(rst), .D(MemOut), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_MemOut), .Bitline2());
Register MEM_WB_InstR ( .clk(clk), .rst(rst), .D(EX_MEM_Inst), .WriteReg(~cstall), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MEM_WB_Inst), .Bitline2());

//assign DstData = DstMux[1] ? (Inst[12] ? {Inst[7:0], SrcData2[7:0]} : {SrcData2[15:8], Inst[7:0]}) : (DstMux[0] ? MemOut : ALUOut);
assign DstData = (MEM_WB_DstMux) ? MEM_WB_MemOut : MEM_WB_Result;

assign pc = PC_val;
assign hlt = (&MEM_WB_Inst[15:12]);

endmodule