// Реализовать MDIO-интерфейс для конфигурации контроллера marvell:
// 1. Написать на HDL-языке конечный автомат с прогрузкой значений в PHY-контроллер Marvell
// 2. Написать на HDL эмулятор PHY-контроллера.
// 3. Создать тестовое окружение для тестирования автомата.
// 4. Проверить работоспособность на временной диаграмме и с помощью теста с самопроверкой.

module tb_mdio_top(
	output reg same,
	inout mdio_inout
);
	reg clk;
	initial clk <= 0;
	always #60 clk <= ~clk;
	
	reg reset;
	initial reset <= 0;
	//always #100000 reset <= ~reset;
	
		// -------------- STATE MACHINE -------------- //
	parameter INIT 	= 2'b00; reg [5:0] init_counter; initial init_counter <= 0;
	parameter IDLE 	= 2'b01;
	parameter WRITE = 2'b10;
	parameter READ	= 2'b11;
	
	reg [1:0] state;
	initial state <= INIT;
		// -------------- STATE MACHINE -------------- //
	
	reg rw;
	initial rw <= 0;
	
	reg [4:0] phy_address;
	initial phy_address <= 0;
	
	reg [4:0] register_address;
	initial register_address <= 0;
	
	reg [15:0] w_register_data;
	initial w_register_data <= 0;
	
	wire 		data_written_flag;
	wire [15:0] r_register_data;
	wire 		data_read_flag;
	
	tb_mdio tb_mdio_inst(
		.i_clk(clk),
		.i_reset(reset),
		.i_rw(rw),
		.i_phy_address(phy_address),
		.i_register_address(register_address),
		.i_w_register_data(w_register_data),
		.o_data_written_flag(data_written_flag),
		.o_r_register_data(r_register_data),
		.o_data_read_flag(data_read_flag),
		.mdio_inout(mdio_inout)
	);
	
	wire data32_written_flag;
	
	tb_mdio_emulator tb_mdio_emulator_inst(
		.i_clk(clk),
		.i_reset(reset),
		.o_data_written_flag(data32_written_flag),
		.mdio_inout(mdio_inout)
	);
	
	always @(posedge clk) begin
		if (reset) begin
			state <= INIT;
			rw <= 0;
			register_address <= 0;
			w_register_data <= 0;
		end
			else begin
					case (state)
						INIT: begin
							case (init_counter)
								0:  begin 
									w_register_data <= 16'h1140;
								end
								1:  w_register_data <= 16'h7949;
								2:  w_register_data <= 16'h141;
								3:  w_register_data <= 16'hcc2;
								4:  w_register_data <= 16'h1e1;
								5:  w_register_data <= 16'h0;
								6:  w_register_data <= 16'h4;
								7:  w_register_data <= 16'h2001;
								8:  w_register_data <= 16'h0;
								9:  w_register_data <= 16'hf00;
								10: w_register_data <= 16'h4000;
								11: w_register_data <= 16'h0;
								12: w_register_data <= 16'h0;
								13: w_register_data <= 16'h0;
								14: w_register_data <= 16'h0;
								15: w_register_data <= 16'h3000;
								16: w_register_data <= 16'h308;
								17: w_register_data <= 16'h8110;
								18: w_register_data <= 16'h0;
								19: w_register_data <= 16'h10;
								20: w_register_data <= 16'hc60;
								21: w_register_data <= 16'h0;
								22: w_register_data <= 16'h0;
								23: w_register_data <= 16'h0;
								24: w_register_data <= 16'h4100;
								25: w_register_data <= 16'h0;
								26: w_register_data <= 16'ha;
								27: w_register_data <= 16'h848b;
								28: w_register_data <= 16'h0;
								29: w_register_data <= 16'h0;
								30: w_register_data <= 16'h0;
								31: w_register_data <= 16'h0;
							endcase
							if (data_written_flag) begin
								if (init_counter == 0) begin
										$display("#------------------------#") ;
										$display("#------ TEST START ------#") ;
										$display("#------ TEST WRITE ------#") ;
										$display("#------------------------#") ;
									end
								init_counter <= init_counter + 1;
								register_address <= register_address + 1;
								$display("written 16'h%h to 5'h%h address of MDIO", w_register_data, register_address) ;
							end
							if (data_written_flag && (init_counter == 5'b11111)) begin
								register_address <= 0;
								init_counter <= 0;
								rw <= 1;
								state <= READ;
							end
						end
						IDLE: begin
							
						end
						WRITE: begin
							
						end
						READ: begin
							if (data32_written_flag) begin
								if (data_read_flag) begin
									init_counter <= init_counter + 1;
									register_address <= register_address + 1;
									case (init_counter)
										0:  same <= (r_register_data == 16'h1140) 	? 1: 0;
										1:  same <= (r_register_data == 16'h7949) 	? 1: 0;
										2:  same <= (r_register_data == 16'h141) 	? 1: 0;
										3:  same <= (r_register_data == 16'hcc2) 	? 1: 0;
										4:  same <= (r_register_data == 16'h1e1) 	? 1: 0;
										5:  same <= (r_register_data == 16'h0) 		? 1: 0;
										6:  same <= (r_register_data == 16'h4) 		? 1: 0;
										7:  same <= (r_register_data == 16'h2001) 	? 1: 0;
										8:  same <= (r_register_data == 16'h0) 		? 1: 0;
										9:  same <= (r_register_data == 16'hf00) 	? 1: 0;
										10: same <= (r_register_data == 16'h4000) 	? 1: 0;
										11: same <= (r_register_data == 16'h0) 		? 1: 0;
										12: same <= (r_register_data == 16'h0) 		? 1: 0;
										13: same <= (r_register_data == 16'h0) 		? 1: 0;
										14: same <= (r_register_data == 16'h0) 		? 1: 0;
										15: same <= (r_register_data == 16'h3000) 	? 1: 0;
										16: same <= (r_register_data == 16'h308) 	? 1: 0;
										17: same <= (r_register_data == 16'h8110) 	? 1: 0;
										18: same <= (r_register_data == 16'h0) 		? 1: 0;
										19: same <= (r_register_data == 16'h10) 	? 1: 0;
										20: same <= (r_register_data == 16'hc60) 	? 1: 0;
										21: same <= (r_register_data == 16'h0) 		? 1: 0;
										22: same <= (r_register_data == 16'h0) 		? 1: 0;
										23: same <= (r_register_data == 16'h0) 		? 1: 0;
										24: same <= (r_register_data == 16'h4100) 	? 1: 0;
										25: same <= (r_register_data == 16'h0) 		? 1: 0;
										26: same <= (r_register_data == 16'ha) 		? 1: 0;
										27: same <= (r_register_data == 16'h848b) 	? 1: 0;
										28: same <= (r_register_data == 16'h0) 		? 1: 0;
										29: same <= (r_register_data == 16'h0) 		? 1: 0;
										30: same <= (r_register_data == 16'h0) 		? 1: 0;
										31: same <= (r_register_data == 16'h0) 		? 1: 0;
									endcase
								end
								if (data_read_flag && (init_counter == 5'b11111)) begin
									register_address <= 0;
									init_counter <= 0;
									rw <= 0;
									state <= IDLE;
									$stop;
								end
							end
						end
					endcase
				end
	end
	
endmodule