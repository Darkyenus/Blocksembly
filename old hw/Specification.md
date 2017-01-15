# Memory model
 - One 8-bit register
 - Memory: 256 bytes

# Instructions
Format:
```
OOOBDDDDDDDD
 | |  \-> 8 bits of argument
 | \-> 1 bit about nature of data. 1 = argument value is literal, 0 = argument value is ram[argument]
 \-> 3 bit instruction code
```

 - 000 LOAD
    - Transfer data from arg to register
 - 001 JUMP
    - Unconditional jump to arg
 - 010 ADD
    - Add arg to register
 - 011 SUBTRACT
    - Subtract arg from register
 - 100 IF
    - If arg and register equals, skip next instruction
 - 101 SELECT
    - Select extension unit/invoke extension
 - 110 STORE
    - Transfer data from register to address at arg
 - 111 EXTENSION
    - Send arg to extension unit