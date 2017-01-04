# Machine code structure

## Registers

In pairs, 0 means segment, 1 means offset.
Combined by concatenation into 16 bit address.

```
Code pointer
    RCS
    RCO

General purpose
000 R0S
001 R0O
010 R1S
011 R1O
100 R2S
101 R2O
110 R3S
111 R3O

Stack registers
    RSS
    RSO

Flag register
    RF: Z|S|C|O|U|U|U|U
        Zero
        Sign
        Carry
        Overflow
```

## Instructions
(sorted by opcode)

```
LOAD into [RRR] by mem pointed to by [RR]
    W:  0 - 8 bit load
        1 - 16 bit load
0000 RRR|RR|W|UU

STORE from [RRR] into mem pointed to by [RR]
    W:  0 - 8 bit load
        1 - 16 bit load
0001 RRR|RR|W|UU

MOVE from [R] to [R] with transformation (changes flags)
    TT: 00 - No op (does not change flags)
        01 - Neg
        10 - Complement
        11 - <Reserved>
0010 RRR|RRR|TT

JUMP (conditional)
    CCC:000 Uncoditional long (RRR points to segment, register RRR+1 is offset)
        001 Uncoditional short
        010 If R1 == R2 | Zero
        011 If R1 < R2 | Sign
        100 If Carry
        101 If Overflow
        110 If R1 <= R2 | Sign || Zero
        111 <reserved>
0011 00CCC|RRR

STACK OPERATION
    OO: Operation
        00 PUSH [RR1] to stack
        01 POP [RR1] from stack
        10 SET RSS to RRR
        11 SET RSO to RRR
0011 010|OO|RR1

<RESERVED>
0011 011U UUUU

<RESERVED>
0011 1UUU UUUU

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

LOAD IMM into [RRR] immediate value [IMM8]
1RRR IIIIIIII
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
