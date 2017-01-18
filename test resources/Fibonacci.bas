# Compute first few fibonacci numbers

# R0 - F1
# R1 - F2
# R2 - F3 (tmp)
# R3 - Limit = 100
# R4 - Jump to nextFib

	LOADI R0 1
	LOADI R1 1
	LOADI R3 100
	LOADI R4 nextFib

nextFib:
	OUTPUT R1
	MOV R2 R0
	ADD R2 R1
	MOV R0 R1
	MOV R1 R2

	# Check if end (is number bigger than 100?)
	CMP R1 R3
	JUMP IF SIGN R4

	# Else, end
	LOADI W0 0xFF
	LOADI W0L 0xFF
	JUMP LONG W0
