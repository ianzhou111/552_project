module br_control (input [2:0] condition, input [2:0] flags, output reg branch);

always @* case (condition)
	3'b000 : begin
		branch = ~flags[2];
	end

	3'b001 : begin
		branch = flags[2];
	end

	3'b010 : begin
		branch = (~flags[2] & ~flags[0]);
	end

	3'b011 : begin
		branch = flags[0];
	end

	3'b100 : begin
		branch = flags[2] | (~flags[2] & ~flags[0]);
	end

	3'b101 : begin
		branch = flags[0] | flags[2];
	end

	3'b110 : begin
		branch = flags[1];
	end

	3'b111 : begin
		branch = 1;
	end
endcase
endmodule