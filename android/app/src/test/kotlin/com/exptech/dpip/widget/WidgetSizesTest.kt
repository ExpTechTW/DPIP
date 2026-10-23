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

    @Test fun `each rotation keeps its own height when one width serves both`() {
        // A launcher whose cell width does not change with rotation. Recovering
        // the two boxes out of `boxes()` by comparing widths answered with the
        // same element twice here, so the short landscape box was rendered with
        // the tall portrait box's layout and its content clipped.
        val options = Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 240)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 240)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 90)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 220)
        }

        val rotations = WidgetSizes.rotationBoxes(options)

        assertEquals(SizeF(240f, 90f), rotations.landscape)
        assertEquals(SizeF(240f, 220f), rotations.portrait)
    }

    @Test fun `rotations name the boxes boxes returns`() {
        val options = Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 130)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 269)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 117)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 220)
        }

        val rotations = WidgetSizes.rotationBoxes(options)

        assertEquals(SizeF(269f, 117f), rotations.landscape)
        assertEquals(SizeF(130f, 220f), rotations.portrait)
        // The legacy pair and its named form must stay the same two boxes.
        assertEquals(WidgetSizes.boxes(options), rotations.distinctBoxes())
    }

    @Test fun `a square box collapses to one rotation`() {
        val options = Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 150)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 150)
        }

        assertEquals(1, WidgetSizes.rotationBoxes(options).distinctBoxes().size)
    }
}
