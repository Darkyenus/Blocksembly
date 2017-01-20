package com.darkyen.blocksembly

import java.io.File
import java.nio.file.Files

/**
 *
 */

fun main(args: Array<String>) {

}

fun compile(file:File) : ByteArray? {
    return compile(Files.readAllLines(file.toPath()).joinToString("\n"))
}

fun compile(fileContent:String):ByteArray? {
    val parser = Parser(fileContent.toCharArray())
    val program = parser.parseProgram()
    if (parser.errors() != 0) {
        System.err.println("${parser.errors()} errors")
        return null
    }

    // Global variables
    for (variableDeclaration in program.content.filter { node -> node is VariableDeclarationNode }.map { node -> node as VariableDeclarationNode }) {

    }

    TODO()
}