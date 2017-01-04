package com.darkyen.blocksembly

/**
 *
 */

interface Node {
    val begin:Int
    val end:Int

    fun toString(sb:StringBuilder, level:Int)

    override fun toString():String

    fun _toString():String {
        val sb = StringBuilder()
        toString(sb, 0)
        return sb.toString()
    }
}

private fun StringBuilder.level(level: Int):StringBuilder {
    for (i in 0..level) {
        append("  ")
    }
    return this
}

interface TopLevelNode : Node

interface ExpressionNode : Node

interface StatementNode : Node

class IdentifierNode (override val begin:Int, override val end:Int, val name: String) : Node {
    override fun toString(sb:StringBuilder, level: Int) { sb.append("'").append(name).append('\'') }
    override fun toString() = _toString()
}

class ProgramNode (override val begin:Int, override val end:Int,
                   val content:List<TopLevelNode>) : Node {
    override fun toString(sb:StringBuilder, level: Int) {
        sb.level(level-1).append("PROGRAM:\n")
        for (node in content) {
            sb.level(level)
            node.toString(sb, level+1)
            sb.append('\n')
        }
    }
    override fun toString() = _toString()
}

enum class ValueType {
    u8, s8, u16, s16, bool
}

class TypeNode (override val begin:Int, override val end:Int,
                val type:ValueType) : Node {
    override fun toString(sb:StringBuilder, level: Int) { sb.append("T\"").append(type).append('\"') }
    override fun toString() = _toString()
}

class CompoundStatement (override val begin:Int, override val end:Int, val body:List<StatementNode>) : StatementNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append("{\n")
        for (node in body) {
            sb.level(level)
            node.toString(sb, level+1)
            sb.append('\n')
        }
        sb.level(level-1).append("}\n")
    }
    override fun toString() = _toString()
}

class VariableDeclarationNode (override val begin:Int, override val end:Int,
                               val type:TypeNode, val name:IdentifierNode, val initialValue:ExpressionNode?) : TopLevelNode, StatementNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append("val ")
        name.toString(sb, level)
        sb.append(" : ")
        type.toString(sb, level)
        if (initialValue != null) {
            sb.append(" = ")
            initialValue.toString(sb, level)
        }
        sb.append(";")
    }
    override fun toString() = _toString()
}

class FunctionDeclarationNode(override val begin:Int, override val end:Int,
                              val name:IdentifierNode, val returnType:TypeNode?, val arguments:List<Pair<IdentifierNode, TypeNode>>,
                              val body:CompoundStatement) : TopLevelNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append("fun ")
        name.toString(sb, level)
        sb.append("(")
        for ((id, type) in arguments) {
            id.toString(sb, level)
            sb.append(" : ")
            type.toString(sb, level)
        }
        sb.append(") ")
        if (returnType != null){
            sb.append(": ")
            returnType.toString(sb, level)
            sb.append(" ")
        }
        body.toString(sb, level)
    }
    override fun toString() = _toString()
}

class AssignmentNode(override val begin:Int, override val end:Int, val variableName:IdentifierNode, val expression:ExpressionNode) : StatementNode {
    override fun toString(sb: StringBuilder, level: Int) {
        variableName.toString(sb, level)
        sb.append(" = ")
        expression.toString(sb, level)
        sb.append(";")
    }
    override fun toString() = _toString()
}

class IfStatementNode(override val begin:Int, override val end:Int, val condition:ExpressionNode, val body:CompoundStatement, val elseStatement:StatementNode?) : StatementNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append("if (")
        condition.toString(sb, level)
        sb.append(") ")
        body.toString(sb, level)
        if (elseStatement != null) {
            sb.append(" else ")
            elseStatement.toString(sb, level)
        }
    }
    override fun toString() = _toString()
}

class WhileStatementNode(override val begin:Int, override val end:Int, val condition:ExpressionNode, val body:CompoundStatement) : StatementNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append("while (")
        condition.toString(sb, level)
        sb.append(") ")
        body.toString(sb, level)
    }
    override fun toString() = _toString()
}

class FunctionCallNode(override val begin:Int, override val end:Int, val name: IdentifierNode, val arguments:List<ExpressionNode>) : ExpressionNode {
    override fun toString(sb: StringBuilder, level: Int) {
        name.toString(sb, level)
        sb.append("(")
        for ((i, argument) in arguments.withIndex()) {
            if (i != 0) {
                sb.append(", ")
            }
            argument.toString(sb, level)
        }
        sb.append(")")
    }
    override fun toString() = _toString()
}

class FunctionCallStatement (override val begin:Int, override val end:Int, val call: FunctionCallNode) : StatementNode {
    override fun toString(sb: StringBuilder, level: Int) {
        call.toString(sb, level)
        sb.append(";")
    }
    override fun toString() = _toString()
}

class LiteralNode(override val begin:Int, override val end:Int, val content:Long) : ExpressionNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append(content)
    }
    override fun toString() = _toString()
}

class BooleanLiteralNode(override val begin:Int, override val end:Int, val content:Boolean) : ExpressionNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append(content)
    }
    override fun toString() = _toString()
}

class FieldReferenceNode (val fieldIdentifier:IdentifierNode) : ExpressionNode {
    override fun toString(sb: StringBuilder, level: Int) {
        fieldIdentifier.toString(sb, level)
    }
    override fun toString() = _toString()

    override val begin: Int
        get() = fieldIdentifier.begin
    override val end: Int
        get() = fieldIdentifier.end
}

enum class UnaryOperator(val text:String) {
    PLUS("+"), MINUS("-"), NEG("~");
}

enum class BinaryOperator(val text:String) {
    PLUS("+"), MINUS("-"),
    BOOL_OR("||"), BOOL_AND("&&"),
    OR("|"), AND("&"), XOR("^"),
    SHIFT_LEFT("<<"), SIGNED_SHIFT_RIGHT(">>>"), SHIFT_RIGHT(">>"),
    GREATER_EQUALS(">="), GREATER(">"), LESSER_EQUALS("<="), LESSER("<"),
    EQUALS("==");
}

class UnaryExpressionNode(override val begin:Int, override val end:Int, val operator: UnaryOperator, val expression: ExpressionNode) : ExpressionNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append(operator.text)
        expression.toString(sb, level)
    }
    override fun toString() = _toString()
}

class BinaryExpressionNode(override val begin:Int, override val end:Int, val firstExpression:ExpressionNode, val operator: BinaryOperator, val secondExpression:ExpressionNode) : ExpressionNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append("[")
        firstExpression.toString(sb, level)
        sb.append(" ").append(operator.text).append(" ")
        secondExpression.toString(sb, level)
        sb.append("]")
    }
    override fun toString() = _toString()
}

class ParenExpressionNode(override val begin:Int, override val end:Int, val expression:ExpressionNode) : ExpressionNode {
    override fun toString(sb: StringBuilder, level: Int) {
        sb.append("(")
        expression.toString(sb, level)
        sb.append(")")
    }
    override fun toString() = _toString()
}