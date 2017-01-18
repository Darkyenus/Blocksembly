module blocpu_runner;

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

	always @(posedge out_output_trigger) begin
		$display("Got output: 0x%X %d", out_output, out_output);
		in_input <= ~out_output;
	end

	initial begin
		$display("Begin");
        core.reset = 1;

		in_instruction_write = 0; in_instruction = 12'b100111001010;in_instruction_address = 16'h0; in_instruction_write = 1; #1 // LOADI R1 202
        in_instruction_write = 0; in_instruction = 12'b101011111110;in_instruction_address = 16'h1; in_instruction_write = 1; #1 // LOADI R2 254
        in_instruction_write = 0; in_instruction = 12'b101110111010;in_instruction_address = 16'h2; in_instruction_write = 1; #1 // LOADI R3 186
        in_instruction_write = 0; in_instruction = 12'b110010111110;in_instruction_address = 16'h3; in_instruction_write = 1; #1 // LOADI R4 190
        in_instruction_write = 0; in_instruction = 12'b100000000000;in_instruction_address = 16'h4; in_instruction_write = 1; #1 // LOADI R0 0
        in_instruction_write = 0; in_instruction = 12'b000100100000;in_instruction_address = 16'h5; in_instruction_write = 1; #1 // STORE R1 R0
        in_instruction_write = 0; in_instruction = 12'b100000000001;in_instruction_address = 16'h6; in_instruction_write = 1; #1 // LOADI R0 1
        in_instruction_write = 0; in_instruction = 12'b000101000000;in_instruction_address = 16'h7; in_instruction_write = 1; #1 // STORE R2 R0
        in_instruction_write = 0; in_instruction = 12'b100000000010;in_instruction_address = 16'h8; in_instruction_write = 1; #1 // LOADI R0 2
        in_instruction_write = 0; in_instruction = 12'b000101100010;in_instruction_address = 16'h9; in_instruction_write = 1; #1 // STORE R3 R0 WIDE
        in_instruction_write = 0; in_instruction = 12'b100001000010;in_instruction_address = 16'ha; in_instruction_write = 1; #1 // LOADI R0 66
        in_instruction_write = 0; in_instruction = 12'b100101000010;in_instruction_address = 16'hb; in_instruction_write = 1; #1 // LOADI R1 66
        in_instruction_write = 0; in_instruction = 12'b101001000010;in_instruction_address = 16'hc; in_instruction_write = 1; #1 // LOADI R2 66
        in_instruction_write = 0; in_instruction = 12'b101101000010;in_instruction_address = 16'hd; in_instruction_write = 1; #1 // LOADI R3 66
        in_instruction_write = 0; in_instruction = 12'b110001000010;in_instruction_address = 16'he; in_instruction_write = 1; #1 // LOADI R4 66
        in_instruction_write = 0; in_instruction = 12'b110101000010;in_instruction_address = 16'hf; in_instruction_write = 1; #1 // LOADI R5 66
        in_instruction_write = 0; in_instruction = 12'b111001000010;in_instruction_address = 16'h10; in_instruction_write = 1; #1 // LOADI R6 66
        in_instruction_write = 0; in_instruction = 12'b111101000010;in_instruction_address = 16'h11; in_instruction_write = 1; #1 // LOADI R7 66
        in_instruction_write = 0; in_instruction = 12'b100000000000;in_instruction_address = 16'h12; in_instruction_write = 1; #1 // LOADI R0 0
        in_instruction_write = 0; in_instruction = 12'b000000100000;in_instruction_address = 16'h13; in_instruction_write = 1; #1 // LOAD R1 R0
        in_instruction_write = 0; in_instruction = 12'b001101111001;in_instruction_address = 16'h14; in_instruction_write = 1; #1 // OUTPUT R1
        in_instruction_write = 0; in_instruction = 12'b100000000001;in_instruction_address = 16'h15; in_instruction_write = 1; #1 // LOADI R0 1
        in_instruction_write = 0; in_instruction = 12'b000000100000;in_instruction_address = 16'h16; in_instruction_write = 1; #1 // LOAD R1 R0
        in_instruction_write = 0; in_instruction = 12'b001101111001;in_instruction_address = 16'h17; in_instruction_write = 1; #1 // OUTPUT R1
        in_instruction_write = 0; in_instruction = 12'b100000000010;in_instruction_address = 16'h18; in_instruction_write = 1; #1 // LOADI R0 2
        in_instruction_write = 0; in_instruction = 12'b000000100000;in_instruction_address = 16'h19; in_instruction_write = 1; #1 // LOAD R1 R0
        in_instruction_write = 0; in_instruction = 12'b001101111001;in_instruction_address = 16'h1a; in_instruction_write = 1; #1 // OUTPUT R1
        in_instruction_write = 0; in_instruction = 12'b100000000011;in_instruction_address = 16'h1b; in_instruction_write = 1; #1 // LOADI R0 3
        in_instruction_write = 0; in_instruction = 12'b000000100000;in_instruction_address = 16'h1c; in_instruction_write = 1; #1 // LOAD R1 R0
        in_instruction_write = 0; in_instruction = 12'b001101111001;in_instruction_address = 16'h1d; in_instruction_write = 1; #1 // OUTPUT R1
        in_instruction_write = 0; in_instruction = 12'b100001000010;in_instruction_address = 16'h1e; in_instruction_write = 1; #1 // LOADI R0 66
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h1f; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h20; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h21; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b100000000001;in_instruction_address = 16'h22; in_instruction_write = 1; #1 // LOADI R0 1
        in_instruction_write = 0; in_instruction = 12'b001101000000;in_instruction_address = 16'h23; in_instruction_write = 1; #1 // Push R0
        in_instruction_write = 0; in_instruction = 12'b100000000010;in_instruction_address = 16'h24; in_instruction_write = 1; #1 // LOADI R0 2
        in_instruction_write = 0; in_instruction = 12'b001101000000;in_instruction_address = 16'h25; in_instruction_write = 1; #1 // Push R0
        in_instruction_write = 0; in_instruction = 12'b100000000011;in_instruction_address = 16'h26; in_instruction_write = 1; #1 // LOADI R0 3
        in_instruction_write = 0; in_instruction = 12'b001101000000;in_instruction_address = 16'h27; in_instruction_write = 1; #1 // Push R0
        in_instruction_write = 0; in_instruction = 12'b100000000100;in_instruction_address = 16'h28; in_instruction_write = 1; #1 // LOADI R0 4
        in_instruction_write = 0; in_instruction = 12'b001101000000;in_instruction_address = 16'h29; in_instruction_write = 1; #1 // Push R0
        in_instruction_write = 0; in_instruction = 12'b100000000101;in_instruction_address = 16'h2a; in_instruction_write = 1; #1 // LOADI R0 5
        in_instruction_write = 0; in_instruction = 12'b001101000000;in_instruction_address = 16'h2b; in_instruction_write = 1; #1 // Push R0
        in_instruction_write = 0; in_instruction = 12'b100000000110;in_instruction_address = 16'h2c; in_instruction_write = 1; #1 // LOADI R0 6
        in_instruction_write = 0; in_instruction = 12'b001101000000;in_instruction_address = 16'h2d; in_instruction_write = 1; #1 // Push R0
        in_instruction_write = 0; in_instruction = 12'b001101001000;in_instruction_address = 16'h2e; in_instruction_write = 1; #1 // Pop R0
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h2f; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b001101001000;in_instruction_address = 16'h30; in_instruction_write = 1; #1 // Pop R0
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h31; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b001101001000;in_instruction_address = 16'h32; in_instruction_write = 1; #1 // Pop R0
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h33; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b001101001000;in_instruction_address = 16'h34; in_instruction_write = 1; #1 // Pop R0
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h35; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b001101001000;in_instruction_address = 16'h36; in_instruction_write = 1; #1 // Pop R0
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h37; in_instruction_write = 1; #1 // OUTPUT R0
        in_instruction_write = 0; in_instruction = 12'b001101001000;in_instruction_address = 16'h38; in_instruction_write = 1; #1 // Pop R0
        in_instruction_write = 0; in_instruction = 12'b001101111000;in_instruction_address = 16'h39; in_instruction_write = 1; #1 // OUTPUT R0

		#5
		$display("Running = 1");
		core.running = 1;

		@(negedge core.running)
		$finish;
	end

endmodule