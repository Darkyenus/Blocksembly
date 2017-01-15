module blocpu_runner;

	blocpu_core core ();

	initial begin
		$display("Begin");
        core.reset = 1;

		core.instruction_memory[0] = 12'b100000000000;
		core.instruction_memory[1] = 12'b001100000000;
		core.instruction_memory[2] = 12'b111100000000;
		core.instruction_memory[3] = 12'b110000000000;
		core.instruction_memory[4] = 12'b100100000001;
		core.instruction_memory[5] = 12'b010100001010;
		core.instruction_memory[6] = 12'b001100000001;
		core.instruction_memory[7] = 12'b111100010011;

		#5
		$display("Running = 1");
		core.running = 1;

		@(negedge core.running)
		$finish;
	end

endmodule