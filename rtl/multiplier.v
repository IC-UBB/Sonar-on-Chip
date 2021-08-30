//////////////////////////////////////////////////////////////////////////////////
// Module Name:    MULTIPLICADOR POR CONSTANTE.
// Luis Osses Gutierrez
//////////////////////////////////////////////////////////////////////////////////
module MULTI   #(parameter n =32)  (data_i,amplify, multiplier_o);
  
  input   wire [n-1:0]   data_i;
  input   wire [n-1:0]   amplify;
  output  wire [n-1:0]   multiplier_o;
    
  assign multiplier_o = data_i * amplify; 
  
endmodule
