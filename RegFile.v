module dff (q, d, wen, clk, rst);

    output         q; //DFF output
    input          d; //DFF input
    input 	   wen; //Write Enable
    input          clk; //Clock
    input          rst; //Reset (used synchronously)

    reg            state;

    assign q = state;

    always @(posedge clk) begin
      state = rst ? 0 : (wen ? d : state);
    end

endmodule

module ReadDecoder_4_16(input [3:0] RegId, output [15:0] Wordline);

assign Wordline[0]  = ~RegId[3] & ~RegId[2] & ~RegId[1] & ~RegId[0];
assign Wordline[1]  = ~RegId[3] & ~RegId[2] & ~RegId[1] &  RegId[0];
assign Wordline[2]  = ~RegId[3] & ~RegId[2] &  RegId[1] & ~RegId[0];
assign Wordline[3]  = ~RegId[3] & ~RegId[2] &  RegId[1] &  RegId[0];
assign Wordline[4]  = ~RegId[3] &  RegId[2] & ~RegId[1] & ~RegId[0];
assign Wordline[5]  = ~RegId[3] &  RegId[2] & ~RegId[1] &  RegId[0];
assign Wordline[6]  = ~RegId[3] &  RegId[2] &  RegId[1] & ~RegId[0];
assign Wordline[7]  = ~RegId[3] &  RegId[2] &  RegId[1] &  RegId[0];
assign Wordline[8]  =  RegId[3] & ~RegId[2] & ~RegId[1] & ~RegId[0];
assign Wordline[9]  =  RegId[3] & ~RegId[2] & ~RegId[1] &  RegId[0];
assign Wordline[10] =  RegId[3] & ~RegId[2] &  RegId[1] & ~RegId[0];
assign Wordline[11] =  RegId[3] & ~RegId[2] &  RegId[1] &  RegId[0];
assign Wordline[12] =  RegId[3] &  RegId[2] & ~RegId[1] & ~RegId[0];
assign Wordline[13] =  RegId[3] &  RegId[2] & ~RegId[1] &  RegId[0];
assign Wordline[14] =  RegId[3] &  RegId[2] &  RegId[1] & ~RegId[0];
assign Wordline[15] =  RegId[3] &  RegId[2] &  RegId[1] &  RegId[0];

endmodule

module WriteDecoder_4_16(input [3:0] RegId, input WriteReg, output [15:0] Wordline);

wire [15:0] out;

ReadDecoder_4_16 dec(.RegId(RegId), .Wordline(out));

assign Wordline = out & {16{WriteReg}};
endmodule

module BitCell( input clk, input rst, input D, input WriteEnable, input ReadEnable1, input
ReadEnable2, inout Bitline1, inout Bitline2);

wire out;

dff ff (.q(out), .d(D), .wen(WriteEnable), .clk(clk), .rst(rst));

assign Bitline1 = ReadEnable1 ? out : 1'bz;
assign Bitline2 = ReadEnable2 ? out : 1'bz;

endmodule

module Register( input clk, input rst, input [15:0] D, input WriteReg, input ReadEnable1, input
ReadEnable2, inout [15:0] Bitline1, inout [15:0] Bitline2);

BitCell cells [15:0] (.clk(clk), .rst(rst), .D(D), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .Bitline1(Bitline1), .Bitline2(Bitline2));

endmodule

module RegisterFile(input clk, input rst, input [3:0] SrcReg1, input [3:0] SrcReg2, input [3:0]
DstReg, input WriteReg, input [15:0] DstData, inout [15:0] SrcData1, inout [15:0] SrcData2);

wire [15:0] src1_sel, src2_sel;
wire [15:0] dst_sel;
wire [15:0] reg_out1, reg_out2;

ReadDecoder_4_16 src1_dec (.RegId(SrcReg1), .Wordline(src1_sel));
ReadDecoder_4_16 src2_dec (.RegId(SrcReg2), .Wordline(src2_sel));

WriteDecoder_4_16 wrt_dec (.RegId(DstReg), .WriteReg(WriteReg), .Wordline(dst_sel));

Register file [15:0] (.clk(clk), .rst(rst), .D(DstData), .WriteReg(dst_sel), .ReadEnable1(src1_sel), .ReadEnable2(src2_sel), .Bitline1(SrcData1), .Bitline2(SrcData2));

//assign SrcData1 = (WriteReg & (DstReg == SrcReg1)) ? DstData : reg_out1;
//assign SrcData2 = (WriteReg & (DstReg == SrcReg2)) ? DstData : reg_out2;

endmodule