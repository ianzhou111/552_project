module two_bit_inc(
    input [1:0] A,
    input en,
    output [1:0] Sum,
    output Ovfl
);

wire [1:0] s;
wire c1, c2;
one_bit_adder adder1(A[0], 1'b1, 1'b0, s[0], c1);
one_bit_adder adder2(A[1], 1'b0, c1, s[1], c2);

assign Ovfl = c2;

assign Sum = en ? s : A;

endmodule

module three_bit_inc(
    input [2:0] A,
    input en,
    output [2:0] Sum,
    output Ovfl
);

wire [2:0] s;
wire c1, c2, c3;
one_bit_adder adder1(A[0], 1'b1, 1'b0, s[0], c1);
one_bit_adder adder2(A[1], 1'b0, c1, s[1], c2);
one_bit_adder adder3(A[2], 1'b0, c2, s[2], c3);

assign Ovfl = c3;

assign Sum = en ? s : A;

endmodule


module sixteen_bit_inc(
    input [15:0] A,
    input en,
    output [15:0] Sum,
    output Ovfl
);

wire [15:0] s;
wire [15:0]c;

one_bit_adder adder[15:0] (A[15:0], {{14{1'b0}}, 2'b10}, {c[14:0], 1'b0}, s[15:0], c[15:0]);

assign Ovfl = c[15];

assign Sum = en ? s : A;

endmodule

module cache_fill_FSM(clk, rst_n, miss_detected, miss_address, fsm_busy, write_data_array,
write_tag_array,memory_address, memory_data_valid, memBusy);
input clk, rst_n;
input miss_detected; // active high when tag match logic detects a miss
input [15:0] miss_address; // address that missed the cache
output fsm_busy; // asserted while FSM is busy handling the miss (can be used as pipeline stall signal)
output write_data_array; // write enable to cache data array to signal when filling with memory_data
output write_tag_array; // write enable to cache tag array to signal when all words are filled in to data array
output [15:0] memory_address; // address to read from memory
input memory_data_valid; // active high indicates valid data returning on memory bus
input memBusy; // active high indicates valid data returning on memory bus

wire stateIn, state;
wire [1:0] count, countIn;
wire [2:0] chCount, chCountIn;
wire ovf, en, addOvf, addEn, chOvf;
wire [15:0] addIn, addInc;

dff Count[1:0]  (.q(count), .d(countIn), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff ChCount[2:0]  (.q(chCount), .d(chCountIn), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff Address[15:0] (.q(memory_address), .d(addIn), .wen(1'b1), .clk(clk), .rst(~rst_n));

two_bit_inc Inc2 (.A(count), .en(en), .Sum(countIn), .Ovfl(ovf));
three_bit_inc Inc3 (.A(chCount), .en(addEn), .Sum(chCountIn), .Ovfl(chOvf));
sixteen_bit_inc AddInc (.A(memory_address), .en(addEn), .Sum(addInc), .Ovfl(addOvf));

dff State (.q(state), .d(stateIn), .wen(1'b1), .clk(clk), .rst(~rst_n));
dff detected_miss (.q(detected), .d(detectedIn), .wen(1'b1), .clk(clk), .rst(~rst_n));

assign stateIn = (~state & miss_detected) | (state & (~chOvf | ~(count[0] & count[1])));
assign en = state & ~memBusy;
assign fsm_busy = write_data_array | write_tag_array;
assign write_data_array = state;
assign write_tag_arrayIn = ~stateIn & state;
dff tagSigDelay (.q(write_tag_array), .d(write_tag_arrayIn), .wen(1'b1), .clk(clk), .rst(~rst_n));

assign addEn = count[1] & count[0] & state & memory_data_valid & ~memBusy;
assign addIn = miss_detected ? (miss_address & 16'hFFF0) : addInc;

endmodule

module cache_tb ();

	reg clk, rst_n;
    reg miss_detected;
    reg [15:0] miss_address;
    wire fsm_busy;
    wire write_data_array;
    wire write_tag_array;
    wire [15:0] memory_address;
    reg memory_data_valid;
	
    cache_fill_FSM DUT(.*);
	
	
    initial begin
		clk = 0;
		rst_n = 0;
		@(posedge clk);
		rst_n = 1;
		miss_detected = 0;
        memory_data_valid = 0;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		miss_detected = 1;
        miss_address = 16'h1233;
        @(posedge clk);
        miss_address = 16'hFFFF; 
		miss_detected = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        memory_data_valid = 1;
        @(posedge clk);
        memory_data_valid = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        memory_data_valid = 1;
		@(posedge clk);
    end
	
	always #10 clk = ~clk;
endmodule