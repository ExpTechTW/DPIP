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
    fun boxes(options: Bundle): List<SizeF> {
        if (Build.VERSION.SDK_INT >= 31) {
            val exact = BundleCompat.getParcelableArrayList(
                options, AppWidgetManager.OPTION_APPWIDGET_SIZES, SizeF::class.java,
            ).orEmpty().filter { valid(it.width) && valid(it.height) }.distinct().take(16)
            if (exact.isNotEmpty()) return exact
        }
        val minW = dimension(options, AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        val minH = dimension(options, AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
        val maxW = dimension(options, AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minW).coerceAtLeast(minW)
        val maxH = dimension(options, AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minH).coerceAtLeast(minH)
        return listOf(SizeF(minW.toFloat(), maxH.toFloat()), SizeF(maxW.toFloat(), minH.toFloat())).distinct()
    }

    fun portrait(boxes: List<SizeF>): SizeF = boxes.minBy { it.width }
    fun landscape(boxes: List<SizeF>): SizeF = boxes.maxBy { it.width }
    fun largestClass(context: Context, options: Bundle): WidgetSizeClass = boxes(options)
        .map { WidgetPresenter.sizeClass(it.width.toInt(), it.height.toInt(), context.resources.configuration.fontScale) }
        .maxBy { it.ordinal }

    private fun valid(value: Float) = value.isFinite() && value >= 1f && value <= 4096f
    private fun dimension(options: Bundle, key: String, fallback: Int): Int =
        options.getInt(key, fallback).takeIf { it in 1..4096 } ?: fallback
}
