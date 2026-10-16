package com.exptech.dpip.widget

/**
 * A dependency-free JSON reader for the Widget's native decoders.
 *
 * `org.json` is in the platform, but its only implementation on the unit-test
 * JVM is the stubbed `android.jar`, where every method throws. Reaching it from
 * code that has to be tested therefore means either a Robolectric-class
 * dependency or a test-only shadow of the platform, and both make the decoder's
 * tests depend on something other than the decoder.
 *
 * This reader exists so the JSON boundary — the one place a foreign, versioned
 * payload enters the process — is exercised by plain JVM tests with nothing
 * added to the build. It is deliberately strict, because the strictness is the
 * contract: a payload this file accepts is one the rest of the Widget trusts.
 *
 * Rejections are by `null`, not by exception: every caller here is already
 * deciding between "use this" and "keep the previous snapshot", and an
 * exception would only be caught to produce the same `null`.
 */
sealed interface WidgetJson {
    data class Obj(val values: Map<String, WidgetJson>) : WidgetJson

    data class Arr(val values: List<WidgetJson>) : WidgetJson

    data class Str(val value: String) : WidgetJson

    /** A number kept as its source text, so integer precision is never lost. */
    data class Num(val raw: String) : WidgetJson

    data class Bool(val value: Boolean) : WidgetJson

    data object Null : WidgetJson

    fun objOrNull(): Obj? = this as? Obj

    fun arrOrNull(): Arr? = this as? Arr

    fun strOrNull(): String? = (this as? Str)?.value

    /**
     * The number's value, or null for a non-number, a non-finite literal, or a
     * magnitude that does not survive a `Double`.
     */
    fun doubleOrNull(): Double? {
        val text = (this as? Num)?.raw ?: return null
        val value = text.toDoubleOrNull() ?: return null
        return if (value.isFinite()) value else null
    }

    fun intOrNull(): Int? {
        val value = doubleOrNull() ?: return null
        if (value != Math.floor(value) || value < Int.MIN_VALUE || value > Int.MAX_VALUE) {
            return null
        }
        return value.toInt()
    }

    fun longOrNull(): Long? {
        val value = doubleOrNull() ?: return null
        if (value != Math.floor(value) || value < Long.MIN_VALUE.toDouble() || value > Long.MAX_VALUE.toDouble()) {
            return null
        }
        return value.toLong()
    }

    fun boolOrNull(): Boolean? = (this as? Bool)?.value

    /** The member [key], or null when the receiver is not an object or lacks it. */
    operator fun get(key: String): WidgetJson? = objOrNull()?.values?.get(key)

    /** True when the member exists and is not JSON `null`. */
    fun has(key: String): Boolean {
        val value = get(key) ?: return false
        return value !== WidgetJson.Null
    }
}

/**
 * Parses one JSON document.
 *
 * `null` means the document is malformed, too long, or nested past
 * [maximumDepth]. Trailing content after the top-level value is rejected, so
 * `{"a":1}{"b":2}` is not silently accepted as the first object.
 */
object WidgetJsonParser {
    const val maximumLength = 512 * 1024
    private const val maximumDepth = 32

    fun parse(source: String): WidgetJson? {
        if (source.length > maximumLength) return null
        val reader = Reader(source)
        val value = reader.readValue(0) ?: return null
        reader.skipWhitespace()
        return if (reader.atEnd()) value else null
    }

    private class Reader(private val source: String) {
        private var position = 0

        fun atEnd(): Boolean = position >= source.length

        fun skipWhitespace() {
            while (position < source.length) {
                val c = source[position]
                if (c == ' ' || c == '\t' || c == '\n' || c == '\r') position++ else break
            }
        }

        fun readValue(depth: Int): WidgetJson? {
            if (depth > maximumDepth) return null
            skipWhitespace()
            if (atEnd()) return null
            return when (val c = source[position]) {
                '{' -> readObject(depth)
                '[' -> readArray(depth)
                '"' -> readString()?.let { WidgetJson.Str(it) }
                't' -> readLiteral("true", WidgetJson.Bool(true))
                'f' -> readLiteral("false", WidgetJson.Bool(false))
                'n' -> readLiteral("null", WidgetJson.Null)
                else -> if (c == '-' || c in '0'..'9') readNumber() else null
            }
        }

