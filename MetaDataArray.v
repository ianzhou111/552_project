//Tag Array of 128  blocks
//Each block will have 1 byte
//BlockEnable is one-hot
//WriteEnable is one on writes and zero on reads

module MetaDataArray(input clk, input rst, input [9:0] DataIn, input Write, input [31:0] BlockEnable, output [9:0] DataOut);
	MBlock Mblk[31:0]( .clk(clk), .rst(rst), .Din(DataIn), .WriteEnable(Write), .Enable(BlockEnable), .Dout(DataOut));
endmodule

module MBlock( input clk,  input rst, input [9:0] Din, input WriteEnable, input Enable, output [9:0] Dout);
	MCell mc[9:0]( .clk(clk), .rst(rst), .Din(Din[9:0]), .WriteEnable(WriteEnable), .Enable(Enable), .Dout(Dout[9:0]));
endmodule

module MCell( input clk,  input rst, input Din, input WriteEnable, input Enable, output Dout);
	wire q;
	assign Dout = (Enable & ~WriteEnable) ? q:'bz;
	dff dffm(.q(q), .d(Din), .wen(Enable & WriteEnable), .clk(clk), .rst(rst));
endmodule

