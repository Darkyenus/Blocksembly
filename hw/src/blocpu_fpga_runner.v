module serialGPIO(
	    input clk,
	    input RxD,
	    output TxD,

	    output reg [7:0] GPout,  // general purpose outputs
	    input [7:0] GPin  // general purpose inputs
	);

	wire RxD_data_ready;
	wire [7:0] RxD_data;

	async_receiver RX(.clk(clk), .RxD(RxD), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
	always @(posedge clk) if(RxD_data_ready) GPout <= RxD_data;

	async_transmitter TX(.clk(clk), .TxD(TxD), .TxD_start(RxD_data_ready), .TxD_data(GPin));
endmodule

module blocpu_fpga_runner(
		CLK,
		KEY,
		SW,
		LEDG,
		LEDR,
		HEX0
		);
		
	input CLK;
	input	[3:0]	KEY;
	input	[17:0]	SW;
	output [8:0]	LEDG;
	output [17:0]	LEDR;
	output [6:0] HEX0;

	reg in_running;
	reg in_reset;
	wire out_running;
	wire out_reset;
	reg [11:0] in_instruction;
	reg [15:0] in_instruction_address;
	reg in_instruction_write;

	blocpu_core core (in_running, in_reset, out_running, out_reset, in_instruction, in_instruction_address, in_instruction_write);

	always @(negedge KEY[0]) begin
		in_reset = 1;
		
		in_instruction_write = 0;
        in_instruction = 12'b100000000000;
        in_instruction_address = 0;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b100101000000;
        in_instruction_address = 1;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b101100001001;
        in_instruction_address = 2;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b110000000101;
        in_instruction_address = 3;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b110100000001;
        in_instruction_address = 4;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b011010000001;
        in_instruction_address = 5;
        in_instruction_write = 1;

        in_instruction_write = 0;
        in_instruction = 12'b001100010011;
        in_instruction_address = 6;
        in_instruction_write = 1;

        in_instruction_write = 0;
        in_instruction = 12'b010000000101;
        in_instruction_address = 7;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b001100001100;
        in_instruction_address = 8;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b111011111111;
        in_instruction_address = 9;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b111111111111;
        in_instruction_address = 10;
        in_instruction_write = 1;
        in_instruction_write = 0;
        in_instruction = 12'b001100000110;
        in_instruction_address = 11;
        in_instruction_write = 1;
	end
	
	always @(negedge KEY[1]) in_running <= 1;
	
	assign LEDG[0] = out_running;

endmodule