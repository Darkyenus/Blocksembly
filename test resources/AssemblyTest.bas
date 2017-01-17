# Count from 0 to 64 and stop
# R1 = counter
# R2 = short jump to loop
# R3 = tmp
# TODO

		LOADI R0 0
loop:   LOADI R1 1
		SUB R0 R1
		LOADI R2 loop
		JUMP IF ZERO R2

end:	LOADI W3 0xFF
		LOADI W3L 0xFF
	    JUMP LONG W3