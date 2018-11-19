enum bit[7:0] {
	OUT_Token = 8'b11110101,
	IN_Token = 8'b10001101,
	SOF_Token = 8'b11001001,
	SETUP_Token = 8'b10110001,
	DATA0 = 8'b11101011,
	DATA1 = 8'b10010011,
	DATA2 = 8'b11010111,
	MDATA = 8'b10101111,
	ACK = 8'b11100100,
	NAK = 8'b10011100,
	STALL = 8'b10100000,
	NYET = 8'b11011000,
	ERR = 8'b10111110,
	Split = 8'b10000010,
	Ping = 8'b11000110
} PID;

module Usb_proxy (
	inout host_dm, host_dp, device_dm, device_dp,
	input clk, rst, is_fs, proxy_en,
	output[13:0] debug,
	output reg[63:0] data,
	output reg[2:0] usb_state,
	output reg[7:0] pid,
	output host_dir
);

wire host_usb_data = is_fs ? (~host_dp & host_dm) : (host_dp & ~host_dm);
wire host_se0 = ~host_dp & ~host_dm;

wire device_usb_data = is_fs ? (~device_dp & device_dm) : (device_dp & ~device_dm);
wire device_se0 = ~device_dp & ~device_dm;

reg _device_dir;
reg _host_dir;

wire device_dir = proxy_en ? _device_dir : 1'b0;
assign host_dir = proxy_en ? _host_dir : 1'b1;

wire usb_data = (device_dir && host_dir) ? device_usb_data | host_usb_data :
	(device_dir ? device_usb_data :
	(host_dir ? host_usb_data : 1'b0));

wire se0 = (device_dir && host_dir) ? device_se0 | host_se0 :
	(device_dir ? device_se0 :
	(host_dir ? host_se0 : 1'b0));
	
wire usb_dp = is_fs ? (~se0 & ~usb_data) : (~se0 & usb_data);
wire usb_dm = is_fs ? (~se0 & usb_data) : (~se0 & ~usb_data);

assign device_dp = device_dir ? 1'bz : usb_dp;
assign device_dm = device_dir ? 1'bz : usb_dm;

assign host_dp = host_dir ? 1'bz : usb_dp;
assign host_dm = host_dir ? 1'bz : usb_dm;

reg [5:0] usb_clk_cnt;

reg [3:0] usb_clk_ls_cnt;

wire usb_clk_fs = usb_clk_cnt[1];
wire usb_clk_ls= usb_clk_ls_cnt[3];

wire usb_clk = (usb_state == 0) ? clk : (is_fs ? usb_clk_fs : usb_clk_ls);

always@ (posedge clk) begin
	if(usb_state == 0) begin
		usb_clk_cnt <= 0;
		usb_clk_ls_cnt <= 0;
	end else begin
		if(usb_clk_cnt > 48) begin 
			usb_clk_cnt <= 0;
		end else begin
			usb_clk_cnt <= usb_clk_cnt + 6'd1;
		end
	end
	
	if(usb_clk_cnt[1]) usb_clk_ls_cnt <= usb_clk_ls_cnt + 4'd1;
end

reg[7:0] usbreg;
reg[7:0] prev_pid;

reg nrzi_prev;

reg[7:0] usb_cnt;

wire[7:0] usbreg_next = usbreg | (usb_data << usb_cnt);

always@ (posedge usb_clk) begin
	if(rst == 1) begin
		usbreg <= 0;
		usb_cnt <= 0;
		_device_dir <= 0;
		_host_dir <= 1;
		nrzi_prev <= 0;
		
	end else if (usb_state == 0) begin		
		if(usb_data) begin
			if(device_dir && ~device_usb_data) _device_dir <= 0;
			if(device_dir && device_usb_data) _host_dir <= 0;
			
			usb_state <= 1;
			
			usb_cnt <= 0;
			usbreg <= 0;
			pid <= 0;
		end;
		
	end else if (usb_state == 1) begin
		
		// fill preamble register
		usbreg <= usbreg_next;
		usb_cnt <= usb_cnt + 8'd1;
		
		if(usb_cnt == 7 && usbreg_next == 8'b11010101) begin
			usb_state <= 2;
			
			usb_cnt <= 0;
			usbreg <= 0;
		end;
		
	end else if (usb_state == 2) begin
		
		usbreg <= usbreg_next;
		usb_cnt <= usb_cnt + 8'd1;
		
		if(usb_cnt == 7) begin
			usb_state <= 3;
			
			usb_cnt <= 0;
			usbreg <= 0;
			
			pid <= usbreg_next;
			prev_pid <= pid;
			
			nrzi_prev <= usb_data;
			data <= 0;
		end;
		
	end else if (usb_state == 3) begin
		nrzi_prev <= usb_data;
		if(~(nrzi_prev ^ usb_data)) data <= data | 1 << usb_cnt;
		if(usb_cnt < 64) usb_cnt <= usb_cnt + 8'd1;
		
	end else if (usb_state == 4) begin
		usb_cnt <= usb_cnt + 8'd1;
		if(usb_cnt > 1) begin
			usb_state <= 0;
			
			if(device_dir == 1) _device_dir <= 0;
			else
			if(pid == IN_Token || ((pid == DATA0 || pid == DATA1) && prev_pid != IN_Token)) _device_dir <= 1;
			
			_host_dir <= 1;
		end
	end
	
	if(se0 == 1 && usb_state != 0 && usb_state != 4) begin
		usb_state <= 4;
		
		usb_cnt <= 0;
		usbreg <= 0;
	end
end

assign debug[0] = usb_data;
assign debug[1] = se0;
assign debug[2] = 0;
assign debug[3] = device_dir;
assign debug[4] = host_dir;
assign debug[5] = usb_state[0];
assign debug[6] = usb_state[1];
assign debug[7] = usb_state[2];

assign debug[13:8] = {6{1'b0}};

endmodule