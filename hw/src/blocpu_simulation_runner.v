module blocpu_runner;

	reg in_running;
    reg in_reset;
    wire out_running;
    wire out_reset;
    reg [11:0] in_instruction;
    reg [15:0] in_instruction_address;
    reg in_instruction_write;

    blocpu_core core (in_running, in_reset, out_running, out_reset, in_instruction, in_instruction_address, in_instruction_write);

	initial begin
		$display("Begin");
        core.reset = 1;

		in_instruction_write = 0;
        in_instruction = 12'b100000000000;
        in_instruction_address = 0;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b100101000000;
        in_instruction_address = 1;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b101100001001;
        in_instruction_address = 2;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b110000000101;
        in_instruction_address = 3;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b110100000001;
        in_instruction_address = 4;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b011010000001;
        in_instruction_address = 5;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b001100010011;
        in_instruction_address = 6;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b010000000101;
        in_instruction_address = 7;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b001100001100;
        in_instruction_address = 8;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b111011111111;
        in_instruction_address = 9;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b111111111111;
        in_instruction_address = 10;
        in_instruction_write = 1;
        #1

        in_instruction_write = 0;
        in_instruction = 12'b001100000110;
        in_instruction_address = 11;
        in_instruction_write = 1;
        #1

		#5
		$display("Running = 1");
		core.running = 1;

		@(negedge core.running)
		$finish;
	end

endmodule