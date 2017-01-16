`define log_trace if(1)$display
`define log_debug if(1)$display
`define log_output if(1)$display

`define WORD_SIZE [CPU_WIDTH-1:0]
`define DOUBLE_WORD_SIZE [CPU_WIDTH+CPU_WIDTH-1:0]
`define ADDRESS_SIZE `DOUBLE_WORD_SIZE

module blocpu_core();

	parameter CPU_WIDTH = 8;
	parameter INSTRUCTION_WIDTH = 12;
	parameter MEMORY_HIGH = (1 << (CPU_WIDTH+CPU_WIDTH)) - 1;
	
	parameter CLOCK_RATE = 10;
	
	reg [INSTRUCTION_WIDTH-1:0] instruction_memory [MEMORY_HIGH:0];
	reg [CPU_WIDTH-1:0] data_memory [MEMORY_HIGH:0];

	// Registers
	// Instruction pointer
	reg `ADDRESS_SIZE IP;
	// General purpose
	reg `WORD_SIZE RG [7:0];
	// Stack
	reg `ADDRESS_SIZE RS;
	// Flag
	reg `WORD_SIZE RF;

	// Internal
	reg clock;
	reg running;
	reg reset;
	reg `WORD_SIZE exit_code;

	// Used to throw away values, see CMP
	reg `WORD_SIZE black_hole;

	// Out
	reg `WORD_SIZE system_output;

	// Reset
	always @(posedge reset)begin
		`log_trace("Initializing core");
		running <= 0;
		exit_code <= 0;
		clock <= 0;
		system_output <= 0;
		reset <= 0;

		//Registers
		IP <= 0;
		RG[0] <= 0;
		RG[1] <= 0;
		RG[2] <= 0;
		RG[3] <= 0;
		RG[4] <= 0;
		RG[5] <= 0;
		RG[6] <= 0;
		RG[7] <= 0;
		RS <= 0;
		RF <= 0;
	end

	function flagUpdate;
		input `WORD_SIZE value;

		begin
			RF[0] = value == 0 ? 1 : 0;
			RF[1] = value[CPU_WIDTH-1];
			RF[CPU_WIDTH-1:2] = 0; //Zero rest
            flagUpdate = value;
		end
	endfunction

	function flagAdd;
		input `WORD_SIZE op1;
		input `WORD_SIZE op2;
		input carry;

		reg [CPU_WIDTH:0] full_result;

		begin
			full_result = {op1[CPU_WIDTH-1], op1} + {op1[CPU_WIDTH-1], op2} + carry;
			RF[0] = full_result == 0 ? 1 : 0;
			RF[1] = full_result[CPU_WIDTH-1];
			RF[2] = full_result[CPU_WIDTH];
			//TODO Overflow
			flagAdd = full_result[CPU_WIDTH-1:0];
		end
	endfunction

	function flagSub;
        input `WORD_SIZE op1;
        input `WORD_SIZE op2;
        input borrow;

		reg [CPU_WIDTH:0] full_result;

        begin
            full_result = {op1[CPU_WIDTH-1], op1} - {op1[CPU_WIDTH-1], op2} - borrow;
            RF[0] = full_result == 0 ? 1 : 0;
            RF[1] = full_result[CPU_WIDTH-1];
            RF[2] = full_result[CPU_WIDTH];
            //TODO Overflow?
            flagSub = full_result[CPU_WIDTH-1:0];
        end
    endfunction

	always #(CLOCK_RATE/2)
		begin
			clock <= ~clock;
			//`log_trace("Clock: %H", clock);
		end

	//Current instruction
	wire [INSTRUCTION_WIDTH-1:0] c_inst;
	assign c_inst = instruction_memory[IP];

	always @(posedge clock)
		if (running) begin
			`log_trace("                             OP %H at %H", c_inst, IP);

			if (c_inst[11:8] == 4'b0000) begin
				// LOAD
				if (c_inst[1] == 0) begin
					// 8 bit
					`log_debug("LOAD 8bit R%H <= %H", c_inst[7:5], data_memory[RG[c_inst[4:2]]]);
					RG[c_inst[7:5]] <= data_memory[RG[c_inst[4:2]]];
				end else begin
					// 16 bit
					`log_debug("LOAD 16bit R%H <= %H, %H", c_inst[7:5], data_memory[RG[c_inst[4:2]]], data_memory[RG[c_inst[4:2]] + 1]);
					RG[c_inst[7:5]] <= data_memory[RG[c_inst[4:2]]];
					RG[c_inst[7:5]+1] <= data_memory[RG[c_inst[4:2]] + 1];
				end
				IP <= IP + 1;
			end

			else if (c_inst[11:8] == 4'b0001) begin
				// STORE
				if (c_inst[1] == 0) begin
                    // 8 bit
                    `log_debug("STORE 8bit R%H => %H", c_inst[7:5], data_memory[RG[c_inst[4:2]]]);
                    data_memory[RG[c_inst[4:2]]] <= RG[c_inst[7:5]];
                end else begin
                    // 16 bit
                    `log_debug("STORE 16bit R%H => %H, %H", c_inst[7:5], data_memory[RG[c_inst[4:2]]], data_memory[RG[c_inst[4:2]] + 1]);
                    data_memory[RG[c_inst[4:2]]] <= RG[c_inst[7:5]];
                    data_memory[RG[c_inst[4:2]] + 1] <= RG[c_inst[7:5]+1];
                end
                IP <= IP + 1;
			end

			else if (c_inst[11:8] == 4'b0010) begin
				// MOVE
				if (c_inst[1:0] == 2'b00) begin
					RG[c_inst[7:5]] <= RG[c_inst[4:3]];
				end
				else if (c_inst[1:0] == 2'b00) begin
                    RG[c_inst[7:5]] <= flagUpdate(~RG[c_inst[4:3]]);
                end
				else if (c_inst[1:0] == 2'b00) begin
                    RG[c_inst[7:5]] <= flagUpdate(-RG[c_inst[4:3]]);
                end
				else if (c_inst[1:0] == 2'b11) begin
					`log_debug("Illegal MOV transformation 11 at %H", IP);
                    RG[c_inst[7:5]] <= RG[c_inst[4:3]];
                end
                IP <= IP + 1;
			end

			else if (c_inst[11:6] == 6'b001100) begin
                // JUMP
                if (c_inst[5:3] == 3'b000) begin
                    // Long unconditional
                    if ({RG[c_inst[2:0]], RG[c_inst[2:0] + 1]} == 16'hFFFF) begin
                        running <= 0;
                    end else begin
                        IP <= {RG[c_inst[2:0]], RG[c_inst[2:0] + 1]};
                    end
                end
                else if (c_inst[5:3] == 3'b001) begin
                    // Short unconditional
                    IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                end
                else if (c_inst[5:3] == 3'b010) begin
                    // If ZERO
                    if (RF[0] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= IP + 1;
                end
				else if (c_inst[5:3] == 3'b011) begin
                    // If SIGN
                    if (RF[1] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= IP + 1;
                end
				else if (c_inst[5:3] == 3'b100) begin
                    // If CARRY
                    if (RF[2] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= IP + 1;
                end
				else if (c_inst[5:3] == 3'b101) begin
                    // If Overflow
                    if (RF[3] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= IP + 1;
                end
				else if (c_inst[5:3] == 3'b011) begin
                    // If Sign or Zero
                    if (RF[0] == 1 || RF[0] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= IP + 1;
                end
				else if (c_inst[5:3] == 3'b011) begin
                    // Unconditional CALL
                    data_memory[RS-1] <= IP[15:8];
                    data_memory[RS-2] <= IP[7:0];
                    RS <= RS - 2;
                    IP <= {RG[c_inst[2:0]], RG[c_inst[2:0] + 1]};
                end
            end

			else if (c_inst[11:5] == 7'b0011010) begin
                // STACK OP
                if (c_inst[4:3] == 2'b00) begin
                    // PUSH
                    data_memory[RS-1] <= RG[c_inst[2:0]];
                    RS <= RS - 1;
                    IP <= IP + 1;
                end
				else if (c_inst[4:3] == 2'b01) begin
                    // POP
                    RG[c_inst[2:0]] <= data_memory[RS];
                    RS <= RS + 1;
                    IP <= IP + 1;
                end
				else if (c_inst[4:3] == 2'b10) begin
                    // INIT STACK POINTER
                    RS <= {RG[c_inst[2:0]], RG[c_inst[2:0]+1]};
                    IP <= IP + 1;
                end
				else if (c_inst[4:3] == 2'b11) begin
                    // <reserved>
                    `log_debug("Illegal stack operation 11 at %H", IP);
                    IP <= IP + 1;
                end
            end

			else if (c_inst[11:4] == 8'b00110110) begin
                // RETURN
                IP <= {data_memory[RS+1], data_memory[RS]};
                RS <= RS + 2 + c_inst[3:0];
            end

			else if (c_inst[11:10] == 2'b01) begin
                // COMBINE
                if (c_inst[9:6] == 4'b0000) begin
                    // ADD
                    RG[c_inst[5:3]] <= flagAdd(RG[c_inst[5:3]], RG[c_inst[2:0]], 0);
                end
                else if (c_inst[9:6] == 4'b0001) begin
                    // SUBTRACT
                    RG[c_inst[5:3]] <= flagSub(RG[c_inst[5:3]], RG[c_inst[2:0]], 0);
                end
                else if (c_inst[9:6] == 4'b0010) begin
                    // AND
                    RG[c_inst[5:3]] <= flagUpdate(RG[c_inst[5:3]] & RG[c_inst[2:0]]);
                end
                else if (c_inst[9:6] == 4'b0011) begin
                    // OR
                    RG[c_inst[5:3]] <= flagUpdate(RG[c_inst[5:3]] | RG[c_inst[2:0]]);
                end
                else if (c_inst[9:6] == 4'b0100) begin
                    // XOR
                    RG[c_inst[5:3]] <= flagUpdate(RG[c_inst[5:3]] ^ RG[c_inst[2:0]]);
                end
                else if (c_inst[9:6] == 4'b0101) begin
                    // ADD with carry
                    RG[c_inst[5:3]] <= flagAdd(RG[c_inst[5:3]], RG[c_inst[2:0]], RF[2]);
                end
                else if (c_inst[9:6] == 4'b0110) begin
                    // SUB with borrow
                    RG[c_inst[5:3]] <= flagSub(RG[c_inst[5:3]], RG[c_inst[2:0]], RF[2]);
                end
                else if (c_inst[9:6] == 4'b0111) begin
                    // SHIFT LEFT
                    RG[c_inst[5:3]] <= flagUpdate(RG[c_inst[5:3]] << RG[c_inst[2:0]]);
                end
                else if (c_inst[9:6] == 4'b1000) begin
                    // SHIFT RIGHT
                    RG[c_inst[5:3]] <= flagUpdate(RG[c_inst[5:3]] >> RG[c_inst[2:0]]);
                end
                else if (c_inst[9:6] == 4'b1001) begin
                    // SHIFT RIGHT with sign fill
                    RG[c_inst[5:3]] <= flagUpdate(RG[c_inst[5:3]] >>> RG[c_inst[2:0]]);
                end
                else if (c_inst[9:6] == 4'b1010) begin
                    // COMPARE
                    black_hole <= flagSub(RG[c_inst[5:3]], RG[c_inst[2:0]], 0);
                end
                else begin
                    `log_debug("Invalid combine parameter %H at %H", c_inst[9:6], IP);
                end
                IP <= IP + 1;
            end

			else if (c_inst[11:11] == 1'b1) begin
                // LOAD IMM8
                RG[c_inst[10:8]] <= c_inst[7:0];

                IP <= IP + 1;
            end

            else begin
                `log_debug("Invalid instruction %H at %H", c_inst, IP);
                IP <= IP + 1;
            end

		end //end main loop

endmodule 