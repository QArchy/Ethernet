// Реализовать MDIO-интерфейс для конфигурации контроллера marvell:
// 1. Написать на HDL-языке конечный автомат с прогрузкой значений в PHY-контроллер Marvell
// 2. Написать на HDL эмулятор PHY-контроллера.
// 3. Создать тестовое окружение для тестирования автомата.
// 4. Проверить работоспособность на временной диаграмме и с помощью теста с самопроверкой.

module tb_mdio_top(
	inout io_mdio
);
	reg [15:0] data_0 	= 16'h1140;
	reg [15:0] data_1 	= 16'h7949; 	
	reg [15:0] data_2 	= 16'h141; 	
	reg [15:0] data_3 	= 16'hcc2; 	
	reg [15:0] data_4 	= 16'h1e1; 	
	reg [15:0] data_5 	= 16'h0; 	
	reg [15:0] data_6 	= 16'h4; 	
	reg [15:0] data_7 	= 16'h2001;	
	reg [15:0] data_8 	= 16'h0;		
	reg [15:0] data_9 	= 16'hf00; 	
	reg [15:0] data_10 	= 16'h4000; 	
	reg [15:0] data_11 	= 16'h0; 	
	reg [15:0] data_12 	= 16'h0; 	
	reg [15:0] data_13 	= 16'h0; 	
	reg [15:0] data_14 	= 16'h0; 	
	reg [15:0] data_15 	= 16'h3000; 	
	reg [15:0] data_16 	= 16'h308; 	
	reg [15:0] data_17 	= 16'h8110; 	
	reg [15:0] data_18 	= 16'h0; 	
	reg [15:0] data_19 	= 16'h10; 	
	reg [15:0] data_20 	= 16'hc60; 	
	reg [15:0] data_21 	= 16'h0; 	
	reg [15:0] data_22 	= 16'h0; 	
	reg [15:0] data_23 	= 16'h0; 	
	reg [15:0] data_24 	= 16'h4100; 	
	reg [15:0] data_25 	= 16'h0; 	
	reg [15:0] data_26 	= 16'ha; 	
	reg [15:0] data_27 	= 16'h848b; 	
	reg [15:0] data_28 	= 16'h0; 	
	reg [15:0] data_29 	= 16'h0; 	
	reg [15:0] data_30 	= 16'h0; 	
	reg [15:0] data_31 	= 16'h0;
	
	reg [15:0] data [31:0];
	initial begin
		data[0] 	<= data_0;
		data[1] 	<= data_1;
		data[2] 	<= data_2;
		data[3] 	<= data_3;
		data[4] 	<= data_4;
		data[5] 	<= data_5;
		data[6] 	<= data_6;
		data[7] 	<= data_7;
		data[8] 	<= data_8;
		data[9] 	<= data_9;
		data[10] 	<= data_10;
		data[11] 	<= data_11;
		data[12] 	<= data_12;
		data[13] 	<= data_13;
		data[14] 	<= data_14;
		data[15] 	<= data_15;
		data[16] 	<= data_16;
		data[17] 	<= data_17;
		data[18] 	<= data_18;
		data[19] 	<= data_19;
		data[20] 	<= data_20;
		data[21] 	<= data_21;
		data[22] 	<= data_22;
		data[23] 	<= data_23;
		data[24] 	<= data_24;
		data[25] 	<= data_25;
		data[26] 	<= data_26;
		data[27] 	<= data_27;
		data[28] 	<= data_28;
		data[29] 	<= data_29;
		data[30] 	<= data_30;
		data[31] 	<= data_31;
	end
	
	reg clk;
	initial clk <= 0;
	always #60 clk <= ~clk;
	
	reg reset;
	initial reset <= 0;
	
	reg same;
	initial same <= 0;
	
		// -------------- STATE MACHINE -------------- //
	parameter WRITE = 2'b00; 
	parameter IDLE 	= 2'b01;
	parameter READ	= 2'b10;
	
	reg [4:0] register_32_counter;
	initial register_32_counter <= 0;
	
	reg [1:0] state;
	initial state <= WRITE;
		// -------------- STATE MACHINE -------------- //
		
	reg rw;
	initial rw <= 0;
	
	reg [4:0] register_address;
	initial register_address <= 0;
	
	reg [31:0] cmd;
	initial cmd <= 0;
	
	reg new_cmd;
	initial new_cmd <= 0;
	
	wire 		data_written_flag;
	wire 		data_read_flag;
	wire [15:0] r_register_data;
	
	tb_mdio tb_mdio_inst(
		.i_clk(clk),
		.i_reset(reset),
		.i_new_cmd(new_cmd),
		.i_cmd(cmd),
		.o_rdy(rdy),
		.o_data_written_flag(data_written_flag),
		.o_data_read_flag(data_read_flag),
		.o_r_register_data(r_register_data),
		.io_mdio(io_mdio)
	);
	
	tb_mdio_emulator tb_mdio_emulator_inst(
		.i_clk(clk),
		.i_reset(reset),
		.io_mdio(io_mdio)
	);
	
	always @(posedge clk, posedge reset) begin /* RESET */
		if (reset) begin
			state 				<= WRITE;
			rw 					<= 0;
			register_address 	<= 0;
			register_32_counter <= 0;
			new_cmd			 	<= 0;
			cmd			 		<= 0;
		end
	end
	
	always @(posedge clk, posedge reset) begin /* WRITE */
		if (~reset && state == WRITE) begin
			if (rdy) begin
				cmd <= {data[register_32_counter], 1'b0, 1'b1, register_address[4:0], {5{1'b0}}, 1'b1, 1'b0, 1'b1, 1'b0};
				register_address <= register_address + 1;
				new_cmd <= 1;
				register_32_counter <= register_32_counter + 1;
				if (register_32_counter == 5'b11111) begin
					state 				<= READ;
					register_32_counter <= 0;
					register_address 	<= 0;
				end
			end
				else new_cmd <= 0;
		end	
	end
	
	always @(posedge clk, posedge reset) begin /* READ */
		if (~reset && state == READ) begin
			if (rdy) begin
				cmd <= {data[register_32_counter], 1'b0, 1'b1, register_address[4:0], {5{1'b0}}, 1'b0, 1'b1, 1'b1, 1'b0};
				register_address <= register_address + 1;
				new_cmd <= 1;
				register_32_counter <= register_32_counter + 1;
				same <= (r_register_data == data[register_32_counter - 1]) ? 1: 0;
				if (register_32_counter == 5'b11111) begin
					state 				<= IDLE;
					register_32_counter <= 0;
					register_address 	<= 0;
				end
			end
				else new_cmd <= 0;
		end	
	end
	
	always @(posedge clk, posedge reset) begin /* IDLE */
		if (~reset && state == IDLE) begin
			rw 					<= 0;
			register_address 	<= 0;
			register_32_counter <= 0;
			new_cmd			 	<= 0;
			cmd			 		<= 0;
		end
	end
	
endmodule