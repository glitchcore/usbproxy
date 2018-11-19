
module reset_delay(iRSTN, iCLK, oRST);
input iRSTN;
input iCLK;
output reg oRST;

reg [20:0] cont;

always @(posedge iCLK or negedge iRSTN)
  if (!iRSTN) 
  begin
    cont     <= 21'b0;
    oRST     <= 1'b1;
  end
  else if (!cont[20]) 
  begin
    cont <= cont + 21'b1;
    oRST <= 1'b1;
  end
  else
    oRST <= 1'b0;
  
endmodule

module DE10_LITE_Default(

	//////////// CLOCK //////////
	input 		          		ADC_CLK_10,
	input 		          		MAX10_CLK1_50,
	input 		          		MAX10_CLK2_50,

	//////////// SDRAM //////////
	output		    [12:0]		DRAM_ADDR,
	output		    [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CKE,
	output		          		DRAM_CLK,
	output		          		DRAM_CS_N,
	inout 		    [15:0]		DRAM_DQ,
	output		          		DRAM_LDQM,
	output		          		DRAM_RAS_N,
	output		          		DRAM_UDQM,
	output		          		DRAM_WE_N,

	//////////// SEG7 //////////
	output		     [7:0]		HEX0,
	output		     [7:0]		HEX1,
	output		     [7:0]		HEX2,
	output		     [7:0]		HEX3,
	output		     [7:0]		HEX4,
	output		     [7:0]		HEX5,

	//////////// KEY //////////
	input 		     [1:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// VGA //////////
	output		     [3:0]		VGA_B,
	output		     [3:0]		VGA_G,
	output		          		VGA_HS,
	output		     [3:0]		VGA_R,
	output		          		VGA_VS,

	//////////// Accelerometer //////////
	output		          		GSENSOR_CS_N,
	input 		     [2:1]		GSENSOR_INT,
	output		          		GSENSOR_SCLK,
	inout 		          		GSENSOR_SDI,
	inout 		          		GSENSOR_SDO,

	//////////// Arduino //////////
	inout 		    [15:0]		ARDUINO_IO,
	inout 		          		ARDUINO_RESET_N,
   //////////// GPIO, GPIO connect to GPIO Default //////////
	inout 		    [35:0]		GPIO
	
);

assign DRAM_ADDR = 13'b0;
assign DRAM_BA = 2'b0;
assign DRAM_CAS_N = 0;
assign DRAM_CKE = 1'b0;
assign DRAM_CLK = 1'b0;
assign DRAM_CS_N = 1'b0;
assign DRAM_LDQM = 1'b0;
assign DRAM_RAS_N = 1'b0;
assign DRAM_UDQM = 1'b0;
assign DRAM_WE_N = 1'b0;
assign VGA_B = 4'b0;
assign VGA_G = 4'b0;
assign VGA_HS = 0;
assign VGA_R = 4'b0;
assign VGA_VS = 1'b0;
assign GSENSOR_CS_N = 1'b0;
assign GSENSOR_SCLK = 1'b0;
assign DRAM_DQ = 16'b0;
assign ARDUINO_IO[15:1] = {15{1'hz}};
assign ARDUINO_RESET_N = 0;
assign GSENSOR_SDI = 1'b0;
assign GSENSOR_SDO = 1'b0;

wire DLY_RST;

wire [23:0]	mSEG7_DIG;
wire resrt_n = KEY[0];

reset_delay	u_reset_delay	(	
	.iRSTN(resrt_n),
	.iCLK(MAX10_CLK1_50),
	.oRST(DLY_RST)
);

SEG7_LUT_6 u0 (
	.oSEG0(HEX0),
	.oSEG1(HEX1),
	.oSEG2(HEX2),
	.oSEG3(HEX3),
	.oSEG4(HEX4),
	.oSEG5(HEX5),
	.iDIG(mSEG7_DIG)
);

wire dir = SW[0];
wire out = SW[1];
wire in = ARDUINO_IO[0];
assign ARDUINO_IO[0] = dir ? out : 1'bz;
assign LEDR = resrt_n
	? {9'b0, in}
	: 10'h3ff
;



wire[63:0] debug;
wire[63:0] data;
wire[2:0] usb_state;
wire[7:0] pid;
wire host_dir;
	
Usb_proxy usb (
	.host_dm(GPIO[0]),
	.host_dp(GPIO[1]),
	
	.device_dm(GPIO[2]),
	.device_dp(GPIO[3]),
	
	.proxy_en(SW[0]),
	.is_fs(SW[1]),
	
	.clk(MAX10_CLK1_50),
	.rst(DLY_RST),
	
	.data(data),
	.usb_state(usb_state),
	.pid(pid),
	.host_dir(host_dir),
	
	.debug()
);

Keyboard_sniffer sniffer (
	.clk(MAX10_CLK1_50),
	.rst(DLY_RST),
	
	.data(data),
	.usb_state(usb_state),
	.pid(pid),
	.host_dir(host_dir),
	
	.debug(debug)
);

assign GPIO[6:4] = usb_state;
assign GPIO[7] = host_dir;
assign GPIO[35:8] = {28{1'hz}}; 

assign mSEG7_DIG = resrt_n // 
	? {debug[7:0], debug[23:16], 8'b0}
	: {6{4'b1000}}     		
;

endmodule
