# While button 1 is not pressed, output button 2

	LOADI R6 loop
	LOADI R7 end

loop:
	# Create output pattern
	INPUT R0
	LOADI R1 4
	MOV R2 R0
	SHL R0 R1
	OR R0 R2
	# And show it
	OUTPUT R0

	# Look at what is pressed
	INPUT R0
	LOADI R1 0b111
	CMP R0 R1
	JUMP IF ZERO R7
	JUMP R6

end:
	LOADI W3 0xFF
	LOADI W3L 0xFF
    JUMP LONG W3


