package com.darkyen.blocksembly

/**
 *
 */

class Parser (data:CharArray) : AbstractParser(data) {

    fun parseProgram():ProgramNode {
        val begin = mark()

        val topLevels = mutableListOf<TopLevelNode>()
        swallowWhiteSpace()
        while (!eof()) {
            swallowWhiteSpace()
            val variableDeclaration = parseVariableDeclaration()
            if (variableDeclaration != null) {
                topLevels.add(variableDeclaration)
                continue
            }

            val functionDeclaration = parseFunctionDeclaration()
            if (functionDeclaration != null) {
                topLevels.add(functionDeclaration)
                continue
            }

            error("Top level declaration expected")
            break
        }

        return ProgramNode(begin, mark(), topLevels)
    }

    private val KEYWORDS = setOf("var","val","if","while","fun")

    fun parseIdentifier():IdentifierNode? = parse { begin ->
        val first = next()
        if (!first.isJavaIdentifierStart()) {
            return@parse null
        }
        val sb = StringBuilder()
        sb.append(first)

        while (true) {
            if (peek().isJavaIdentifierPart()) {
                sb.append(next())
            } else break
        }
        val name = sb.toString()
        if (KEYWORDS.contains(name)) return@parse null
        return@parse IdentifierNode(begin, mark(), name)
    }

    fun parseTypeNode():TypeNode? = parse { begin ->
        for (type in ValueType.values()) {
            if (match(type.name)) {
                return@parse TypeNode(begin, mark(), type)
            }
        }
        return@parse null
    }

    fun parseVariableDeclaration():VariableDeclarationNode? = parse { begin ->
        if (!match("var")) return@parse null

        val identifier = parseIdentifier()
        if (identifier == null) {
            error("Expected declared variable identifier")
            return@parse null
        }

        if (!expect(":")) return@parse null

        val type = parseTypeNode()
        if (type == null) {
            error("Expected variable type node")
            return@parse null
        }

        var initialValue:ExpressionNode? = null

        if (match("=")) {
            initialValue = parseExpression()
            if (initialValue == null) {
                error("Expected initial value expression")
            }
        }

        if (!expect(";")) return@parse null

        return@parse VariableDeclarationNode(begin, mark(), type, identifier, initialValue)
    }

    private fun parseCompoundStatement(missingOpen:String):CompoundStatement? = parse { begin ->
        if (!expect("{", message = missingOpen)) return@parse null

        val body = mutableListOf<StatementNode>()

        val openBody = mark()
        while (!match("}")) {
            if (eof()) {
                error("Expected '}' for '{' at "+line(openBody))
                return@parse null
            }

            val statement = parseStatement()
            if (statement == null) {
                error("Expected statement in compound")
                return@parse null
            }
            body.add(statement)
        }

        return@parse CompoundStatement(begin, mark(), body)
    }

    fun parseFunctionDeclaration(): FunctionDeclarationNode? = parse { begin ->
        if (!match("fun")) return@parse null

        val identifier = parseIdentifier()
        if (identifier == null) {
            error("Expected function identifier")
            return@parse null
        }

        var returnType:TypeNode? = null

        if (match(":")) {
            returnType = parseTypeNode()
            if (returnType == null) {
                error("Expected return@parse type node")
                return@parse null
            }
        }

        val openParen = mark()
        if (!expect("(")) return@parse null

        val arguments = mutableListOf<Pair<IdentifierNode, TypeNode>>()

        while (!match(")")) {
            if (eof()) {
                error("Expected ')' for '(' at "+line(openParen))
                return@parse null
            }

            if (arguments.isNotEmpty()) {
                if (!expect(",")) return@parse null
            }

            val argIdentifier = parseIdentifier()
            if (argIdentifier == null) {
                error("Expected identifier for declared function's name")
                return@parse null
            }

            if (!expect(":", message = "Expected ':' and type for parameter "+argIdentifier.name)) return@parse null

            val argType = parseTypeNode()
            if (argType == null) {
                error("Expected type for parameter "+argIdentifier.name)
                return@parse null
            }

            arguments.add(Pair(argIdentifier, argType))
        }

        val body = parseCompoundStatement("Expected body of function "+identifier.name) ?: return@parse null

        return@parse FunctionDeclarationNode(begin, mark(), identifier, returnType, arguments, body)
    }

    fun parseLiteral(): LiteralNode? = parse { begin ->
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

        return@parse LiteralNode(begin, mark(), value)
    }

    fun parseBooleanLiteral(): BooleanLiteralNode? = parse { begin ->
        if (match("true")) {
            return@parse BooleanLiteralNode(begin, mark(), true)
        } else if (match("false")) {
            return@parse BooleanLiteralNode(begin, mark(), false)
        } else return@parse null
    }

