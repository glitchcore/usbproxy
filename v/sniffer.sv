module Keyboard_sniffer(
	input clk, rst,
	
	input [63:0] data,
	input[2:0] usb_state,
	input[7:0] pid,
	input host_dir,
	
	output[7:0] modifier,
	output[7:0] keycode,
	output reg[3:0] leds,
	
	output[3:0] debug
);

assign debug[3:1] = 3'b0;

reg[63:0] keyboard_data;

assign modifier = keyboard_data[7:0];
assign keycode =  keyboard_data[23:16];

reg led_data;

always@ (posedge clk) begin
	if(rst) begin
		led_data <= 0;
		leds <= 0;
	end else begin
	
		if(usb_state == 4) begin
			
			if(pid == DATA0 || pid == DATA1) begin
				if(led_data) leds <= data[3:0];
				else keyboard_data <= data;
			end
			
			if(pid == OUT_Token && data[10:7] == 4'b0) led_data <= 1;
			else led_data <= 0;
			
		end
	end
end

assign debug[0] = led_data;


endmodule
