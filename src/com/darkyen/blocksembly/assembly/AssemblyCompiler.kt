package com.darkyen.blocksembly.assembly

import com.darkyen.blocksembly.AbstractParser

/*
 *
 */

enum class GeneralRegister(val wideName:String? = null) {
    R0("W0"),
    R1("W0L"),
    R2("W1"),
    R3("W1L"),
    R4("W2"),
    R5("W2L"),
    R6("W3"),
    R7("W3L");

    override fun toString(): String {
        return name
    }
}

abstract class MachineOperation {
    var sourceLocation = -1

    fun at(sourceLocation:Int): MachineOperation {
        this.sourceLocation = sourceLocation
        return this
    }

    abstract fun machineInstruction(builder: InstructionBuilder)
}

class InstructionBuilder {
    private var value:Int = 0
    private var bits:Int = 0

    fun lit(width:Int, value:Int): InstructionBuilder {
        if (this.bits + width > 12) throw IllegalArgumentException("Too much bits")
        val mask = (1 shl width) - 1
        if ((mask and value) != value) throw IllegalArgumentException("Value $value won't fit into $width bits")
        this.value = (this.value shl width) or value
        this.bits += width
        return this
    }

    fun reg(register: GeneralRegister, width:Int = 3): InstructionBuilder {
        if (this.bits + width > 12) throw IllegalArgumentException("Too much bits")
        this.value = (this.value shl width) or (register.ordinal ushr (3-width))
        this.bits += width
        return this
    }

    fun value():Int {
        if (bits != 12) throw IllegalStateException("Has $bits bits, 12 expected")
        return value
    }

    fun clear() {
        value = 0
        bits = 0
    }
}

class OperationLOAD(val targetRegister: GeneralRegister, val sourceMemory: GeneralRegister, val wide:Boolean) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(4, 0b0000).reg(targetRegister).reg(sourceMemory).lit(1, if (wide) 1 else 0).lit(1,0)
    }

    override fun toString(): String {
        return "LOAD "+ targetRegister +" "+ sourceMemory +" "+if(wide) "WIDE" else ""
    }
}

class OperationSTORE(val targetMemory: GeneralRegister, val sourceRegister: GeneralRegister, val wide: Boolean) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(4, 0b0001).reg(targetMemory).reg(sourceRegister).lit(1, if (wide) 1 else 0).lit(1,0)
    }

    override fun toString(): String {
        return "STORE "+targetMemory+" "+ sourceRegister +" "+if(wide) "WIDE" else ""
    }
}

enum class TransformationMOVE {None, Negate, Complement, _RESERVED_}
class OperationMOVE(val to: GeneralRegister, val from: GeneralRegister, val operation: TransformationMOVE) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(4, 0b0010).reg(to).reg(from).lit(2, operation.ordinal)
    }

    override fun toString(): String {
        return "MOVE $to $from $operation"
    }
}

enum class TypeJUMP {Long, Short, Zero, Sign, Carry, Overflow, SignZero, Call}
class OperationJUMP(val target: GeneralRegister, val type: TypeJUMP) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(6, 0b001100).lit(3, type.ordinal).reg(target)
    }

    override fun toString(): String {
        return "JUMP $type $target"
    }
}

enum class TypeSTACK {Push, Pop, StackInit, SegmentInit}
class OperationSTACK(val data: GeneralRegister, val type: TypeSTACK) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(7, 0b0011010).lit(2, type.ordinal).reg(data)
    }

    override fun toString(): String {
        return "$type $data"
    }
}

class OperationRETURN(val arguments:Int) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(8, 0b00110110).lit(4, arguments)
    }

    override fun toString(): String {
        return "RETURN $arguments"
    }
}

class OperationIO(val output:Boolean, val register: GeneralRegister) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(8, 0b00110111).lit(1, if (output) 1 else 0).reg(register)
    }

    override fun toString(): String {
        if (output) {
            return "OUTPUT $register"
        } else {
            return "INPUT $register"
        }
    }
}

enum class TypeCOMBINE {Add, Sub, And, Or, Xor, AddWithCarry, SubWithBorrow, ShiftLeft, ShiftRight, ShiftRightWithSignFill, Compare}
class OperationCOMBINE(val target: GeneralRegister, val source: GeneralRegister, val type: TypeCOMBINE) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(2,0b01).lit(4, type.ordinal).reg(target).reg(source)
    }

    override fun toString(): String {
        return "COMBINE $target $type= $source"
    }
}

class OperationLOADI(val target: GeneralRegister, val value:Int) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(1,0b1).reg(target).lit(8, value)
    }

    override fun toString(): String {
        return "LOADI $target $value"
    }
}

class AssemblyParser(data:CharArray) : AbstractParser(data) {

    private val commands = mutableListOf<MachineOperation>()
    private val labels = mutableMapOf<String, Int>()

