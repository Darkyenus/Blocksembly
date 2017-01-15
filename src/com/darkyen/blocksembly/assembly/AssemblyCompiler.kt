package com.darkyen.blocksembly.assembly

import com.darkyen.blocksembly.AbstractParser

/*
 *
 */

class AssemblyCompiler {

}

enum class GeneralRegister(val altName:String, val wideName:String? = null) {
    R0S("RG0", "R0"),
    R0O("RG1"),
    R1S("RG2", "R1"),
    R1O("RG3"),
    R2S("RG4", "R2"),
    R2O("RG5"),
    R3S("RG6", "R3"),
    R3O("RG7");
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
        if ((1 shl width - 1) and value != value) throw IllegalArgumentException("Value $value won't fit into $width bits")
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

class OperationLOAD(val register: GeneralRegister, val memory: GeneralRegister, val wide:Boolean) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(4, 0b0000).reg(register).reg(memory).lit(1, if (wide) 1 else 0).lit(1,0)
    }
}

class OperationSTORE(val register: GeneralRegister, val memory: GeneralRegister, val wide:Boolean) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(4, 0b0001).reg(register).reg(memory).lit(1, if (wide) 1 else 0).lit(1,0)
    }
}

enum class TransformationMOVE {None, Negate, Complement, _RESERVED_}
class OperationMOVE(val to: GeneralRegister, val from: GeneralRegister, val operation: TransformationMOVE) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(4, 0b0010).reg(to).reg(from).lit(2, operation.ordinal)
    }
}

enum class TypeJUMP {Long, Short, Zero, Sign, Carry, Overflow, SignZero, Call}
class OperationJUMP(val target: GeneralRegister, val type: TypeJUMP) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(6, 0b001100).lit(3, type.ordinal).reg(target)
    }
}

enum class TypeSTACK {Push, Pop, Init, _RESERVED_}
class OperationSTACK(val data: GeneralRegister, val type: TypeSTACK) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(7, 0b0011010).lit(2, type.ordinal).reg(data)
    }
}

class OperationRETURN(val arguments:Int) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(8, 0b00110110).lit(4, arguments)
    }
}

enum class TypeCOMBINE {Add, Sub, And, Or, Xor, AddWithCarry, SubWithBorrow, ShiftLeft, ShiftRight, ShiftRightWithSignFill, Compare}
class OperationCOMBINE(val target: GeneralRegister, val source: GeneralRegister, val type: TypeCOMBINE) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(2,0b01).lit(4, type.ordinal).reg(target).reg(source)
    }
}

class OperationLOADI(val target: GeneralRegister, val value:Int) : MachineOperation() {
    override fun machineInstruction(builder: InstructionBuilder) {
        builder.lit(1,0b1).reg(target).lit(8, value)
    }
}

class AssemblyParser(data:CharArray) : AbstractParser(data) {

    private val commands = mutableListOf<MachineOperation>()
    private val labels = mutableMapOf<String, Int>()

