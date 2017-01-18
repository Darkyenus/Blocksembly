import com.darkyen.blocksembly.assembly.AssemblyParser
import com.darkyen.blocksembly.assembly.InstructionBuilder
import java.io.File
import java.nio.file.Files

/**
 *
 */

fun main(args: Array<String>) {
    val fileName = "MemoryTest.bas"//"Fibonacci.bas"//"AssemblyTest.bas"

    val fileContent = Files.readAllLines(File(fileName).toPath()).joinToString("\n")
    val parser = AssemblyParser(fileContent.toCharArray())

    val program = parser.parse()
    if (parser.errors() != 0) {
        return
    }

    val sb_verilog = StringBuilder()
    val sb_debug = StringBuilder()
    val instructionBuilder = InstructionBuilder()

    /*
    //core.instruction_memory[0] = 12'b100000000000;

    for ((i, operation) in program.withIndex()) {
        sb.append("core.instruction_memory[").append(i).append("] = 12'b")
        operation.machineInstruction(instructionBuilder)
        val binaryString = Integer.toBinaryString(instructionBuilder.value())
        for (j in 0..(12-binaryString.length)-1) {
            sb.append("0")
        }
        sb.append(binaryString)
        instructionBuilder.clear()

        sb.append(";\n")
    }
    */

    //in_instruction_write = 0;
    //in_instruction = 12'b0100000101010;
    //in_instruction_address = 0;
    //in_instruction_write = 1;

    for ((i, operation) in program.withIndex()) {
        sb_verilog.append("in_instruction_write = 0; ")
        sb_verilog.append("in_instruction = 12'b")
        operation.machineInstruction(instructionBuilder)
        val binaryString = Integer.toBinaryString(instructionBuilder.value())
        for (j in 0..(12-binaryString.length)-1) {
            sb_verilog.append("0")
        }
        sb_verilog.append(binaryString)
        instructionBuilder.clear()

        sb_verilog.append(";")
        sb_verilog.append("in_instruction_address = 16'h").append(Integer.toHexString(i)).append("; ")
        sb_verilog.append("in_instruction_write = 1; #1 // ").append(operation).append("\n")

        sb_debug.append(i).append("\t").append(operation).append("\n")
    }



    println(sb_verilog)
    println()
    println()
    println()
    println(sb_debug)
}