    fun parse():List<MachineOperation> {
        swallowWhiteSpace()
        while (!eof()) {
            //Parse all labels
            while (parseLabel() != null) {}

            //Parse command
            val preErrors = errors()
            val command = parseCommand()
            val postErrors = errors()
            if (command != null) {
                commands.add(command)
            } else {
                if (preErrors == postErrors) error("Expected command")
                while (!eof() && peek() != '\n') next()//Skip to the end of line
            }
            swallowWhiteSpace()
        }

        //All commands parsed, resolve symbols
        for (i in commands.indices) {
            val operation = commands[i]
            if (operation is OperationSymbolicLOADI) {
                val value = labels[operation.label]
                if (value == null) {
                    error("Symbol '${operation.label}' is not defined", operation.sourceLocation)
                } else {
                    commands[i] = OperationLOADI(operation.target, value)
                }
            }
        }

        return commands
    }

    override fun swallowWhiteSpace() {
        while (true) {
            val next = peek()
            if (next.isWhitespace()) {
                next()
            } else if (next == '#') {
                next()
                while (peek() != '\n') {
                    next()
                }
            } else {
                break
            }
        }
    }

    private fun parseLabel():String? = parse {
        val labelName = parseWord() ?: return@parse null
        if (!match(":")) return@parse null

        if (labels.containsKey(labelName)) {
            error("Label redefinition!")
        }
        labels.put(labelName, commands.size)

        return@parse labelName
    }

    private fun parseWord():String? = parse {
        if (eof()) return@parse null
        val first = next()
        if (first.isWhitespace() || first == ':' || first.isDigit()) return@parse null
        val sb = StringBuilder()
        sb.append(first)
        while (!peek().isWhitespace() && peek() != ':') {
            sb.append(next())
        }
        return sb.toString()
    }

    private fun expectRegister(expectMessage:String? = null): GeneralRegister? = parse {
        for (reg in GeneralRegister.values()) {
            if ((reg.wideName != null && matchWord(reg.wideName)) || matchWord(reg.name)) {
                return@parse reg
            }
        }
        if (expectMessage != null) error(expectMessage)
        return@parse null
    }

    private fun parseNumber(): Long? = parse { begin ->
        val base:Int
        if (match("0x")) {
            //Hexadecimal
            base = 16
        } else if (match("0b")) {
            //Binary
            base = 2
        } else {
            //Decimal
            base = 10
        }

        val first = Character.digit(next(), base)
        if (first == -1) {
            if (base != 10) {
                error("Literal expected after prefix")
            }
            return@parse null
        }

        var value:Long = first.toLong()
        while (true) {
            val next = Character.digit(peek(), base)
            if (next == -1) break
            next()
            value = (value * base) + next
        }

        return@parse value
    }

