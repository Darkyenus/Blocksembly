import com.darkyen.blocksembly.Parser
import java.io.File
import java.nio.file.Files

/**
 *
 */

fun main(args: Array<String>) {
    val fileContent = Files.readAllLines(File("ParserTest.bpp").toPath()).joinToString("\n")
    val parser = Parser(fileContent.toCharArray())

    val program = parser.parseProgram()

    val sb = StringBuilder()
    program.toString(sb, 0)
    println(sb)
}