package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.location.Location
import java.net.HttpURLConnection
import java.net.URL

/**
 * Fires on each background location alarm: gets one fix, reports it to
 * `updateDeviceLocation`, then keeps the interval adapting to how far the device
 * moved (see [LocationAlarmScheduler]).
 *
 * **Chain continuity:** the next alarm is armed *up front* — before the fix and
 * HTTP work — using the stored interval, so a mid-work process kill (aggressive
 * OEM battery manager, memory pressure) can never permanently break the
 * self-rescheduling chain. It is then refined to the adapted interval once the
 * move is known (the same request code replaces the provisional alarm).
 *
 * The fix, POST, and refine run off the main thread in a `goAsync` window;
 * everything reads from shared prefs so it works with no Flutter isolate alive.
 * A missing fix backs the interval off (a device that can't fix stops waking so
 * often); a POST error just retries next cycle.
 */
class LocationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        val prefs = LocationAlarmScheduler.prefs(appContext)
        if (!prefs.getBoolean(LocationAlarmScheduler.KEY_ENABLED, false)) return
        val token = prefs.getString(LocationAlarmScheduler.KEY_TOKEN, null) ?: return
        val version = prefs.getString(LocationAlarmScheduler.KEY_VERSION, null) ?: return
        val platform = prefs.getInt(LocationAlarmScheduler.KEY_PLATFORM, 0)

        val stored = prefs.getLong(
            LocationAlarmScheduler.KEY_INTERVAL_MIN,
            LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
        )
        // Arm the next alarm BEFORE any blocking work, so the chain survives a
        // kill during the fix/network wait.
        LocationAlarmScheduler.schedule(appContext, stored)

        val pending = goAsync()
        Thread {
            try {
                val location = LocationFetcher.getFix(appContext)
                val next = if (location != null) {
                    val n = LocationAlarmScheduler.nextIntervalMinutes(
                        distanceFromLast(prefs, location), stored,
                    )
                    prefs.edit()
                        .putBoolean(LocationAlarmScheduler.KEY_HAS_LAST, true)
                        .putFloat(
                            LocationAlarmScheduler.KEY_LAST_LAT, location.latitude.toFloat(),
                        )
                        .putFloat(
                            LocationAlarmScheduler.KEY_LAST_LNG, location.longitude.toFloat(),
                        )
                        .putLong(LocationAlarmScheduler.KEY_INTERVAL_MIN, n)
                        .apply()
                    post(platform, token, version, location.latitude, location.longitude)
                    n
                } else {
                    // No fix — back off toward the max like the stationary case.
                    val n = (stored + 5).coerceAtMost(LocationAlarmScheduler.MAX_INTERVAL_MIN)
                    prefs.edit().putLong(LocationAlarmScheduler.KEY_INTERVAL_MIN, n).apply()
                    n
                }
                // Refine the provisional alarm to the adapted interval.
                if (next != stored &&
                    prefs.getBoolean(LocationAlarmScheduler.KEY_ENABLED, false)
                ) {
                    LocationAlarmScheduler.schedule(appContext, next)
                }
            } catch (e: Exception) {
                // The provisional alarm is already armed — leave it as the backstop.
            } finally {
                pending.finish()
            }
        }.start()
    }

    private fun distanceFromLast(prefs: SharedPreferences, location: Location): Double? {
        if (!prefs.getBoolean(LocationAlarmScheduler.KEY_HAS_LAST, false)) return null
        val lastLat = prefs.getFloat(LocationAlarmScheduler.KEY_LAST_LAT, 0f).toDouble()
        val lastLng = prefs.getFloat(LocationAlarmScheduler.KEY_LAST_LNG, 0f).toDouble()
        val results = FloatArray(1)
        Location.distanceBetween(lastLat, lastLng, location.latitude, location.longitude, results)
        return results[0].toDouble()
    }

    private fun post(platform: Int, token: String, version: String, lat: Double, lng: Double) {
        try {
            // coreExclusiveApi is tnn1-only (no failover).
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
            // Best-effort; the next wake-up retries.
        }
    }
}
