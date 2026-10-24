package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import androidx.core.os.BundleCompat

/** Launcher content boxes, shared by rendering and source forecast demand.
 * Options already exclude host padding. Never subtract that padding again.
 * Legacy bounds describe rotations, not a simultaneous min/min rectangle.
 */
internal object WidgetSizes {
    /**
     * The two boxes the pre-API-31 options describe, each named by its rotation.
     *
     * Named rather than recovered: the legacy options give one width pair and one
     * height pair, and which rotation a box belongs to is only knowable at the
     * point they are combined. Picking them back out of a `List<SizeF>` by
     * comparing widths — as this file used to — is wrong whenever a launcher
     * reports `minWidth == maxWidth` with differing heights, because both
     * selectors then answer with the same element and the short landscape box is
     * rendered with the tall box's layout. That is a real launcher shape (a grid
     * whose cell width does not change with rotation), and the symptom is clipped
     * content on exactly the devices that have no `OPTION_APPWIDGET_SIZES`.
     */
    data class RotationBoxes(val landscape: SizeF, val portrait: SizeF) {
        /** Distinct, portrait first — the order [boxes] has always returned. */
        fun distinctBoxes(): List<SizeF> = listOf(portrait, landscape).distinct()
    }

    fun boxes(options: Bundle): List<SizeF> {
        if (Build.VERSION.SDK_INT >= 31) {
            val exact = BundleCompat.getParcelableArrayList(
                options, AppWidgetManager.OPTION_APPWIDGET_SIZES, SizeF::class.java,
            ).orEmpty().filter { valid(it.width) && valid(it.height) }.distinct().take(16)
            if (exact.isNotEmpty()) return exact
        }
        return rotationBoxes(options).distinctBoxes()
    }

    fun rotationBoxes(options: Bundle): RotationBoxes {
        val minW = dimension(options, AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        val minH = dimension(options, AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
        val maxW = dimension(options, AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minW).coerceAtLeast(minW)
        val maxH = dimension(options, AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minH).coerceAtLeast(minH)
        return RotationBoxes(
            landscape = SizeF(maxW.toFloat(), minH.toFloat()),
            portrait = SizeF(minW.toFloat(), maxH.toFloat()),
        )
    }

    fun largestClass(context: Context, options: Bundle): WidgetSizeClass = boxes(options)
        .map { WidgetPresenter.sizeClass(it.width.toInt(), it.height.toInt(), context.resources.configuration.fontScale) }
        .maxBy { it.ordinal }

    private fun valid(value: Float) = value.isFinite() && value >= 1f && value <= 4096f
    private fun dimension(options: Bundle, key: String, fallback: Int): Int =
        options.getInt(key, fallback).takeIf { it in 1..4096 } ?: fallback
}
