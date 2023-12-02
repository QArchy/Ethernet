module tb_mdio_data_controller(
	input 		i_mdio_clk_mdc, 	// max 8.3 MHz
	input 		i_reset,			// reset
	input 		i_w_data_bit,		// new data bit
	input 		i_mdio_io,			// io pick
	output reg 	o_r_data_bit,		// input buffer
	inout 		mdio_inout			// data
);
	wire mdio_in;
	assign mdio_in = mdio_inout;
	
	assign mdio_inout = i_mdio_io ? 1'bZ: i_w_data_bit;
	initial o_r_data_bit <= 0;
	
	always @(posedge i_mdio_clk_mdc) begin
		if (i_reset) begin
			o_r_data_bit <= 0;
		end else begin
			if (i_mdio_io)
					o_r_data_bit <= mdio_in;
				else
					o_r_data_bit <= 0;
		end
	end
	
endmodule