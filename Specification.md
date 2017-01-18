# Machine code structure

## Registers

In pairs, 0 means segment, 1 means offset.
Combined by concatenation into 16 bit address.

```
Instruction pointer
    RCS
    RCO

General purpose
000 R0S (RG0)
001 R0O (RG1)
010 R1S (RG2)
011 R1O (RG3)
100 R2S (RG4)
101 R2O (RG5)
110 R3S (RG6)
111 R3O (RG7)

Stack registers
    RSS
    RSO

Segment register
    RSE

Flag register
    RF: U|U|U|U|O|C|S|Z
        Zero
        Sign
        Carry
        Overflow
```

## Instructions
(sorted by opcode)

```
LOAD into [R1R] by mem pointed to by [R2R] in segment RSE
    W:  0 - 8 bit load
        1 - 16 bit load
0000 R1R|R2R|W|U
    LOAD8 RRR RRO
    LOAD16 RRR RRO

STORE from [R1R] into mem pointed to by [R2R] in segment RSE
    W:  0 - 8 bit load
        1 - 16 bit load
0001 R1R|R2R|W|U
    STORE8 RRR RRO
    STORE16 RRR RRO

MOVE to [R1R] from [R2R] with transformation (changes flags)
    TT: 00 - No op (does not change flags)
        01 - Neg
        10 - Complement
        11 - <Reserved>
0010 R1R|R2R|TT
    MOVE RRR [-,~]RRR

JUMP (conditional)
    CCC:000 Uncoditional long (RRR points to segment, register RRR+1 is offset) - Jump to FF:FF means HALT
        001 Uncoditional short
        010 If R1 == R2 | Zero
        011 If R1 < R2 | Sign
        100 If Carry
        101 If Overflow
        110 If R1 <= R2 | Sign || Zero
        111 Call (like long jump), push return address on stack
0011 00|CCC|RRR
    JUMP [LONG] RRR
    JUMP [IF Z|S|C|O|SZ] RRR
    CALL RRR

STACK OPERATION
    OO: Operation
        00 PUSH [RRR] to stack
        01 POP [RRR] from stack
        10 SET RSS to RRR, RSO to RRR+1
        11 SET RSE to RRR
0011 010|OO|RRR
    PUSH RRR
    POP RRR
    STACK_INIT RRR
    SEGMENT_INIT RRR

RETURN, pop return address (2B, segment+offset), and also pop AAAA (IMM4) bytes from stack (arguments)
0011 0110|AAAA
    RETURN [AAAA]

<RESERVED FOR IO>
0011 0111|O|RRR

<RESERVED>
0011 1UUUUUUU

COMBINE from [R1] and [R2] to [R1] (changes flags)
    0000 - ADD: R1 = R1 + R2
    0001 - SUB: R1 = R1 - R2
    0010 - AND
    0011 - OR
    0100 - XOR
    0101 - ADD WITH CARRY
    0110 - SUB WITH BORROW
    0111 - SHIFT LEFT
    1000 - SHIFT RIGHT
    1001 - SHIFT RIGHT WITH SIGNFILL
    1010 - COMPARE: R1 - R2
    1011 - <reserved>
    1100 - <reserved>
    1101 - <reserved>
    1110 - <reserved>
    1111 - <reserved>
01TT TT|RR1|RR2
    ADD RRR RRR
    SUB RRR RRR
    AND RRR RRR
    OR RRR RRR
    XOR RRR RRR
    ADC RRR RRR
    SBB RRR RRR
    SHL RRR RRR
    SHR RRR RRR
    SRS RRR RRR
    CMP RRR RRR

LOAD IMM into [RRR] immediate value [IMM8]
1RRR IIIIIIII
    LOADI RRR IIIIIIII
```

## High level
C-like

```
<program> := <top-declaration>*

<top-declaration> := <variable-declaration>
                   | <function-declaration>

<variable-declaration> := "val" <identifier> ":" <type> ["=" <expression (const)>] ";"

<type> := "s8" | "u8" | "s16" | "u16" | "bool"

<identifier> := r"[a-zA-Z_][a-zA-Z_0-9]*" //Like Java

<function-declaration> := "fun" <identifier> [":" <type>] "(" [<identifier> ":" <type> ["," <type> <identifier>]*] ")"
                            "{" <statement>* "}"

<statement> := <variable-declaration>
             | <assignment>
             | <if-statement>
             | <while-statement>
             | <function-call-statement>

<assignment> := <identifier> "=" <expression> ";"

<if-statement> := "if" "(" <expression> ")" "{" <statement>* "}" ["else" ("{" <statement> "}" | <if-statement>)]

<while-statement> := "while" "(" <expression> ")" "{" <statement>* "}"

<function-call-statement> := <function-call> ";"

<function-call> := <identifier> "(" [<expression> ["," <expression>]*] ")"

<expression> := <constant>
              | <identifier>
              | <unary-operator> <expression>
              | <expression> <binary-operator> <expression>
              | "(" <expression> ")"
              | <function-call>

<constant> := r"[0-9_]+"
            | r"0x[0-9a-fA-F_]+"
            | r"0b[01_]+"
            | "true" | "false"
            //Not specified for clarity: _ may not be first nor last character, octal is not supported, so leading zeros are permitted

<unary-operator> := "+" | "-" | "~"

<binary-operator> := "+" | "-" | "|" | "&" | "^" | "||" | "&&" | "<<" | ">>" | ">>>"

```
