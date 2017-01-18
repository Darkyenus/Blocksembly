# Count from 0 to 64 and stop
# R1 = counter
# R2 = 64
# R3 = short jump to end
# R4 = short jump to loop
# R5 = 1


		# Init
		LOADI R0 0
		LOADI R1 64
		LOADI R3 end
		LOADI R4 loop
		LOADI R5 1

loop:	# Is 64?
		CMP R0 R1
		JUMP IF ZERO R3

		# It is not
		ADD R0 R5
		JUMP R4

end:    # End, halt
		LOADI W3 0xFF
		LOADI W3L 0xFF
	    JUMP LONG W3