module tb_mdio(
	input 				i_clk,
	input 				i_reset,
	input 				i_rw,
	input 		[4:0] 	i_phy_address,
	input 		[4:0] 	i_register_address,
	input 		[15:0] 	i_w_register_data,
	output reg			o_data_written_flag,
	output reg 	[15:0] 	o_r_register_data,
	output reg 			o_data_read_flag,
	inout 				mdio_inout
);
	initial o_data_written_flag 	<= 0;
	initial o_r_register_data 		<= 0;
	initial o_data_read_flag 		<= 0;
	
		// -------------- STATE MACHINE -------------- //
	parameter 	IDLE 				= 3'b000;
	parameter	START				= 3'b001;
	reg 		start_counter; 				initial start_counter 				<= 0;
	parameter	OPCODE_WRITE		= 3'b010; // 10 - Read, 01 - Write
	reg 	 	opcode_counter; 			initial opcode_counter 				<= 0;
	parameter	PHY_ADSRESS			= 3'b011;
	reg [2:0] 	phy_address_counter; 		initial phy_address_counter 		<= 0;
	parameter	REGISTER_ADSRESS	= 3'b100;
	reg [2:0] 	register_address_counter; 	initial register_address_counter 	<= 0;
	parameter	TA					= 3'b101; // z0 - Read, 10 - Write
	reg 	 	ta_counter; 				initial ta_counter					<= 1;
	parameter	REGISTER_DATA		= 3'b110;
	reg [3:0] 	register_data_counter; 		initial register_data_counter 		<= 4'b1111;
	
	reg [2:0] state;
	initial state <= IDLE;
		// -------------- STATE MACHINE -------------- //
	
	reg w_data_bit;
	initial w_data_bit <= 0;
	
	reg mdio_io;
	initial mdio_io <= 1;
	
	wire r_data_bit;
	
	tb_mdio_data_controller tb_mdio_data_controller_inst(
		.i_mdio_clk_mdc(i_clk), 	// max 8.3 MHz
		.i_reset(i_reset),			// reset
		.i_w_data_bit(w_data_bit),	// new data bit
		.i_mdio_io(mdio_io),		// io pick
		.o_r_data_bit(r_data_bit), 	// input buffer
		.mdio_inout(mdio_inout)		// data
	);
	
	always @(posedge i_clk) begin
		if (i_reset) begin
			w_data_bit 	<= 0;
			mdio_io 	<= 0;
			state 		<= 0;
		end
			else begin
				case (state)
					IDLE: begin
						if (mdio_io == 1) begin
							mdio_io <= 0;
							o_data_written_flag <= 0;
							o_data_read_flag <= 0;
							state <= START;
						end else begin
								if (i_rw)
									o_data_read_flag <= 1;
								else
									o_data_written_flag <= 1;
								w_data_bit <= 0;
								mdio_io <= 1;
							end
					end
					START: begin
						if (!start_counter) begin
							mdio_io <= 0;
							w_data_bit <= 0;
						end
							else begin
									w_data_bit <= 1;
									state <= OPCODE_WRITE;
								end
						start_counter <= start_counter + 1;
					end
					OPCODE_WRITE: begin
						if (!opcode_counter) begin
							w_data_bit <= i_rw ? 1: 0;
						end
							else begin
									w_data_bit <= i_rw ? 0: 1;
									state <= PHY_ADSRESS;
								end
						opcode_counter <= opcode_counter + 1;
					end
					PHY_ADSRESS: begin
						w_data_bit <= i_phy_address[phy_address_counter];
						phy_address_counter <= phy_address_counter + 1;
						if (phy_address_counter == 3'b100) begin
							phy_address_counter <= 0;
							state <= REGISTER_ADSRESS;
						end
					end
					REGISTER_ADSRESS: begin
						w_data_bit <= i_register_address[register_address_counter];
						register_address_counter <= register_address_counter + 1;
						if (register_address_counter == 3'b100) begin
							register_address_counter <= 0;
							state <= TA;
							if (i_rw) begin
								mdio_io <= 1;
						end
					end
					TA: begin
						if (i_rw) begin
							if (ta_counter)
								state <= REGISTER_DATA;
						end
							else begin
									if (!ta_counter) begin
										w_data_bit <= 1;
									end
										else begin
												w_data_bit <= 0;
												state <= REGISTER_DATA;
											end
								end
						ta_counter <= ta_counter + 1;
					end
					REGISTER_DATA: begin
						if (i_rw)
							o_r_register_data[register_data_counter] <= r_data_bit;
						else
							w_data_bit <= i_w_register_data[register_data_counter];
							
						if (register_data_counter == 0) begin
							if (i_rw)
								mdio_io <= 0;
							state <= IDLE;
						end
						
						register_data_counter <= register_data_counter - 1;
					end
				endcase
			end
	end
	
endmodule