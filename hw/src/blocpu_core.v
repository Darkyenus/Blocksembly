`define log_trace if(0)$display
`define log_debug if(0)$display
`define log_error if(1)$display

`define WORD_SIZE [CPU_WIDTH-1:0]
`define DOUBLE_WORD_SIZE [CPU_WIDTH+CPU_WIDTH-1:0]
`define ADDRESS_SIZE `DOUBLE_WORD_SIZE
`define INSTRUCTION_SIZE [INSTRUCTION_WIDTH-1:0]

module blocpu_core(input in_running, input in_reset, output out_running, output out_reset, 
						input `INSTRUCTION_SIZE in_instruction, input `ADDRESS_SIZE in_instruction_address, input in_instruction_write,
						output reg `WORD_SIZE out_output, output reg out_output_trigger,
						input `WORD_SIZE in_input);

	parameter CPU_WIDTH = 8;
	parameter INSTRUCTION_WIDTH = 12;
	parameter MEMORY_WIDTH = 16;
	
	parameter CLOCK_RATE = 10;
	
	reg `INSTRUCTION_SIZE instruction_memory [(1 << (CPU_WIDTH + CPU_WIDTH))-1:0];
	reg `WORD_SIZE data_memory [(1 << (CPU_WIDTH + CPU_WIDTH))-1:0];

	// Registers
	// Instruction pointer
	reg `ADDRESS_SIZE IP;
	// General purpose
	reg `WORD_SIZE RG [7:0];
	// Stack
	reg `ADDRESS_SIZE RS;
	// Segment
    reg `WORD_SIZE RSE;
	// Flag
	reg `WORD_SIZE RF;

	// Internal
	reg clock;
	reg running;
	reg reset;

	always @(posedge in_running) running = in_running;
	always @(posedge in_reset) reset = in_reset;
	assign out_running = running;
	assign out_reset = reset;

	// Used to throw away values, see CMP
	reg `WORD_SIZE black_hole;

	// Reset
	always @(posedge reset)begin
		`log_trace("Initializing core");
		running <= 0;
		clock <= 0;
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
		RSE <= 0;
		RS <= 0;
		RF <= 0;
	end
	
	//Programming
	always @(posedge in_instruction_write) begin
		`log_debug("PGM instruction_memory[%X] = %X", in_instruction_address, in_instruction);
		instruction_memory[in_instruction_address] <= in_instruction;
	end

	function [CPU_WIDTH-1:0] flagUpdate;
		input `WORD_SIZE value;

		begin
			RF[0] = value == 0 ? 1'b1 : 1'b0;
			RF[1] = value[CPU_WIDTH-1];
			RF[CPU_WIDTH-1:2] = 1'b0; //Zero rest
         
			flagUpdate = value;
		end
	endfunction

	function `WORD_SIZE flagAdd;
		input `WORD_SIZE op1;
		input `WORD_SIZE op2;
		input carry;

		reg [CPU_WIDTH:0] full_result;

		begin
			full_result = {op1[CPU_WIDTH-1], op1} + {op1[CPU_WIDTH-1], op2} + carry;
			RF[0] = full_result == 1'b0 ? 1'b1 : 1'b0;
			RF[1] = full_result[CPU_WIDTH-1];
			RF[2] = full_result[CPU_WIDTH];
			//TODO Overflow
			
			flagAdd = full_result[CPU_WIDTH-1:0];
		end
	endfunction

	function `WORD_SIZE flagSub;
        input `WORD_SIZE op1;
        input `WORD_SIZE op2;
        input borrow;

		reg [CPU_WIDTH:0] full_result;

        begin
            full_result = {op1[CPU_WIDTH-1], op1} - {op1[CPU_WIDTH-1], op2} - borrow;
            RF[0] = full_result == 1'b0 ? 1'b1 : 1'b0;
            RF[1] = full_result[CPU_WIDTH-1];
            RF[2] = full_result[CPU_WIDTH];
            //TODO Overflow?
				
            flagSub = full_result[CPU_WIDTH-1:0];
        end
    endfunction

	always #(CLOCK_RATE/2)
		begin
			clock <= ~clock;
			`log_trace("Clock: %X", clock);
		end

	//Current instruction
	wire `INSTRUCTION_SIZE c_inst;
	assign c_inst = instruction_memory[IP];

	always @(posedge clock)
		if (running) begin
			`log_trace("                             OP %X at %X", c_inst, IP);
			`log_trace("                             R0: %X R1: %X R2: %X R3: %X R4: %X R5: %X R6: %X R7: %X", RG[0], RG[1], RG[2], RG[3], RG[4], RG[5], RG[6], RG[7]);
			`log_trace("                             RS+1: %X RS: %X RS-1: %X RS-2: %X", data_memory[RS+1], data_memory[RS], data_memory[RS-1], data_memory[RS-2]);

			if (c_inst[11:8] == 4'b0000) begin
				// LOAD
				if (c_inst[1] == 0) begin
					// 8 bit
					`log_debug("LOAD 8bit R%X <= %X", c_inst[7:5], data_memory[{RSE, RG[c_inst[4:2]]}]);
					RG[c_inst[7:5]] <= data_memory[{RSE, RG[c_inst[4:2]]}];
				end else begin
					// 16 bit
					`log_debug("LOAD 16bit R%X <= %X, %X", c_inst[7:5], data_memory[{RSE, RG[c_inst[4:2]]}], data_memory[{RSE, RG[c_inst[4:2]+1]}]);
					RG[c_inst[7:5]] <= data_memory[{RSE, RG[c_inst[4:2]]}];
					RG[c_inst[7:5]+1] <= data_memory[{RSE, RG[c_inst[4:2]+1]}];
				end
				IP <= toDWord(IP + 1);
			end

			else if (c_inst[11:8] == 4'b0001) begin
				// STORE

				`define S8_TA1 {RSE, RG[c_inst[7:5]]}
                `define S8_TM1 data_memory[`S8_TA1]
                `define S8_SA1 (c_inst[4:2])
                `define S8_SR1 RG[`S8_SA1]

                `define S8_TA2 {RSE, toWord(RG[c_inst[7:5]] + 1)}
                `define S8_TM2 data_memory[`S8_TA2]
                `define S8_SA2 (c_inst[4:2]+1)
                `define S8_SR2 RG[`S8_SA2]

				if (c_inst[1] == 0) begin
                    // 8 bit
                    `log_debug("STORE8 %X@%X <= %X@R%X", `S8_TM1, `S8_TA1, `S8_SR1, `S8_SA1);
                    `S8_TM1 <= `S8_SR1;
                end else begin
                    // 16 bit
                    `log_debug("STORE16 (%X,%X)@(%Xm%X) <= (%X,%X)@(R%X,R%X)", `S8_TM1, `S8_TM2, `S8_TA1, `S8_TA2, `S8_SR1, `S8_SR2, `S8_SA1, `S8_SA2);
                    `S8_TM1 <= `S8_SR1;
                    `S8_TM2 <= `S8_SR2;
                end

                `undef S8_TA1
                `undef S8_TA2
                `undef S8_TM1
                `undef S8_TM2
                `undef S8_SA1
                `undef S8_SA2
                `undef S8_SR1
                `undef S8_SR2

                IP <= toDWord(IP + 1);
			end

			else if (c_inst[11:8] == 4'b0010) begin
				// MOVE
				if (c_inst[1:0] == 2'b00) begin
					RG[c_inst[7:5]] <= RG[c_inst[4:2]];
				end
				else if (c_inst[1:0] == 2'b00) begin
                    RG[c_inst[7:5]] <= flagUpdate(~RG[c_inst[4:2]]);
                end
				else if (c_inst[1:0] == 2'b00) begin
                    RG[c_inst[7:5]] <= flagUpdate(-RG[c_inst[4:2]]);
                end
				else if (c_inst[1:0] == 2'b11) begin
					`log_error("Illegal MOV transformation 11 at %X", IP);
                    RG[c_inst[7:5]] <= RG[c_inst[4:2]];
                end
                IP <= toDWord(IP + 1);
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
                        IP <= toDWord(IP + 1);
                end
				else if (c_inst[5:3] == 3'b011) begin
                    // If SIGN
                    if (RF[1] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= toDWord(IP + 1);
                end
				else if (c_inst[5:3] == 3'b100) begin
                    // If CARRY
                    if (RF[2] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= toDWord(IP + 1);
                end
				else if (c_inst[5:3] == 3'b101) begin
                    // If Overflow
                    if (RF[3] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= toDWord(IP + 1);
                end
				else if (c_inst[5:3] == 3'b011) begin
                    // If Sign or Zero
                    if (RF[0] == 1 || RF[0] == 1)
                        IP[CPU_WIDTH-1:0] <= RG[c_inst[2:0]];
                    else
                        IP <= toDWord(IP + 1);
                end
				else if (c_inst[5:3] == 3'b011) begin
                    // Unconditional CALL
                    data_memory[toDWord(RS-1)] <= IP[15:8];
                    data_memory[toDWord(RS-2)] <= IP[7:0];
                    RS <= toDWord(RS - 2);
                    IP <= {RG[c_inst[2:0]], RG[c_inst[2:0] + 1]};
                end
            end

			else if (c_inst[11:5] == 7'b0011010) begin
                // STACK OP
                if (c_inst[4:3] == 2'b00) begin
                    // PUSH
                    `log_debug("PUSH %X (from %X) (RS: %X)", RG[c_inst[2:0]], c_inst[2:0], toDWord(RS-1));
                    data_memory[toDWord(RS-1)] <= RG[c_inst[2:0]];
                    RS <= toDWord(RS - 1);
                    IP <= toDWord(IP + 1);
                end
				else if (c_inst[4:3] == 2'b01) begin
                    // POP
                    `log_debug("POP %X (to %X) (RS: %X)", data_memory[RS], c_inst[2:0], RS);
                    RG[c_inst[2:0]] <= data_memory[RS];
                    RS <= toDWord(RS + 1);
                    IP <= toDWord(IP + 1);
                end
				else if (c_inst[4:3] == 2'b10) begin
                    // INIT STACK POINTER
                    `log_debug("INIT STACK POINTER TO %X from %X", {RG[c_inst[2:0]], RG[c_inst[2:0]+1]}, c_inst[2:0]);
                    RS <= {RG[c_inst[2:0]], RG[c_inst[2:0]+1]};
                    IP <= toDWord(IP + 1);
                end
				else if (c_inst[4:3] == 2'b11) begin
                    // INIT SEGMENT POINTER
                    `log_debug("INIT SEGMENT POINTER TO %X from %X", {RG[c_inst[2:0]], RG[c_inst[2:0]+1]}, c_inst[2:0]);
                    RSE <= RG[c_inst[2:0]];
                    IP <= toDWord(IP + 1);
                end
            end

			else if (c_inst[11:4] == 8'b00110110) begin
                // RETURN
                `log_debug("RETURN %X (to %X)", c_inst[3:0], {data_memory[RS+1], data_memory[RS]});
                IP <= {data_memory[RS+1], data_memory[RS]};
                RS <= toDWord(RS + 2 + c_inst[3:0]);
            end

            else if (c_inst[11:3] == 9'b001101111) begin
                // OUTPUT
                `log_debug("OUTPUT: %X", RG[c_inst[2:0]]);
				out_output <= RG[c_inst[2:0]];
				out_output_trigger <= 1;
				//TODO Turn off the trigger properly?
				#1
				out_output_trigger <= 0;

				IP <= toDWord(IP + 1);
            end

            else if (c_inst[11:3] == 9'b001101110) begin
                // INPUT
                `log_debug("INPUT: %X", in_input);
                RG[c_inst[2:0]] <= in_input;

                IP <= toDWord(IP + 1);
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
                    `log_error("Invalid combine parameter %X at %X", c_inst[9:6], IP);
                end
                IP <= toDWord(IP + 1);
            end

			else if (c_inst[11:11] == 1'b1) begin
                // LOAD IMM8
                `log_debug("LOADI %X '%X'", c_inst[10:8], c_inst[7:0]);
                RG[c_inst[10:8]] <= c_inst[7:0];

                IP <= toDWord(IP + 1);
            end

            else begin
                `log_error("Invalid instruction %X at %X", c_inst, IP);
                $dumpfile("test.vcd");
                $dumpvars(0, blocpu_core);
                running <= 0;
                IP <= toDWord(IP + 1);
            end

		end //end main loop

	//Utility functions

	function `WORD_SIZE toWord;
		input [63:0] i;
		begin
			toWord = i`WORD_SIZE;
		end
	endfunction

	function `DOUBLE_WORD_SIZE toDWord;
        input [63:0] i;
        begin
            toDWord = i`DOUBLE_WORD_SIZE;
        end
    endfunction

endmodule
