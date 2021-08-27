//////////////////////////////////////////////////////////////////////////////////
// Module Name:    MULTIPLICADOR POR CONSTANTE.
// Luis Osses Gutierrez
//////////////////////////////////////////////////////////////////////////////////
module MULTI   #(parameter n =32)  (data_i,amplify, multiplier_o);
  
  input  [n-1:0]   data_i;
  input  [n-1:0]   amplify;
  output [n-1:0]   multiplier_o;
  reg    [n-1:0]   multiplier_o;
    
  assign multiplier_o = data_i * amplify; 
  
endmodule
