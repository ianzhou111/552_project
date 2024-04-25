module double_flop (q2, d2, wen, clk, rst);

    output         [1:0]q2; //DFF output
    input          [1:0]d2; //DFF input
    input 	   wen; //Write Enable
    input          clk; //Clock
    input          rst; //Reset (used synchronously)

dff f0(.q(q2[0]), .d(d2[0]), .wen(wen), .clk(clk), .rst(rst));
dff f1(.q(q2[1]), .d(d2[0]), .wen(wen), .clk(clk), .rst(rst));


endmodule