        private fun readLiteral(literal: String, value: WidgetJson): WidgetJson? {
            if (position + literal.length > source.length) return null
            if (source.regionMatches(position, literal, 0, literal.length).not()) return null
            position += literal.length
            return value
        }

        private fun readObject(depth: Int): WidgetJson? {
            position++ // '{'
            val values = LinkedHashMap<String, WidgetJson>()
            skipWhitespace()
            if (!atEnd() && source[position] == '}') {
                position++
                return WidgetJson.Obj(values)
            }
            while (true) {
                skipWhitespace()
                if (atEnd() || source[position] != '"') return null
                val key = readString() ?: return null
                skipWhitespace()
                if (atEnd() || source[position] != ':') return null
                position++
                val value = readValue(depth + 1) ?: return null
                values[key] = value
                skipWhitespace()
                if (atEnd()) return null
                when (source[position]) {
                    ',' -> position++
                    '}' -> {
                        position++
                        return WidgetJson.Obj(values)
                    }
                    else -> return null
                }
            }
        }

        private fun readArray(depth: Int): WidgetJson? {
            position++ // '['
            val values = ArrayList<WidgetJson>()
            skipWhitespace()
            if (!atEnd() && source[position] == ']') {
                position++
                return WidgetJson.Arr(values)
            }
            while (true) {
                val value = readValue(depth + 1) ?: return null
                values.add(value)
                skipWhitespace()
                if (atEnd()) return null
                when (source[position]) {
                    ',' -> position++
                    ']' -> {
                        position++
                        return WidgetJson.Arr(values)
                    }
                    else -> return null
                }
            }
        }

        private fun readString(): String? {
            position++ // '"'
            val builder = StringBuilder()
            while (true) {
                if (atEnd()) return null
                when (val c = source[position]) {
                    '"' -> {
                        position++
                        return builder.toString()
                    }
                    '\\' -> {
                        position++
                        if (atEnd()) return null
                        when (val escape = source[position]) {
                            '"' -> builder.append('"')
                            '\\' -> builder.append('\\')
                            '/' -> builder.append('/')
                            'b' -> builder.append('\b')
                            'f' -> builder.append('\u000C')
                            'n' -> builder.append('\n')
                            'r' -> builder.append('\r')
                            't' -> builder.append('\t')
                            'u' -> {
                                val code = readHex4() ?: return null
                                builder.append(code)
                            }
                            else -> {
                                if (escape in 'a'..'z' || escape in 'A'..'Z') return null
                                return null
                            }
                        }
                        position++
                    }
                    else -> {
                        if (c < ' ') return null
                        builder.append(c)
                        // Surrogate halves are appended as they arrive; the
                        // payloads here are already UTF-16 text, so a valid
                        // pair reassembles and a lone half is still a string.
                        position++
                    }
                }
            }
        }

        private fun readHex4(): Char? {
            if (position + 4 >= source.length) return null
            var value = 0
            for (index in 1..4) {
                val digit = hexDigit(source[position + index]) ?: return null
                value = value * 16 + digit
            }
            position += 4
            return value.toChar()
        }

        private fun hexDigit(c: Char): Int? = when (c) {
            in '0'..'9' -> c - '0'
            in 'a'..'f' -> c - 'a' + 10
            in 'A'..'F' -> c - 'A' + 10
            else -> null
        }

        private fun readNumber(): WidgetJson? {
            val start = position
            if (!atEnd() && source[position] == '-') position++
            if (atEnd() || source[position] !in '0'..'9') return null
            if (source[position] == '0') {
                position++
            } else {
                while (!atEnd() && source[position] in '0'..'9') position++
            }
            if (!atEnd() && source[position] == '.') {
                position++
                if (atEnd() || source[position] !in '0'..'9') return null
                while (!atEnd() && source[position] in '0'..'9') position++
            }
            if (!atEnd() && (source[position] == 'e' || source[position] == 'E')) {
                position++
                if (!atEnd() && (source[position] == '+' || source[position] == '-')) position++
                if (atEnd() || source[position] !in '0'..'9') return null
                while (!atEnd() && source[position] in '0'..'9') position++
            }
            return WidgetJson.Num(source.substring(start, position))
        }
    }
}