    fun parseUnaryExpression(): UnaryExpressionNode? = parse { begin ->
        val operator:UnaryOperator = run opMatch@{
            for (operator in UnaryOperator.values()) {
                if (match(operator.text)) return@opMatch operator
            }
            return@parse null
        }

        val expression = parseExpression()
        if (expression == null) {
            error("Expected expression after unary "+operator)
            return@parse null
        }

        return@parse UnaryExpressionNode(begin, mark(), operator, expression)
    }

    fun parseFunctionCall(): FunctionCallNode? = parse { begin ->
        val functionIdentifier = parseIdentifier() ?: return@parse null
        if (!match("(")) return@parse null

        val arguments = mutableListOf<ExpressionNode>()
        while(!match(")")) {
            if (eof()) {
                error("Expected ')' for '(' at "+line(begin))
                return@parse null
            }

            if (arguments.isNotEmpty()) {
                if (!expect(",")) return@parse null
            }
            val arg = parseExpression()
            if (arg == null) {
                error("Expected expression for ${arguments.size+1}. argument")
                return@parse null
            }
            arguments.add(arg)
        }

        return@parse FunctionCallNode(begin, mark(), functionIdentifier, arguments)
    }

    fun parseExpression():ExpressionNode? = parse { begin ->
        val firstExpression:ExpressionNode = run<ExpressionNode> simple@{
            val literal = parseLiteral()
            if (literal != null) {
                return@simple literal
            }
            val boolean = parseBooleanLiteral()
            if (boolean != null) {
                return@simple boolean
            }
            val unary = parseUnaryExpression()
            if (unary != null) {
                return@simple unary
            }
            //Binary is special case
            val functionCall = parseFunctionCall()
            if (functionCall != null) {
                return@simple functionCall
            }

            // Paren
            if (match("(")) {
                val expression = parseExpression()
                if (expression == null) {
                    error("Expected expression in parentheses")
                    return@parse null
                }
                if (!expect(")", message = "Expected ')' to close '(' at "+line(begin)+":"+column(begin))) return@parse null

                return@simple ParenExpressionNode(begin, mark(), expression)
            }

            // Field reference
            val fieldIdentifier = parseIdentifier()
            if (fieldIdentifier != null) {
                return@simple FieldReferenceNode(fieldIdentifier)
            }

            return@parse null
        }

        val operator:BinaryOperator = run opMatch@{
            for (operator in BinaryOperator.values()) {
                if (match(operator.text)) return@opMatch operator
            }
            //There is no operator, this is not a binary expression
            return@parse firstExpression
        }

        val secondExpression = parseExpression()
        if (secondExpression == null) {
            error("Expected expression after "+operator)
            return@parse null
        }

        return@parse BinaryExpressionNode(begin, mark(), firstExpression, operator, secondExpression)
    }

    fun parseAssignment(): AssignmentNode? = parse { begin ->
        val variable = parseIdentifier() ?: return@parse null

        if (!match("=")) return@parse null

        val expression = parseExpression()
        if (expression == null) {
            error("Expected expression after '${variable.name} ='")
            return@parse null
        }

        expect(";", message = "Missing ';' after assignment")

        return@parse AssignmentNode(begin, mark(), variable, expression)
    }

    fun parseIfStatement(): IfStatementNode? = parse { begin ->
        if (!match("if")) return@parse null

        if (!expect("(")) return@parse null

        val condition = parseExpression()
        if (condition == null) {
            error("Condition expected after 'if ('")
            return@parse null
        }

        if (!expect(")")) return@parse null

        val body = parseCompoundStatement("Expected body of if statement") ?: return@parse null

        var elseStatement:StatementNode? = null

        if (match("else")) {
            val elseIf = parseIfStatement()
            if (elseIf != null) {
                elseStatement = elseIf
            } else {
                val elseBranch = parseCompoundStatement("'if' or '{' expected after else") ?: return@parse null
                elseStatement = elseBranch
            }
        }

        return@parse IfStatementNode(begin, mark(), condition, body, elseStatement)
    }

    fun parseWhileStatement(): WhileStatementNode? = parse { begin ->
        if (!match("while")) return@parse null

        if (!expect("(")) return@parse null

        val condition = parseExpression()
        if (condition == null) {
            error("Expected condition of while statement")
            return@parse null
        }

        if (!expect(")")) return@parse null

        val body = parseCompoundStatement("Expected body of while statement") ?: return@parse null

        return@parse WhileStatementNode(begin, mark(), condition, body)
    }

    fun parseStatement():StatementNode? = parse { begin ->
        val variableDeclaration = parseVariableDeclaration()
        if (variableDeclaration != null) return@parse variableDeclaration

        val assignment = parseAssignment()
        if (assignment != null) return@parse assignment

        val ifStatement = parseIfStatement()
        if (ifStatement != null) return@parse ifStatement

        val whileStatement = parseWhileStatement()
        if (whileStatement != null) return@parse whileStatement

        val functionCall = parseFunctionCall()
        if (functionCall != null) {
            expect(";", message = "Expected ';' after "+functionCall.name.name+" call")
            return@parse FunctionCallStatement(begin, mark(), functionCall)
        }

        return@parse null
    }
}