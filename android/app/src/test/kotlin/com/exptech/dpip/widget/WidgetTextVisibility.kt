package com.exptech.dpip.widget

import android.graphics.RectF
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import com.exptech.dpip.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue

/** Checks the text layout against its own content box AND every launcher clip. */
internal object WidgetTextVisibility {
    fun assertTree(label: String, view: View) {
        if (view.visibility != View.VISIBLE) return
        if (view is TextView && view.text.isNotEmpty()) {
            assertVisible("$label '${view.text}'", view, allowEllipsis = true)
        }
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) assertTree(label, view.getChildAt(index))
        }
    }

    fun assertVisible(label: String, text: TextView, allowEllipsis: Boolean = false) {
        val layout = text.layout
        assertNotNull("$label: no text layout", layout)
        layout!!
        assertTrue("$label: invisible text", text.visibility == View.VISIBLE)
        val availableHeight = text.height - text.compoundPaddingTop - text.compoundPaddingBottom
        assertTrue(
            "$label: '${text.text}' layout height ${layout.height} exceeds available $availableHeight",
            layout.height <= availableHeight,
        )
        val origin = origin(text)
        val clip = RectF(
            origin.first + text.compoundPaddingLeft,
            // TextView's canvas clips horizontal compound padding, but vertical
            // ink may use the font/explicit padding (e.g. Thai tone marks).
            origin.second,
            origin.first + text.width - text.compoundPaddingRight,
            origin.second + text.height,
        )
        var node: View = text
        while (node.id != android.R.id.background) {
            val parent = node.parent as? ViewGroup ?: break
            val p = origin(parent)
            if (parent.clipChildren) {
                val inset = parent.clipToPadding
                val bounds = RectF(
                    p.first + if (inset) parent.paddingLeft else 0,
                    p.second + if (inset) parent.paddingTop else 0,
                    p.first + parent.width - if (inset) parent.paddingRight else 0,
                    p.second + parent.height - if (inset) parent.paddingBottom else 0,
                )
                assertTrue("$label: outside ancestor clip $bounds", clip.intersect(bounds))
            }
            node = parent
        }
        val verticalOffset = when (text.gravity and Gravity.VERTICAL_GRAVITY_MASK) {
            Gravity.BOTTOM -> availableHeight - layout.height
            Gravity.CENTER_VERTICAL -> (availableHeight - layout.height) / 2
            else -> 0
        }
        for (line in 0 until layout.lineCount) {
            if (!allowEllipsis) {
                assertEquals("$label: ellipsised '${text.text}'", 0, layout.getEllipsisCount(line))
            }
            val bounds = RectF(
                origin.first + text.compoundPaddingLeft + layout.getLineLeft(line),
                origin.second + text.compoundPaddingTop + verticalOffset + layout.getLineTop(line),
                origin.first + text.compoundPaddingLeft + layout.getLineRight(line),
                origin.second + text.compoundPaddingTop + verticalOffset + layout.getLineBottom(line),
            )
            assertTrue("$label: line $bounds is clipped by $clip ('${text.text}')", clip.contains(bounds))
        }
        // Rasterise the layout without any parent clip. This is the expected
        // whole glyph, not the surviving pixels in an already clipped widget.
        // A generous guard also captures fallback-font accents and overhang.
        val guard = text.textSize.toInt().coerceAtLeast(1)
        // Single-line Toolbar labels use Android's VERY_WIDE scrolling layout.
        // Rasterise every glyph's actual extent, not a million empty columns;
        // line/ancestor bounds above still reject any out-of-viewport ink.
        val inkWidth = (0 until layout.lineCount).maxOf {
            kotlin.math.ceil(layout.getLineRight(it).toDouble()).toInt()
        }.coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(inkWidth + guard * 2, layout.height + guard * 2, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.translate(guard.toFloat(), guard.toFloat())
        layout.draw(canvas)
        val pixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        val textX = origin.first + text.compoundPaddingLeft - text.scrollX
        val textY = origin.second + text.compoundPaddingTop + verticalOffset - text.scrollY
        try {
            for (index in pixels.indices) {
                if (pixels[index] ushr 24 == 0) continue
                val x = textX + index % bitmap.width - guard + 0.5f
                val y = textY + index / bitmap.width - guard + 0.5f
                assertTrue("$label: expected glyph pixel ($x, $y) clipped by $clip", clip.contains(x, y))
            }
        } finally {
            bitmap.recycle()
        }
    }

    /** Root coordinates, including translated views and scrolled ancestors. */
    private fun origin(view: View): Pair<Float, Float> {
        var x = 0f
        var y = 0f
        var node = view
        while (node.id != android.R.id.background) {
            x += node.left + node.translationX
            y += node.top + node.translationY
            val parent = node.parent as? View ?: break
            x -= parent.scrollX
            y -= parent.scrollY
            node = parent
        }
        return x to y
    }
}
