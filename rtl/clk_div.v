// CLK DIV MODULE

// ---------- Module START ---------- //
module CLOCK_DIVIDER #(parameter N=8)( 
                     // C = counter end value
input clk, rst,
input [N-1:0] C,
output reg we_pcm);
    
    
//INTERNAL REGISTERS
  reg [N-1:0] count = 0;  

  // ============= COUNTER LOGIC START ============= //
  always @(posedge clk)
     begin
       if (rst) begin
         we_pcm <= 1'b0;
         count <= 0;
       end
       else begin
            count <= count + 1;               
                if (count == C-1) begin
                      we_pcm <= 1'b1; 
                      count <= 0;  //reset counter
                   end 
                else begin
                  we_pcm<=1'b0;
                end
              
    // ============= COUNTER LOGIC END ============== //   
   		end   
  end
endmodule 
// ---------- Module END ---------- //
