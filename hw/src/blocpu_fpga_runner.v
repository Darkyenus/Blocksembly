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

	wire [7:0] out_output;
    wire out_output_trigger;
    reg [7:0] in_input;

	blocpu_core core (in_running, in_reset, out_running, out_reset,
						in_instruction, in_instruction_address, in_instruction_write,
						out_output, out_output_trigger, in_input);

	always @(negedge KEY[0]) begin
		in_reset = 1;
		
		//Instruction begin
		in_instruction_write = 0; in_instruction = 12'b111000000010;in_instruction_address = 16'h0; in_instruction_write = 1; #1 // LOADI R6 2
        in_instruction_write = 0; in_instruction = 12'b111100001101;in_instruction_address = 16'h1; in_instruction_write = 1; #1 // LOADI R7 13
        in_instruction_write = 0; in_instruction = 12'b001101110000;in_instruction_address = 16'h2; in_instruction_write = 1; #1 // INPUT R0
        in_instruction_write = 0; in_instruction = 12'b100100000100;in_instruction_address = 16'h3; in_instruction_write = 1; #1 // LOADI R1 4
        in_instruction_write = 0; in_instruction = 12'b001001000000;in_instruction_address = 16'h4; in_instruction_write = 1; #1 // MOVE R2 R0 None
        in_instruction_write = 0; in_instruction = 12'b010111000001;in_instruction_address = 16'h5; in_instruction_write = 1; #1 // COMBINE R0 ShiftLeft= R1
        in_instruction_write = 0; in_instruction = 12'b010011000010;in_instruction_address = 16'h6; in_instruction_write = 1; #1 // COMBINE R0 Or= R2
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h7; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b001101110000;in_instruction_address = 16'h8; in_instruction_write = 1; #1 // INPUT R0
        in_instruction_write = 0; in_instruction = 12'b100100000111;in_instruction_address = 16'h9; in_instruction_write = 1; #1 // LOADI R1 7
        in_instruction_write = 0; in_instruction = 12'b011010000001;in_instruction_address = 16'ha; in_instruction_write = 1; #1 // COMBINE R0 Compare= R1
        in_instruction_write = 0; in_instruction = 12'b001100010111;in_instruction_address = 16'hb; in_instruction_write = 1; #1 // JUMP Zero R7
        in_instruction_write = 0; in_instruction = 12'b001100001110;in_instruction_address = 16'hc; in_instruction_write = 1; #1 // JUMP Short R6
        in_instruction_write = 0; in_instruction = 12'b111011111111;in_instruction_address = 16'hd; in_instruction_write = 1; #1 // LOADI R6 255
        in_instruction_write = 0; in_instruction = 12'b111111111111;in_instruction_address = 16'he; in_instruction_write = 1; #1 // LOADI R7 255
        in_instruction_write = 0; in_instruction = 12'b001100000110;in_instruction_address = 16'hf; in_instruction_write = 1; #1 // JUMP Long R6
		//Instruction end
	end
	
	always @(negedge KEY[1]) in_running <= 1;
	
	assign LEDG[8] = out_running;
	always @(posedge out_output_trigger) LEDG[7:0] = out_output;

	assign in_input[3:0] = KEY[3:0];

endmodule