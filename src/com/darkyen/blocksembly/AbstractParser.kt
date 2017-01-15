package com.darkyen.blocksembly

/**
 *
 */
abstract class AbstractParser (private val data:CharArray) {

    private var pos = 0
    private var errors = 0

    protected fun mark():Int = pos

    protected fun rollback(mark:Int) {
        pos = mark
    }

    protected fun next():Char {
        try {
            return peek()
        } finally {
            pos++
        }
    }

    protected fun peek():Char {
        if (eof()) {
            return 0.toChar()
        } else {
            return data[pos]
        }
    }

    protected fun eof():Boolean = pos >= data.size

    protected open fun swallowWhiteSpace() {
        while (peek().isWhitespace()) {
            pos++
        }
    }

    protected fun match(what:CharSequence, swallowWhitespace: Boolean = true):Boolean {
        swallowWhiteSpace()
        if (pos + what.length > data.size) {
            return false
        } else {
            var i = 0
            while (i < what.length) {
                if (data[pos+i] != what[i]) return false
                i++
            }
            pos += what.length
            return true
        }
    }

    protected fun expect(what: CharSequence, rollbackMark:Int = -1, message: String? = null, swallowWhitespace:Boolean = true):Boolean {
        if (match(what, swallowWhitespace)) {
            return true
        } else {
            if (message != null) {
                error(message)
            } else {
                error("Expected "+what)
            }
            if (rollbackMark > 0) {
                rollback(rollbackMark)
            }
            return false
        }
    }


    inline protected fun <T> parse(op:(Int) -> T?):T? {
        swallowWhiteSpace()
        val begin = mark()
        val result = op(begin)
        if (result == null) {
            rollback(begin)
        }
        return result
    }

    protected fun line(of:Int = pos):Int {
        var l = 1
        for (i in 0..(Math.min(of, data.size)-1)) {
            if (data[i] == '\n') l++
        }
        return l
    }

    protected fun column(of:Int = pos):Int {
        var lineStart = Math.min(of, data.size)
        while (lineStart > 0 && data[lineStart] != '\n') {
            lineStart--
        }
        return (of - lineStart)
    }

    protected fun error(message:String, at:Int = pos) {
        errors++
        System.err.println("\t"+line(at)+":"+column(at)+"\t"+message)
    }

    override fun toString(): String {
        val sb = StringBuilder()
        for (i in (pos-20..pos-1)) {
            if (i >= 0 && i < data.size) {
                sb.append(data[i])
            }
        }
        sb.append(" | ")
        for (i in (pos..pos+20)) {
            if (i >= 0 && i < data.size) {
                sb.append(data[i])
            }
        }

        if (eof()) {
            sb.append(" [EOF]")
        }

        return sb.toString()
    }
}