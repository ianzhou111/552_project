module double_flop ([1:0]q, [1:0]d, wen, clk, rst);

    output         [1:0]q; //DFF output
    input          [1:0]d; //DFF input
    input 	   wen; //Write Enable
    input          clk; //Clock
    input          rst; //Reset (used synchronously)

dff f0(.q[0](q), .d[0](d), .wen(wen), .clk(clk), .rst(rst));
dff f1(.q[1](q), .d[1](d), .wen(wen), .clk(clk), .rst(rst));


endmodule