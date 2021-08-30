
//////////////////////////////////////////////////////////////////////////////////
// 
// Design Name: 	 Parametric Register
// Module Name:    REG 
// Luis Osses Gutierrez
//
/////////////////////////////////////////////////////////////////////////////////
module REG(clk,rst,ce, D, Q);
	parameter n=16; // Parameter
  input wire [n-1:0] D;
	input wire rst,clk,ce;
  output reg [n-1:0] Q;

  always @(posedge clk)
	begin
      if(rst) Q<=0;
		else 
          if(ce)
			Q<=D;
	end

endmodule
