module tb_mdio_emulator(
	input 				i_clk,
	input 				i_reset,
	inout 				io_mdio
);
	reg [15:0] data [31:0];
	
	reg [4:0] register_32_counter;
	initial register_32_counter <= 0;
	
	reg [3:0] register_16_counter;
	initial register_16_counter <= 0;
	
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
	reg [31:0] 	cmd;
	initial 	cmd <= 0;
	reg [4:0] 	cmd_counter;
	initial 	cmd_counter <= 0;
	
	reg rw;
	initial rw <= 0;
	
	always @(posedge i_clk, posedge i_reset) begin /* RESET */
		if (i_reset) begin
			z 					<= 0;
			state 				<= 0;
			cmd 				<= 0;
			cmd_counter 		<= 0;
		end
	end
	
	always @(posedge i_clk, posedge i_reset) begin /* TRANSMISSION START CONDITION */
		if (~i_reset && state == 0 && register_16_counter == 0) begin
			if (mdio_in == 0) begin
				state 			 <= 1;
				cmd[cmd_counter] <= mdio_in;
				cmd_counter 	 <= cmd_counter + 1;
			end
		end
	end
	
	always @(posedge i_clk, posedge i_reset) begin /* TRANSMISSION */
		if (~i_reset && state == 1) begin
			cmd[cmd_counter] <= mdio_in;
			cmd_counter 	 <= cmd_counter + 1;
			if (cmd_counter == 5'b00011 /* 3 */)
				rw <= (cmd[cmd_counter - 1]);
			if (cmd_counter == 5'b01101 /* 13 */)
				z <= rw ? 1: 0;
			if (cmd_counter >= 5'b10000 && ~rw) begin
				data[register_32_counter][register_16_counter] 	<= mdio_in;
				register_16_counter 							<= register_16_counter + 1;
				if (register_16_counter == 4'b1111)
					register_32_counter <= register_32_counter + 1;
			end
			if (cmd_counter >= 5'b01101 && rw)
				register_16_counter <= 4'b1111;
			if (cmd_counter >= 5'b01110 && rw) begin
				mdio_out 			<= data[register_32_counter][register_16_counter];
				register_16_counter <= register_16_counter - 1;
				if (register_16_counter == 4'b0000)
					register_32_counter <= register_32_counter + 1;
			end
			if (cmd_counter == 5'b11111) begin
				state 				<= 0;
				register_16_counter <= 0;
				z 					<= 0;
			end
		end
	end
	
	
	
endmodule