    private fun parseCommand(): MachineOperation? = parse<MachineOperation> { begin ->
        if (matchWord("LOAD8") || matchWord("LOAD")) {
            val targetReg = expectRegister("LOAD8 target register expected") ?: return@parse null
            val sourceReg = expectRegister("LOAD8 source register expected") ?: return@parse null
            return@parse OperationLOAD(targetReg, sourceReg, false).at(begin)
        } else if (matchWord("LOAD16") || matchWord("LOADW")) {
            val targetReg = expectRegister("LOAD16 target register expected") ?: return@parse null
            val sourceReg = expectRegister("LOAD16 source register expected") ?: return@parse null
            return@parse OperationLOAD(targetReg, sourceReg, true).at(begin)
        } else if (matchWord("STORE8") || matchWord("STORE")) {
            val targetReg = expectRegister("STORE8 target register expected") ?: return@parse null
            val sourceReg = expectRegister("STORE8 source register expected") ?: return@parse null
            return@parse OperationSTORE(targetReg, sourceReg, false).at(begin)
        } else if (matchWord("STORE16") || matchWord("STOREW")) {
            val targetReg = expectRegister("STORE16 target register expected") ?: return@parse null
            val sourceReg = expectRegister("STORE16 source register expected") ?: return@parse null
            return@parse OperationSTORE(targetReg, sourceReg, true).at(begin)
        } else if (matchWord("MOVE") || matchWord("MOV")) {
            val targetReg = expectRegister("MOVE target register expected") ?: return@parse null
            val transformation: TransformationMOVE
            if (match("-")) {
                transformation = TransformationMOVE.Complement
            } else if(match("~")) {
                transformation = TransformationMOVE.Negate
            } else {
                transformation = TransformationMOVE.None
            }
            val sourceReg = expectRegister("MOVE source register expected") ?: return@parse null

            return@parse OperationMOVE(targetReg, sourceReg, transformation).at(begin)
        } else if (matchWord("JUMP")) {
            val type: TypeJUMP
            if (matchWord("LONG")) {
                type = TypeJUMP.Long
            } else if (match("IF")) {
                if (matchWord("ZERO") || matchWord("Z")) {
                    type = TypeJUMP.Zero
                } else if (matchWord("SIGN") || matchWord("S")) {
                    type = TypeJUMP.Sign
                } else if (matchWord("CARRY") || matchWord("C")) {
                    type = TypeJUMP.Carry
                } else if (matchWord("OVERFLOW") || matchWord("O")) {
                    type = TypeJUMP.Overflow
                } else if (matchWord("SIGN_ZERO") || matchWord("SZ")) {
                    type = TypeJUMP.SignZero
                } else {
                    error("JUMP IF: Condition expected")
                    return@parse null
                }
            } else {
                type = TypeJUMP.Short
            }
            val targetReg = expectRegister("Jump target register expected") ?: return@parse null
            return@parse OperationJUMP(targetReg, type).at(begin)
        } else if (matchWord("CALL")) {
            val targetReg = expectRegister("Call target register expected") ?: return@parse null
            return@parse OperationJUMP(targetReg, TypeJUMP.Call).at(begin)
        } else if (matchWord("PUSH")) {
            val dataReg = expectRegister("Push register expected") ?: return@parse null
            return@parse OperationSTACK(dataReg, TypeSTACK.Push).at(begin)
        } else if (matchWord("POP")) {
            val dataReg = expectRegister("Pop register expected") ?: return@parse null
            return@parse OperationSTACK(dataReg, TypeSTACK.Pop).at(begin)
        } else if (matchWord("STACK_INIT")) {
            val dataReg = expectRegister("Stack init register expected") ?: return@parse null
            return@parse OperationSTACK(dataReg, TypeSTACK.StackInit).at(begin)
        } else if (matchWord("SEGMENT_INIT")) {
            val dataReg = expectRegister("Segment init register expected") ?: return@parse null
            return@parse OperationSTACK(dataReg, TypeSTACK.SegmentInit).at(begin)
        } else if (matchWord("RETURN")) {
            val args = parseNumber()
            if (args == null) {
                error("RETURN: Expected amount of argument bytes")
                return@parse null
            }
            if (args < 0 || args.toInt().toLong() != args) {
                error("RETURN: Invalid amount of argument bytes")
                return@parse null
            }
            return@parse OperationRETURN(args.toInt()).at(begin)
        } else if (matchWord("OUTPUT")) {
            val reg = expectRegister("Output register expected") ?: return@parse null
            return@parse OperationIO(true, reg)
        } else if (matchWord("INPUT")) {
            val reg = expectRegister("Input register expected") ?: return@parse null
            return@parse OperationIO(false, reg)
        } else if (matchWord("ADD")) {
            val targetReg = expectRegister("ADD target register expected") ?: return@parse null
            val sourceReg = expectRegister("ADD source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Add).at(begin)
        } else if (matchWord("SUB")) {
            val targetReg = expectRegister("SUB target register expected") ?: return@parse null
            val sourceReg = expectRegister("SUB source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Sub).at(begin)
        } else if (matchWord("AND")) {
            val targetReg = expectRegister("AND target register expected") ?: return@parse null
            val sourceReg = expectRegister("AND source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.And).at(begin)
        } else if (matchWord("OR")) {
            val targetReg = expectRegister("OR target register expected") ?: return@parse null
            val sourceReg = expectRegister("OR source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Or).at(begin)
        } else if (matchWord("XOR")) {
            val targetReg = expectRegister("XOR target register expected") ?: return@parse null
            val sourceReg = expectRegister("XOR source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Xor).at(begin)
        } else if (matchWord("ADC")) {
            val targetReg = expectRegister("ADC target register expected") ?: return@parse null
            val sourceReg = expectRegister("ADC source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.AddWithCarry).at(begin)
        } else if (matchWord("SBB")) {
            val targetReg = expectRegister("SBB target register expected") ?: return@parse null
            val sourceReg = expectRegister("SBB source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.SubWithBorrow).at(begin)
        } else if (matchWord("SHL")) {
            val targetReg = expectRegister("SHL target register expected") ?: return@parse null
            val sourceReg = expectRegister("SHL source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.ShiftLeft).at(begin)
        } else if (matchWord("SHR")) {
            val targetReg = expectRegister("SHR target register expected") ?: return@parse null
            val sourceReg = expectRegister("SHR source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.ShiftRight).at(begin)
        } else if (matchWord("SRS")) {
            val targetReg = expectRegister("SRS target register expected") ?: return@parse null
            val sourceReg = expectRegister("SRS source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.ShiftRightWithSignFill).at(begin)
        } else if (matchWord("CMP")) {
            val targetReg = expectRegister("CMP target register expected") ?: return@parse null
            val sourceReg = expectRegister("CMP source register expected") ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Compare).at(begin)
        } else if (matchWord("LOADI")) {
            val targetReg = expectRegister("LOADI target register expected") ?: return@parse null
            val number = parseNumber()
            if (number == null) {
                val symbol = parseWord()
                if (symbol != null) {
                    return@parse OperationSymbolicLOADI(targetReg, symbol).at(begin)
                }
                error("LOADI: Number or symbol expected")
                return@parse null
            } else if (number < Byte.MIN_VALUE || number > 256) {
                error("LOADI: Number is invalid")
                return@parse null
            }
            return@parse OperationLOADI(targetReg, number.toInt()).at(begin)
        }
        error("Instruction expected")
        return@parse null
    }

    private class OperationSymbolicLOADI(val target: GeneralRegister, val label:String) : MachineOperation() {
        override fun machineInstruction(builder: InstructionBuilder) {
            throw IllegalStateException("This operation is symbolic and can't be translated")
        }
    }

}

