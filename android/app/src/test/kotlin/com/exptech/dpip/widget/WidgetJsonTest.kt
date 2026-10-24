package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetJsonTest {
    @Test
    fun `parses nested objects arrays and escapes`() {
        val root = WidgetJsonParser.parse(
            """{"a":{"b":[1,2,3],"c":"line\nbreak\u0041"},"d":true,"e":null,"f":-1.5e2}""",
        )?.objOrNull()!!
        val a = root["a"]!!.objOrNull()!!
        assertEquals(3, a["b"]!!.arrOrNull()!!.values.size)
        assertEquals("line\nbreakA", a["c"]!!.strOrNull())
        assertEquals(true, root["d"]!!.boolOrNull())
        assertEquals(WidgetJson.Null, root["e"])
        assertEquals(-150.0, root["f"]!!.doubleOrNull()!!, 1e-9)
    }

    @Test
    fun `keeps large integers exact`() {
        val parsed = WidgetJsonParser.parse("1791454316238")!!
        assertEquals(1791454316238L, parsed.longOrNull())
    }

    @Test
    fun `an integer is not silently truncated to an int`() {
        val parsed = WidgetJsonParser.parse("3000000000")!!
        assertNull(parsed.intOrNull())
        assertEquals(3000000000L, parsed.longOrNull())
    }

    @Test
    fun `rejects trailing content`() {
        assertNull(WidgetJsonParser.parse("""{"a":1}{"b":2}"""))
        assertNull(WidgetJsonParser.parse("1 2"))
    }

    @Test
    fun `rejects malformed documents`() {
        assertNull(WidgetJsonParser.parse("""{"a":}"""))
        assertNull(WidgetJsonParser.parse("""{"a":1,}"""))
        assertNull(WidgetJsonParser.parse("""{"a" 1}"""))
        assertNull(WidgetJsonParser.parse("""[1,2"""))
        assertNull(WidgetJsonParser.parse(""))
        assertNull(WidgetJsonParser.parse("""{"a":01}"""))
    }

    @Test
    fun `rejects the non-JSON literals a payload might smuggle in`() {
        assertNull(WidgetJsonParser.parse("""{"a":NaN}"""))
        assertNull(WidgetJsonParser.parse("""{"a":Infinity}"""))
        assertNull(WidgetJsonParser.parse("""{"a":-Infinity}"""))
        assertNull(WidgetJsonParser.parse("""{"a":0x10}"""))
        assertNull(WidgetJsonParser.parse("""{"a":+1}"""))
    }

    @Test
    fun `rejects a raw control character inside a string`() {
        val withControl = "{\"a\":\"x\u0001y\"}"
        assertNull(WidgetJsonParser.parse(withControl))
    }

    @Test
    fun `rejects nesting past the depth ceiling`() {
        val deep = "[".repeat(40) + "]".repeat(40)
        assertNull(WidgetJsonParser.parse(deep))
        val acceptable = "[".repeat(30) + "]".repeat(30)
        assertTrue(WidgetJsonParser.parse(acceptable) != null)
    }

    @Test
    fun `rejects a document past the length ceiling`() {
        val huge = "[" + "1,".repeat(WidgetJsonParser.maximumLength) + "1]"
        assertNull(WidgetJsonParser.parse(huge))
    }

    @Test
    fun `distinguishes an absent member from a null member`() {
        val root = WidgetJsonParser.parse("""{"present":null}""")!!.objOrNull()!!
        assertEquals(WidgetJson.Null, root["present"])
        assertTrue(root.has("present").not())
        assertNull(root["absent"])
        assertTrue(root.has("absent").not())
    }

    @Test
    fun `a string with an unpaired surrogate is still a string`() {
        val parsed = WidgetJsonParser.parse("""{"a":"\ud83d"}""")
        assertEquals(1, parsed!!["a"]!!.strOrNull()!!.length)
    }
}
