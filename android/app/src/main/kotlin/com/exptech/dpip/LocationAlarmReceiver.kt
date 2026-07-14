package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.location.Location

/**
 * The GMS-less fallback alarm handler: gets one framework-`LocationManager` fix,
 * reports the township, and keeps the interval adapting to how far the device
 * moved (see [LocationAlarmScheduler]). Devices with Google Play services use
 * the geofence spine instead.
 *
 * **Chain continuity:** the next alarm is armed *up front* — before the fix and
 * HTTP work — so a mid-work process kill can't permanently break the
 * self-rescheduling chain; it's then refined to the adapted interval. Runs off
 * the main thread in a `goAsync` window; state comes from [BgLocationStore].
 */
class LocationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        if (!BgLocationStore.enabled(appContext)) return

        val prefs = BgLocationStore.prefs(appContext)
        val stored = prefs.getLong(
            BgLocationStore.KEY_INTERVAL_MIN,
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
                        distanceFromLast(appContext, location), stored,
                    )
                    BgLocationStore.saveLast(appContext, location.latitude, location.longitude)
                    prefs.edit().putLong(BgLocationStore.KEY_INTERVAL_MIN, n).apply()
                    BgLocationStore.report(appContext, location.latitude, location.longitude)
                    n
                } else {
                    // No fix — back off toward the max like the stationary case.
                    val n = (stored + 5).coerceAtMost(LocationAlarmScheduler.MAX_INTERVAL_MIN)
                    prefs.edit().putLong(BgLocationStore.KEY_INTERVAL_MIN, n).apply()
                    n
                }
                // Refine the provisional alarm to the adapted interval.
                if (next != stored && BgLocationStore.enabled(appContext)) {
                    LocationAlarmScheduler.schedule(appContext, next)
                }
            } catch (e: Exception) {
                // The provisional alarm is already armed — leave it as the backstop.
            } finally {
                pending.finish()
            }
        }.start()
    }

    private fun distanceFromLast(context: Context, location: Location): Double? {
        if (!BgLocationStore.hasLast(context)) return null
        val results = FloatArray(1)
        Location.distanceBetween(
            BgLocationStore.lastLat(context),
            BgLocationStore.lastLng(context),
            location.latitude,
            location.longitude,
            results,
        )
        return results[0].toDouble()
    }
}
