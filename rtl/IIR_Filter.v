/*
IIR filter for MPW-2
*/
module IIR_Filter
  #(
    parameter N  = 16)
  (
    input         clk,
    input         rst,
    input         en,
    input [N-1:0] X,
    input [N-1:0] a0,
    input [N-1:0] a1,
    input [N-1:0] a2,
    input [N-1:0] b1,
    input [N-1:0] b2,
    output 		  valid,
    output[N-1]   Y);
  
  reg [N-1:0] X1, X2;
  reg [N-1:0] Y1, Y2, Yt;
  
  assign Y = Yt;
  assign Yt = X*a0 + X1*a1 + a2*X2 - Y1*b1 + Y2*b2;
  
  always@(posedge clk) begin
    if(rst ==1'b1) 
    begin
      Y1 <= 0;
      Y2 <= 0;
      X1 <= 0;
      X2 <= 0;
    end
    else if(en == 1'b1) 
    begin 
      Y1 <= Yt;
      Y2 <= Y1;
      X1 <= X;
      X2 <= X1;
    end
  end
  
endmodule
