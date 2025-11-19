package com.exptech.dpip

import android.content.SharedPreferences
import kotlin.math.roundToInt

private const val DOUBLE_FLAG_PREFIX = "home_widget.double."

/**
 * 從 SharedPreferences 讀取數值型資料，並自動處理由 home_widget
 * 以 Long 形式儲存的 Double。
 */
fun SharedPreferences.readNumber(key: String): Double? {
    val raw = all[key] ?: return null
    return when (raw) {
        is Int -> raw.toDouble()
        is Float -> raw.toDouble()
        is Long ->
            if (getBoolean("$DOUBLE_FLAG_PREFIX$key", false)) {
                java.lang.Double.longBitsToDouble(raw)
            } else {
                raw.toDouble()
            }
        is Double -> raw
        is String -> raw.toDoubleOrNull()
        else -> null
    }
}

fun SharedPreferences.readIntValue(key: String): Int? = readNumber(key)?.roundToInt()

fun SharedPreferences.readFloatValue(key: String): Float? = readNumber(key)?.toFloat()

fun SharedPreferences.readTimestampMillis(key: String): Long? {
    val value = readNumber(key)?.toLong() ?: return null
    return if (value < 1_000_000_000_000L) value * 1000L else value
}

