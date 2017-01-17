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
		
		/*core.instruction_memory[0] = 12'b0100000101010;
		core.instruction_memory[1] = 12'b0100100000001;
		core.instruction_memory[2] = 12'b0010001000001;
		core.instruction_memory[3] = 12'b0101000000001;
		core.instruction_memory[4] = 12'b0001100010010;
		core.instruction_memory[5] = 12'b0111011111111;
		core.instruction_memory[6] = 12'b0111111111111;
		core.instruction_memory[7] = 12'b0001100000110;*/
	end
	
	always @(negedge KEY[1]) in_running <= 1;
	
	assign LEDG[0] = out_running;

endmodule