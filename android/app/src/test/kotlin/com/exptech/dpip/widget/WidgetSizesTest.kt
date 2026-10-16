package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.os.Bundle
import android.util.SizeF
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Bounds fallback must remain valid when an OEM omits the exact-size list. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 31, 35])
class WidgetSizesTest {
    @Test fun `missing empty and invalid exact lists preserve paired rotations`() {
        val options = Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 130)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 269)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 117)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 220)
        }
        val expected = listOf(SizeF(130f, 220f), SizeF(269f, 117f))
        assertEquals(expected, WidgetSizes.boxes(options))
        options.putParcelableArrayList("appWidgetSizes", arrayListOf<SizeF>())
        assertEquals(expected, WidgetSizes.boxes(options))
        options.putParcelableArrayList("appWidgetSizes", arrayListOf(SizeF(-1f, 0f)))
        assertEquals(expected, WidgetSizes.boxes(options))
    }
    @Test fun `unusable bounds have finite positive defaults`() {
        val options = Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, -1)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, Int.MAX_VALUE)
        }
        assertEquals(listOf(SizeF(250f, 110f)), WidgetSizes.boxes(options))
    }
}
