/*
Clock prescaler for MEMS microphones MPW-2
It multiplies the system clock period by a natural number in a range 
of 1:255. 
*/
module Mic_Clk(
    input  wire clk,
    input  wire rst,
    output wire micclk);
  
  reg micclk_t;
  reg [7:0] count;
  wire [7:0] limit;
  wire en;

  // externalize this register to be configurable via WishBone
  assign limit = 8'h03;
  
  assign en = count == limit ? 1'b1 : 1'b0;
  assign micclk = micclk_t;
  
  always@(posedge clk) begin
    if(rst ==1'b1) 
    begin
      count <= 8'h00;
      micclk_t <= 0;
    end
    else  
    begin
      if(count < limit)
      	count <= count + 1'b1;
      else 
        count <= 8'h00;
      if( en == 1'b1)
        micclk_t <= ~micclk_t;
    end
  end
      
endmodule


