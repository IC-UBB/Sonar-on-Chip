// Code your design here
//maximiliano cerda cid

module comparator #(parameter n=32)(data_i,treshold,compare_o);
  input [n-1:0] data_i, treshold; //maf filter output and treshold value  
  output compare_o; //output of the compare block
  reg compare_o;

  assign compare_o = (data_i >= treshold) ? 1'b1:1'b0;

endmodule
