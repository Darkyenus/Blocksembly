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

module blocpu_runner;

	blocpu_core core ();

	initial begin
		$display("Begin");
        core.reset = 1;

		core.instruction_memory[0] = 12'b0100000101010;
        core.instruction_memory[1] = 12'b0100100000001;
        core.instruction_memory[2] = 12'b0010001000001;
        core.instruction_memory[3] = 12'b0101000000001;
        core.instruction_memory[4] = 12'b0001100010010;
        core.instruction_memory[5] = 12'b0111011111111;
        core.instruction_memory[6] = 12'b0111111111111;
        core.instruction_memory[7] = 12'b0001100000110;

		#5
		$display("Running = 1");
		core.running = 1;

		@(negedge core.running)
		$finish;
	end

endmodule