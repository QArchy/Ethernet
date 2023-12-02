module tb_mdio_emulator(
	input i_clk,
	input i_reset,
	output reg o_data_written_flag,
	inout mdio_inout
);
	initial o_data_written_flag 	<= 0;
	reg o_data_read_flag;
	initial o_data_read_flag <= 0;
	
		// -------------- STATE MACHINE -------------- //
	parameter 	IDLE 				= 3'b000;
	parameter	START				= 3'b001;
	reg 		start_counter; 				initial start_counter 				<= 0;
	parameter	OPCODE				= 3'b010; // 10 - Read, 01 - Write
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
	
	// r - external device writes to this module, w - external device reads from this module
	reg rw; // r : mdio_io = 1, w : mdio_io = 0;
	initial rw <= 1;
	
	reg [15:0] reg_data [31:0];
	reg [4:0] reg_data_counter;
	initial reg_data_counter <= 0;
	
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
	
	reg [4:0] phy_address;
	initial phy_address <= 0;
	
	reg [4:0] register_address;
	initial register_address <= 0;
	
	always @(posedge i_clk) begin
		if (i_reset) begin
			w_data_bit 			<= 0;
			mdio_io 			<= 1;
			state 				<= 0;
			rw					<= 0;
			rw					<= 0;
			phy_address 		<= 0;
			register_address 	<= 0;
		end
			else begin
				case (state)
					IDLE: begin
						mdio_io <= 1;
						o_data_written_flag <= 0;
						state <= START;
					end
					START: begin
						if (~start_counter && ~r_data_bit) begin
								start_counter <= start_counter + 1;
						end
							else if (start_counter && r_data_bit) begin
									start_counter <= start_counter + 1;
									state <= OPCODE;
								end
					end
					OPCODE: begin
						if (opcode_counter) begin
							rw <= r_data_bit ? 1: 0;
							state <= PHY_ADSRESS;
						end
						opcode_counter <= opcode_counter + 1;
					end
					PHY_ADSRESS: begin
						phy_address[phy_address_counter] <= r_data_bit;
						phy_address_counter <= phy_address_counter + 1;
						if (phy_address_counter == 3'b100) begin
							phy_address_counter <= 0;
							state <= REGISTER_ADSRESS;
						end
					end
					REGISTER_ADSRESS: begin
						register_address[register_address_counter] <= r_data_bit;
						register_address_counter <= register_address_counter + 1;
						if (register_address_counter == 3'b100) begin
							register_address_counter <= 0;
							state <= TA;
							mdio_io <= rw ? 1: 0;
						end
					end
					TA: begin
						if (ta_counter)
							state <= REGISTER_DATA;
						ta_counter <= ta_counter + 1;
					end
					REGISTER_DATA: begin
						if (rw)
							reg_data[reg_data_counter][register_data_counter] <= r_data_bit;
						else
							w_data_bit <= reg_data[reg_data_counter][register_data_counter];
							
						if (register_data_counter == 0) begin
							reg_data_counter <= reg_data_counter + 1;
							state <= IDLE;
							if (rw) begin
									o_data_read_flag <= 1;
								end else begin
										o_data_written_flag <= 1;
										mdio_io <= 0;
									end
						end
						
						register_data_counter <= register_data_counter - 1;
					end
				endcase
			end
	end
	
endmodule