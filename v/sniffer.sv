module Keyboard_sniffer(
	input clk, rst,
	
	input [63:0] data,
	input[2:0] usb_state,
	input[7:0] pid,
	input host_dir,
	
	output reg[63:0] debug
);


always@ (posedge clk) begin
	if((pid == DATA0 || pid == DATA1) && usb_state == 4) begin
		debug <= data;
	end
end


endmodule
