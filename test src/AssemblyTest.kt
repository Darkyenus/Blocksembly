import com.darkyen.blocksembly.assembly.AssemblyParser
import com.darkyen.blocksembly.assembly.InstructionBuilder
import java.io.File
import java.nio.file.Files

/**
 *
 */

fun main(args: Array<String>) {
    val fileContent = Files.readAllLines(File("AssemblyTest.bas").toPath()).joinToString("\n")
    val parser = AssemblyParser(fileContent.toCharArray())

    val program = parser.parse()
    if (parser.errors() != 0) {
        return
    }

    val sb = StringBuilder()
    //core.instruction_memory[0] = 12'b100000000000;
    val instructionBuilder = InstructionBuilder()
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
    println(sb)
}