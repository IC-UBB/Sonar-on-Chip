// ---------------------------------------------------- //
//        	     	RSS Test Bench
//         Mauricio Montanares, Luis Osses, Max Cerda 2021
// ---------------------------------------------------- //     
`timescale 1ns / 1ps
module testRSS ();
  
  //constants
  parameter N = 16;
  parameter len_data_test = 10000;
  //set counter for FOR LOOP
  integer count;
  integer cout_for_dec = 10;
  integer f;
  //memory for test
  reg data_for_test[len_data_test-1:0];
  
  //  ====== ports initialization begin  ====== //
  
  reg clk, we, rst, Ctrl;
  reg [N-1:0] data_in;
  
 wire signed [N-1:0] data_out;
  
  //  xxxx ports initialization end xxxx //
  

  // ====== Initilization of DUT ====== //
  
  RSS0 DUT(clk,we,rst,Ctrl,data_in,data_out);
  
  // ================== TEST BEGING ==================== //
  initial begin
    f = $fopen("./output.csv","w");
  end
	// ---initial values begin --- //
    initial begin
      clk = 0;
      rst = 0;
      we = 0;
      data_in = 0;
      Ctrl = 0;
      
    //read memory data
  	$readmemh("y1_V2.txt", data_for_test);
   
    

    end
  // ---initial values end --- //
  
  //clock 
  always #10 clk = ~clk;

    //--------- stimulus start! ---------- //

    initial begin
      we = 1;
      //put rst
      rst = 1;			//set rst
      @(negedge clk);	//wait for negedge clk
      rst = 0;			//set rst = 0
      Ctrl = 1;

      // --- Using test_data_input for stimulus DUT --- //

      for(count = 0; count < len_data_test; count = count + 1) begin
        
        data_in = data_for_test[count];
        if(count == 0) begin
          $display("data_in,data_out_L1,data_out_cic");
          $fwrite(f,"data_in,data_out_L1,data_out_cic\n");
        end
        if(count!=0 || count == 0) begin
        	$display ("%d,%d,%d",data_for_test[count], DUT.sum1, data_out);
          $fwrite(f,"%d,%d,%d\n",data_for_test[count], DUT.sum1, data_out); 
          
        end
    //wait for negedge clk for change the values
        @(negedge clk);
      end
      $fclose(f);
       $finish;
    end
  //--------- stimulus END! ---------- //
  
  //--------- dump to file! ---------- //
      initial begin
        $dumpfile ("rss.vcd");
    $dumpvars;
    end
    endmodule
  
  // xxxxxxxxxxxxxxxxxxxx TEST END xxxxxxxxxxxxxxxxxxxx //  
