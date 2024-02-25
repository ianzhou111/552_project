module adder_tb();

logic [15:0] A; //Input values
logic [15:0] Sum; //sum output
logic Ovfl; //To indicate overflow

add_4 DUT(.*);

initial begin 
    A = 16'h0b00;
    #1;


end


endmodule 