/*
Sonar on Chip top level module based on user project example
Files:
defines.v - macroodefinitions (come vith Caravel)
Mic_Clk.v - clock divider for MEMS microphones
*/
`include "include/defines.v"
`define BUS_WIDTH 16 

module SonarOnChip(
  
  `ifdef USE_POWER_PINS
    inout wire vdda1,	// User area 1 3.3V supply
    inout wire vdda2,	// User area 2 3.3V supply
    inout wire vssa1,	// User area 1 analog ground
    inout wire vssa2,	// User area 2 analog ground
    inout wire vccd1,	// User area 1 1.8V supply
    inout wire vccd2,	// User area 2 1.8v supply
    inout wire vssd1,	// User area 1 digital ground
    inout wire vssd2,	// User area 2 digital ground
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
  wire [2*`BUS_WIDTH-1:0] maf_o;
  wire compare_ch1_out;
	assign io_out[16] = compare_ch1_out;
 
  /* PCM inputs from GPIO, will come from PDM */	
  wire [`BUS_WIDTH-1:0] pcm_reg_i;
	//assign pcm_reg_i = io_in[`BUS_WIDTH-1:0];

  /* PCM register output signal*/
  wire [`BUS_WIDTH-1:0] pcm_reg_o;
  /* 32 - bit sign extended pcm value */
  wire [2*`BUS_WIDTH-1:0] pcm32, pcm32abs;
  
  /* clock enable wiring*/
  wire ce;
  assign ce = 1; 
  
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

`include "include/wbs_mmap.v"
	reg [`BUS_WIDTH-1:0] control;
	reg [`BUS_WIDTH-1:0] amp;
	reg [`BUS_WIDTH-1:0] a0;
	reg [`BUS_WIDTH-1:0] a1;
	reg [`BUS_WIDTH-1:0] a2;
	reg [`BUS_WIDTH-1:0] b1;
	reg [`BUS_WIDTH-1:0] b2;
  reg [2*`BUS_WIDTH-1:0] threshold;
  reg [7:0] pdm_clk_div_reg;
  reg [7:0] pcm_clk_div_reg;
	wire iir_valid;
	always@(posedge clk) begin
		if(rst) begin
			wbs_done <= 0;
			a0 <= 0;
			a1 <= 0;
			a2 <= 0;
			b1 <= 0;
			b2 <= 0;
      amp <= 0;
      pdm_clk_div_reg <= 8'h09;
      pcm_clk_div_reg <= 8'h65;
		end
		else begin
			wbs_done <= 0;
			if(wb_valid) begin
				case(wbs_adr_i[5:2])
					CONTROL_ADDR		: control <= wbs_dat_i;
					A0_ADDR					: a0 <= wbs_dat_i;
					A1_ADDR					: a1 <= wbs_dat_i;
					A2_ADDR					: a2 <= wbs_dat_i;
					B1_ADDR					: b1 <= wbs_dat_i;
					B2_ADDR					: b2 <= wbs_dat_i;
					AMP_ADDR				: amp <= wbs_dat_i;
					THRESHOLD_ADDR	: threshold <= wbs_dat_i;
					default:;
				endcase
				wbs_done <= 1;
			end
		end
	end 
  /*-------------------------Structural modelling ----------------------------*/
  
  /*------------------------  PDM starts   -----------------------------------*/
  
  wire mic_in;
  assign mic_in = io_in[0];
  assign io_out[1] = mclk;
  assign io_oeb[1] = 1'b1;
  wire [`BUS_WIDTH-1:0] cic_out;

  RSS0  cicmodule(clk, mclk, rst, mic_in, cic_out);

  /*------------------------   PDM ends    -----------------------------------*/
  
  /*------------------------  PCM starts   -----------------------------------*/
  
  assign pcm_reg_i = cic_out;

  REG pcm_reg(clk, rst, control[0], pcm_reg_i, pcm_reg_o);
  
  /*------------------------   PCM ends    -----------------------------------*/
  
  /*------------------------   SE starts    -----------------------------------*/
  signext se(pcm_reg_o, pcm32);
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
    .X(pcm_reg_o),
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
  
  comparator comp(maf_o, threshold, compare_ch1_out);
  
  /*------------------------   COMP ends    ----------------------------------*/
  
  /*------------------------  CLKDIV PDM starts   --------------------------------*/

  wire [7:0] pdm_clkdiv_i;
  assign pdm_clkdiv_i = pdm_clk_div_reg;
  CLOCK_DIVIDER divpdm(clk, rst, pdm_clkdiv_i, mclk);
  /*------------------------  CLOCKDIV PDM ends   --------------------------------*/

/*------------------------  CLKDIV PCM starts   --------------------------------*/
  wire [7:0] pcm_clkdiv_i;
  wire  we_pcm;
  assign pcm_clkdiv_i = pcm_clk_div_reg;
  CLOCK_DIVIDER divpcm(clk, rst, pcm_clkdiv_i, we_pcm);
  /*------------------------  CLOCKDIV PCM ends   --------------------------------*/



endmodule



