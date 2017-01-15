`define log_trace if(0)$display
`define log_debug if(0)$display
`define log_output if(1)$display

module blocpu_core();

	parameter CPU_WIDTH = 8;
	parameter INSTRUCTION_WIDTH = CPU_WIDTH + 4;
	parameter MEMORY_SIZE = (1 << CPU_WIDTH) - 1;
	
	parameter CLOCK_RATE = 10;
	
	reg [INSTRUCTION_WIDTH-1:0] instruction_memory [MEMORY_SIZE:0];
	reg [CPU_WIDTH-1:0] ram [MEMORY_SIZE:0];
	
	reg [CPU_WIDTH-1:0] register;
	reg [CPU_WIDTH-1:0] instruction_pointer;
	reg [CPU_WIDTH-1:0] extension_register;
	
	reg clock;
	reg running;
	reg reset;
	reg [CPU_WIDTH-1:0] exit_code;

	reg [CPU_WIDTH-1:0] system_output;

	always @(posedge reset)begin
		`log_trace("Initializing core");
		running <= 0;
		exit_code <= 0;
		clock <= 0;
		instruction_pointer <= 0;
		system_output <= 0;
		reset <= 0;
	end

	// Simulation only, not reliable
	initial begin
		reset <= 1;
	end

	always #(CLOCK_RATE/2) clock <= ~clock;

	wire [INSTRUCTION_WIDTH-1:0] current_instruction;
	wire [2:0] current_opcode;
	wire [CPU_WIDTH-1:0] current_arg;

	assign current_instruction = instruction_memory[instruction_pointer];
	assign #1 current_opcode = current_instruction[INSTRUCTION_WIDTH-1:INSTRUCTION_WIDTH-3];
	assign #1 current_arg = current_instruction[INSTRUCTION_WIDTH-4] ? current_instruction[CPU_WIDTH-1:0] : ram[current_instruction[CPU_WIDTH-1:0]];

	always @(posedge clock)
		if (running) begin
			#2 //Wait for instruction to load

			`log_trace("                             OP %H %H at %H", current_opcode, current_arg, instruction_pointer);

			if (current_opcode == 3'b000) begin
				`log_debug("LOAD %h", current_arg);
				register <= current_arg;
				instruction_pointer <= instruction_pointer + 1;

			end else if (current_opcode == 3'b001) begin
				`log_debug("JUMP %h", current_arg);
                instruction_pointer <= current_arg;

			end else if (current_opcode == 3'b010) begin
                `log_debug("IF %h", current_arg);
				if (current_arg === register) begin
					instruction_pointer <= instruction_pointer + 2;
				end else begin
					instruction_pointer <= instruction_pointer + 1;
				end

			end else if (current_opcode == 3'b011) begin
            				`log_debug("STORE %h", current_arg);
            				ram[current_arg] <= register;
            				instruction_pointer <= instruction_pointer + 1;

            end else if (current_opcode == 3'b100) begin
                `log_debug("ADD %h", current_arg);
                register <= register + current_arg;
				instruction_pointer <= instruction_pointer + 1;

            end else if (current_opcode == 3'b101) begin
				`log_debug("SUB %h", current_arg);
                register <= register - current_arg;
				instruction_pointer <= instruction_pointer + 1;

			end else if (current_opcode == 3'b110) begin
                `log_debug("EXTENSION %h", current_arg);

                if (extension_register == 0) begin
                    `log_output("\t\t\t\t\tOUT: %h", register);
                    system_output <= current_arg;
                end else if (extension_register == 1) begin
                    running <= 0;
                    exit_code <= current_arg;
                end
                instruction_pointer <= instruction_pointer + 1;

            end else if (current_opcode == 3'b111) begin
                `log_debug("SELECT %h", current_arg);
                if (current_arg === 8'b000) begin
                    //DEBUG
                    extension_register <= 0;
                end else if (current_arg === 8'b10011) begin
					//EXIT NOW
					running <= 0;
					exit_code <= 0;
                end else if (current_arg === 8'b10100) begin
                    //SELECT EXIT
                    extension_register <= 1;
                    running <= 0;
                    exit_code <= 0;
				end
				instruction_pointer <= instruction_pointer + 1;

			end

		end

endmodule 