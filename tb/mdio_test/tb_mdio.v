module tb_mdio(
	input 				i_clk,
	input 				i_reset,
	input 				i_new_cmd,
	input 		[31:0] 	i_cmd,
	output reg			o_rdy,
	output reg			o_data_written_flag,
	output reg	 		o_data_read_flag,
	output reg 	[15:0] 	o_r_register_data,
	inout 				io_mdio
);
	initial o_rdy				<= 1;
	initial o_data_written_flag	<= 0;
	initial o_data_read_flag	<= 0;
	initial o_r_register_data	<= 0;
	
	/* --------- INOUT PATH --------- */
	reg z;
	initial z <= 0;
	
	wire mdio_in;				// read line
	assign mdio_in = io_mdio;
	
	reg mdio_out;				// write line
	initial mdio_out <= 0;
	
	assign io_mdio = z ? mdio_out: 1'bZ;
	/* --------- INOUT PATH --------- */
	
	reg 		state;
	initial 	state <= 0;
	reg 		set_rdy;
	initial 	set_rdy <= 0;
	reg [4:0] 	cmd_counter;
	initial 	cmd_counter <= 0;
	
	always @(posedge i_clk, posedge i_reset) begin /* RESET */
		if (i_reset) begin
			z 					<= 0;
			o_data_written_flag <= 0;
			o_data_read_flag 	<= 0;
			o_r_register_data 	<= 0;
			state 				<= 0;
			cmd_counter 		<= 0;
		end
	end
	
	always @(posedge i_clk, posedge i_reset) begin /* TRANSMISSION START CONDITION (RESET OUTPUT) */
		if (~i_reset) begin
			if (set_rdy) begin
				set_rdy <= 0;
				z 		<= 0;
				o_rdy 	<= 1;
			end
				else o_rdy <= 0;
			if (i_new_cmd && state != 1)
				state <= 1'b1;
			if (~state) begin
				o_data_written_flag <= 0;
				o_data_read_flag 	<= 0;
				o_r_register_data 	<= 0;
			end
		end
	end
	
	always @(posedge i_clk, posedge i_reset) begin /* TRANSMISSION */
		if (~i_reset && state) begin
			case (i_cmd[3])
				0: begin /* READ */
					z <= (cmd_counter >= 5'b01101 /* 13 */) ? 0: 1;
					if (cmd_counter >= 5'b10000 /* 16 */) begin
						o_r_register_data[14:0] <= o_r_register_data[15:1];
						o_r_register_data[15] 	<= mdio_in;
					end
				end
				1: begin /* WRITE */
					z <= 1;
				end
			endcase
			mdio_out <= i_cmd[cmd_counter];
		end
	end
	
	always @(posedge i_clk, posedge i_reset) begin /* TRANSMISSION END CONDITION (SET OUTPUT) */
		if (~i_reset && state) begin
			if (cmd_counter == 5'b11111 /* 31 */) begin
				if (i_cmd[3]) 
					o_data_written_flag <= 1;
				else 
					o_data_read_flag <= 1;
				state 	<= 0;
				set_rdy <= 1;
			end
			cmd_counter <= cmd_counter + 1;
		end
	end
	
endmodule