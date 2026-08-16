package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.location.Location
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

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
 *
 * **The chain always has an exit.** Because the reschedule at the top is
 * unconditional, this receiver is the only thing that can stop it, and it does:
 * on a device with Play services it re-registers the geofence at the end of
 * every firing and cancels itself the moment Play services confirms a fence is
 * live. So a device that fell back to the alarm climbs back to the geofence
 * within one interval instead of staying on it until the user next opens the
 * app — and a device that never should have been on it in the first place gets
 * off it just as fast.
 */
class LocationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        BgLocationStore.noteWake(appContext, "alarm")
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
                // Refine the provisional alarm to the adapted interval. This has
                // to happen BEFORE the hand-back below: the cancel there arrives
                // on a callback, so anything that schedules afterwards races it
                // and wins, which would leave the alarm running for good.
                if (next != stored && BgLocationStore.enabled(appContext)) {
                    LocationAlarmScheduler.schedule(appContext, next)
                }
                // Hand back to the geofence, which is the spine worth having:
                // Play services keeps monitoring it after an OEM battery manager
                // kills this process, and a parked phone costs it zero wakeups.
                //
                // Unconditional on a GMS device, and that is the point. This used
                // to be gated on `!BgLocationStore.armed()`, i.e. "only climb back
                // if we believe no fence is live" — which made the chain
                // inescapable in the one state that matters. `armed` is a stored
                // belief, and several paths arm this alarm without clearing it
                // (a resume whose fix times out indoors is the everyday one, see
                // BackgroundLocationChannel.armGeofence). Once the alarm was
                // running while the flag said `true`, the guard skipped the
                // re-register, so nothing ever reached the cancel — while the
                // top of onReceive rescheduled the next firing unconditionally.
                // Both spines then ran forever: a wakeup, a GPS fix and a POST
                // every 10 minutes that the geofence was already covering.
                //
                // Re-registering is cheap and idempotent (a fixed request id
                // replaces in place), and standing down on Play services'
                // confirmation rather than on the flag also repairs a stale
                // `armed` instead of trusting it.
                if (location != null &&
                    GmsAvailability.available(appContext) &&
                    BgLocationStore.enabled(appContext)
                ) {
                    val settled = CountDownLatch(1)
                    GeofenceManager.register(
                        appContext, location.latitude, location.longitude,
                    ) { armed ->
                        if (armed) LocationAlarmScheduler.cancel(appContext)
                        settled.countDown()
                    }
                    // The callback lands on the main looper, which is free — this
                    // is a worker thread inside goAsync, so awaiting it is safe.
                    // Capped well inside the broadcast window: if Play services
                    // does not answer in time the alarm simply survives to the
                    // next firing, which is the correct fallback anyway.
                    settled.await(10, TimeUnit.SECONDS)
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
