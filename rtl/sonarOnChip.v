/*
Sonar on Chip top level module based on user project example
Files:
defines.v - macroodefinitions (come vith Caravel)
Mic_Clk.v - clock divider for MEMS microphones
*/
`include "defines.v"
`define BUS_WIDTH 16 

module SonarOnChip(
  
  `ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
  `endif

    // Wishbone Slave ports (WB MI A)
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [2*`BUS_WIDTH-1:0] wbs_dat_i,
    input wire [2*`BUS_WIDTH-1:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [2*`BUS_WIDTH-1:0] wbs_dat_o,

    // Logic Analyzer Signals
    input wire  [127:0] la_data_in,
    output wire [127:0] la_data_out,
    input wire  [127:0] la_oenb,
 

    // IOs
    input wire  [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
  output wire [2:0] irq
	);
  /*----------------------------- module declaration ends ---------------------*/
  
  /* clock and reset signals*/
  
  wire clk;
  wire rst;
  
  // enable outputs (input does not care about that)
	// low 16 as output higher 16 as inputs
  assign io_oeb = 38'h00FFFF0000;
  
  assign clk = wb_clk_i;
  assign rst = wb_rst_i;
  
  /* Clock signal for MEMS microphones */
  wire mclk;
  
  /* Compare module wires*/
  wire [2*`BUS_WIDTH-1:0] treshold;
  wire [2*`BUS_WIDTH-1:0] maf_o;
  wire compare_ch1_out;
	assign io_out[16] = compare_ch1_out;
 
  /* PCM inputs from GPIO, will come from PDM */	
  wire [`BUS_WIDTH-1:0] pcm_i;
	assign pcm_i = io_in[`BUS_WIDTH-1:0];

  /* PCM register output signal*/
  wire [`BUS_WIDTH-1:0] pcm_o;
  /* 32 - bit sign extended pcm value */
  wire [2*`BUS_WIDTH-1:0] pcm32, pcm32abs;
  
  /* clock enable wiring*/
  wire ce;
  assign ce = control[0]; 
  
  /* Multiplier  output */
  wire [2*`BUS_WIDTH-1:0] mul_o;
  
 /** Wishbone Slave Interface **/
  // WB MI A
	wire [31:0] rdata; 
	wire [31:0] wdata;
	
	reg wbs_done;
	wire wb_valid;
	wire [3:0] wstrb;
	wire [31:0] la_write;

	assign wbs_ack_o = wbs_done;	
	assign wb_valid = wbs_cyc_i && wbs_stb_i; 
	assign wstrb = wbs_sel_i & {4{wbs_we_i}};
	assign wbs_dat_o = rdata;
	assign wdata = wbs_dat_i;

`include "wbs_mmap.v"
	reg [`BUS_WIDTH-1:0] control;
	reg [`BUS_WIDTH-1:0] amp;
	reg [`BUS_WIDTH-1:0] a0;
	reg [`BUS_WIDTH-1:0] a1;
	reg [`BUS_WIDTH-1:0] a2;
	reg [`BUS_WIDTH-1:0] b1;
	reg [`BUS_WIDTH-1:0] b2;
	wire iir_valid;
	always@(posedge clk) begin
		if(rst) begin
			wbs_done <= 0;
			a0 <= 0;
			a1 <= 0;
			a2 <= 0;
			b1 <= 0;
			b2 <= 0;
		end
		else begin
			wbs_done <= 0;
			if(wb_valid) begin
				case(wbs_adr_i[5:2])
					CONTROL_ADDR: control <= wbs_dat_i;
					A0_ADDR			: a0 <= wbs_dat_i;
					A1_ADDR			: a1 <= wbs_dat_i;
					A2_ADDR			: a2 <= wbs_dat_i;
					B1_ADDR			: b1 <= wbs_dat_i;
					B2_ADDR			: b2 <= wbs_dat_i;
					AMP_ADDR		: amp <= wbs_dat_i;
					default:;
				endcase
				wbs_done <= 1;
			end
		end
	end 
  /*-------------------------Structural modelling ----------------------------*/
  
  /*------------------------  PDM starts   -----------------------------------*/
  /*------------------------   PDM ends    -----------------------------------*/
  
  /*------------------------  PCM starts   -----------------------------------*/
  
  REG pcm_reg(clk, rst, control[0], pcm_i, pcm_o);
  
  /*------------------------   PCM ends    -----------------------------------*/
  
  /*------------------------   SE starts    -----------------------------------*/
  signext se(pcm_o, pcm32);
  /*------------------------   SE ends    -----------------------------------*/
  
  /*------------------------  MUL starts   -----------------------------------*/
	wire [2*`BUS_WIDTH-1:0]mul_i;
	wire [2*`BUS_WIDTH-1:0]iir_data;
	assign mul_i = (io_in[4]) ? pcm32 : iir_data; 

  MULTI mul(mul_i, amp, mul_o);
  /*------------------------   MUL ends    -----------------------------------*/
  
  /*------------------------ AMP starts   -----------------------------------*/
  //REG #(.n(`BUS_WIDTH)) amp_reg(clk, rst, ce & wb_valid, amp_i, amp);
  /*------------------------ AMP endss   -----------------------------------*/
  
  
  /*------------------------  ABS starts   -----------------------------------*/
  Abs  abs(mul_o, pcm32abs);
  /*------------------------   ABS ends    -----------------------------------*/
  
  /*------------------------  IIR starts   -----------------------------------*/
	IIR_Filter u_Filter(
    .clk(clk),
    .rst(rst),
    .en(ce),
    .X(pcm_o),
    .a0(a0),
    .a1(a1),
    .a2(a2),
    .b1(b1),
    .b2(b2),
    .valid(iir_valid),
    .Y(iir_data)
		);
  /*------------------------   IIR ends    -----------------------------------*/
  
  /*------------------------  MAMOV starts   ---------------------------------*/
  MAF_FILTER maf(clk, rst, ce, pcm32abs, maf_o);
  /*------------------------   MAMOV ends    ---------------------------------*/
  
  /*------------------------  COMP starts   ----------------------------------*/
  
  comparator comp(maf_o, treshold, compare_ch1_out);
  
  /*------------------------   COMP ends    ----------------------------------*/
  
  /*------------------------  CLKDIV starts   --------------------------------*/
 
  Mic_Clk micclk(clk, rst, mclk);
  
  /*------------------------  CLOCKDIV ends   --------------------------------*/


endmodule



