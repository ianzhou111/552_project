module control (input [3:0] Opcode, output WriteReg , output ALU2Mux, output [2:0] DstMux, output enableMem, output readWriteMem)

always @* case (Opcode)
	4'b0000 : begin //ADD
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b0001 : begin //SUB
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b0010 : begin //XOR
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b0011 : begin //RED
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b0100 : begin //SLL
		WriteReg = 1'b1;
		ALU2Mux = 1'b1;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b0101 : begin //SRA
		WriteReg = 1'b1;
		ALU2Mux = 1'b1;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b0110 : begin //ROR
		WriteReg = 1'b1;
		ALU2Mux = 1'b1;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b0111 : begin //PADDSB
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b1000 : begin //LW
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b1;
		readWriteMem = 1'b0;
	end
	
	4'b1001 : begin //SW
		WriteReg = 1'b0;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b1;
		readWriteMem = 1'b1;
	end
	
	4'b1010 : begin //LLB
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b10;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end	

	4'b1011 : begin //LHB
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b10;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
	
	4'b1100 : begin //B
		WriteReg = 1'b0;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end

	4'b1101 : begin //BR
		WriteReg = 1'b0;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end

	4'b1110 : begin //PCS
		WriteReg = 1'b1;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end

	4'b1111 : begin //HLT
		WriteReg = 1'b0;
		ALU2Mux = 1'b0;
		DstMux = 2'b00;
		enableMem = 1'b0;
		readWriteMem = 1'b0;
	end
endcase
endmodule