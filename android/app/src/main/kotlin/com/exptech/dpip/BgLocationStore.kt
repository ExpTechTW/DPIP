package com.exptech.dpip

import android.content.Context
import android.content.SharedPreferences
import java.net.HttpURLConnection
import java.net.URL

/**
 * Shared persistence + reporting for background device-location reporting, used
 * by both the primary geofence spine ([GeofenceManager]/[GeofenceReceiver]) and
 * the Google-Play-services-less alarm fallback ([LocationAlarmScheduler]).
 *
 * State lives in prefs so any receiver can run with no Flutter isolate alive.
 */
object BgLocationStore {
    const val PREFS = "dpip_bg_location"
    const val KEY_ENABLED = "enabled"
    const val KEY_TOKEN = "token"
    const val KEY_VERSION = "version"
    const val KEY_PLATFORM = "platform"
    const val KEY_LAST_LAT = "last_lat"
    const val KEY_LAST_LNG = "last_lng"
    const val KEY_HAS_LAST = "has_last"
    const val KEY_INTERVAL_MIN = "interval_min" // alarm fallback only

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    fun saveConfig(context: Context, token: String, version: String, platform: Int) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, true)
            .putString(KEY_TOKEN, token)
            .putString(KEY_VERSION, version)
            .putInt(KEY_PLATFORM, platform)
            .apply()
    }

    fun disable(context: Context) {
        prefs(context).edit().putBoolean(KEY_ENABLED, false).apply()
    }

    fun saveLast(context: Context, lat: Double, lng: Double) {
        prefs(context).edit()
            .putBoolean(KEY_HAS_LAST, true)
            .putFloat(KEY_LAST_LAT, lat.toFloat())
            .putFloat(KEY_LAST_LNG, lng.toFloat())
            .apply()
    }

    fun hasLast(context: Context): Boolean = prefs(context).getBoolean(KEY_HAS_LAST, false)

    fun lastLat(context: Context): Double =
        prefs(context).getFloat(KEY_LAST_LAT, 0f).toDouble()

    fun lastLng(context: Context): Double =
        prefs(context).getFloat(KEY_LAST_LNG, 0f).toDouble()

    /**
     * Reports coordinates to `updateDeviceLocation` (blocking — call off the
     * main thread). Best-effort: a failure is swallowed and retried on the next
     * trigger. coreExclusiveApi is tnn1-only (no failover).
     */
    fun report(context: Context, lat: Double, lng: Double) {
        val prefs = prefs(context)
        val token = prefs.getString(KEY_TOKEN, null) ?: return
        val version = prefs.getString(KEY_VERSION, null) ?: return
        val platform = prefs.getInt(KEY_PLATFORM, 0)
        try {
            val url = URL(
                "https://api.core-tnn1.exptech.dev/api/v2/location/" +
                    "$platform/$token/$version/$lat,$lng",
            )
            (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 10_000
                readTimeout = 10_000
                responseCode // fire the request
                disconnect()
            }
        } catch (e: Exception) {
            // Best-effort; the next trigger retries.
        }
    }
}