    fun parse():List<MachineOperation> {
        while (!eof()) {
            //Parse all labels
            while (parseLabel()) {}

            //Parse command
            val command = parseCommand()
            if (command != null) {
                commands.add(command)
            } else {
                error("Expected command")
            }
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

    private fun parseLabel():Boolean = parse {
        val labelName = parseWord() ?: return@parse false
        if (!match(":")) return@parse false

        if (labels.containsKey(labelName)) {
            error("Label redefinition!")
        }
        labels.put(labelName, commands.size)

        return@parse true
    } ?: false

    private fun parseWord():String? = parse {
        val first = next()
        if (first.isWhitespace() || first == ':' || first.isDigit()) return@parse null
        val sb = StringBuilder()
        sb.append(first)
        while (!peek().isWhitespace() || first == ':') {
            sb.append(next())
        }
        return sb.toString()
    }

    private fun expectRegister(expectMessage:String? = null, wideOnly:Boolean = false): GeneralRegister? = parse {
        for (reg in GeneralRegister.values()) {
            if (wideOnly && reg.wideName == null) continue
            if (match(reg.name) || match(reg.altName) || (reg.wideName != null && match(reg.wideName))) {
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
        if (match("LOAD8")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationLOAD(targetReg, sourceReg, false).at(begin)
        } else if (match("LOAD16")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationLOAD(targetReg, sourceReg, true).at(begin)
        } else if (match("STORE8")) {
            val sourceReg = expectRegister("Source register expected") ?: return@parse null
            val targetReg = expectRegister("Target register expected", false) ?: return@parse null
            return@parse OperationSTORE(sourceReg, targetReg, false).at(begin)
        } else if (match("STORE16")) {
            val sourceReg = expectRegister("Source register expected") ?: return@parse null
            val targetReg = expectRegister("Target register expected", false) ?: return@parse null
            return@parse OperationSTORE(sourceReg, targetReg, true).at(begin)
        } else if (match("MOVE")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val transformation: TransformationMOVE
            if (match("-")) {
                transformation = TransformationMOVE.Complement
            } else if(match("~")) {
                transformation = TransformationMOVE.Negate
            } else {
                transformation = TransformationMOVE.None
            }
            val sourceReg = expectRegister("Source register expected") ?: return@parse null

            return@parse OperationMOVE(targetReg, sourceReg, transformation).at(begin)
        } else if (match("JUMP")) {
            val type: TypeJUMP
            if (match("LONG")) {
                type = TypeJUMP.Long
            } else if (match("IF")) {
                if (match("Z")) {
                    type = TypeJUMP.Zero
                } else if (match("S")) {
                    type = TypeJUMP.Sign
                } else if (match("C")) {
                    type = TypeJUMP.Carry
                } else if (match("O")) {
                    type = TypeJUMP.Overflow
                } else if (match("SZ")) {
                    type = TypeJUMP.SignZero
                } else {
                    error("Condition expected")
                    return@parse null
                }
            } else {
                type = TypeJUMP.Short
            }
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            return@parse OperationJUMP(targetReg, type).at(begin)
        } else if (match("CALL")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            return@parse OperationJUMP(targetReg, TypeJUMP.Call).at(begin)
        } else if (match("PUSH")) {
            val dataReg = expectRegister("Push register expected") ?: return@parse null
            return@parse OperationSTACK(dataReg, TypeSTACK.Push).at(begin)
        } else if (match("POP")) {
            val dataReg = expectRegister("Pop register expected") ?: return@parse null
            return@parse OperationSTACK(dataReg, TypeSTACK.Pop).at(begin)
        } else if (match("STACK_INIT")) {
            val dataReg = expectRegister("Stack init register expected") ?: return@parse null
            return@parse OperationSTACK(dataReg, TypeSTACK.Init).at(begin)
        } else if (match("RETURN")) {
            val args = parseNumber()
            if (args == null) {
                error("Expected amount of argument bytes")
                return@parse null
            }
            if (args < 0 || args.toInt().toLong() != args) {
                error("Invalid amount of argument bytes")
                return@parse null
            }
            return@parse OperationRETURN(args.toInt()).at(begin)
        } else if (match("ADD")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Add).at(begin)
        } else if (match("SUB")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Sub).at(begin)
        } else if (match("AND")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.And).at(begin)
        } else if (match("OR")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Or).at(begin)
        } else if (match("XOR")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Xor).at(begin)
        } else if (match("ADC")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.AddWithCarry).at(begin)
        } else if (match("SBB")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.SubWithBorrow).at(begin)
        } else if (match("SHL")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.ShiftLeft).at(begin)
        } else if (match("SHR")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.ShiftRight).at(begin)
        } else if (match("SRS")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.ShiftRightWithSignFill).at(begin)
        } else if (match("CMP")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val sourceReg = expectRegister("Source register expected", true) ?: return@parse null
            return@parse OperationCOMBINE(targetReg, sourceReg, TypeCOMBINE.Compare).at(begin)
        } else if (match("LOADI")) {
            val targetReg = expectRegister("Target register expected") ?: return@parse null
            val number = parseNumber()
            if (number == null) {
                val symbol = parseWord()
                if (symbol != null) {
                    return@parse OperationSymbolicLOADI(targetReg, symbol).at(begin)
                }
                error("Number or symbol expected")
                return@parse null
            } else if (number < Byte.MIN_VALUE || number > 256) {
                error("Number is invalid")
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

