module Shifter (Shift_Out, Shift_In, Shift_Val, Mode);
input [15:0] Shift_In; 	// This is the input data to perform shift operation on
input [3:0] Shift_Val; 	// Shift amount (used to shift the input data)
input  [1:0] Mode; 		// 00 Shift left, 01 is shift right, 10 is rotate right 
output [15:0] Shift_Out; 	// Shifted output data

wire [15:0]r1,r2,r3;

assign r1 = (Shift_Val[0]) ? ((Mode[1])? ({Shift_In[0],Shift_In[15:1]}) : (Mode[0])? {Shift_In[15],Shift_In[15:1]}:{Shift_In[14:0],1'b0}) : Shift_In; 

assign r2 = (Shift_Val[1]) ? ((Mode[1])? ({r1[1:0],r1[15:2]}) : (Mode[0])? {{2{r1[15]}},r1[15:2]}:{r1[13:0],2'b0}) :r1; 

assign r3 = (Shift_Val[2]) ? ((Mode[1])? ({r2[3:0],r2[15:4]}): (Mode[0])? {{4{r2[15]}},r2[15:4]}:{r2[11:0],4'b0}) :r2; 

assign Shift_Out = (Shift_Val[3]) ? ((Mode[1])? ({r3[7:0],r3[15:8]}): (Mode[0])? {{8{r3[15]}},r3[15:8]}:{r3[7:0],8'b0}) :r3;


endmodule
