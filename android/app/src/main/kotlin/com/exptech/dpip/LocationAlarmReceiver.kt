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
 * **The chain never has an exit.** It used to: this receiver cancelled itself
 * the moment Play services confirmed a fence was live. That is now a lengthening
 * to [LocationAlarmScheduler.WATCHDOG_MIN] instead, because a fence
 * that registers is not a fence that fires, and cancelling on `armed` made a
 * fence that had quietly stopped firing indistinguishable from a device that
 * was not moving. Only turning reporting off stops the chain.
 */
class LocationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        BgLocationStore.noteWake(appContext, "alarm")
        if (!BgLocationStore.enabled(appContext)) return

        val prefs = BgLocationStore.prefs(appContext)
        // The adaptive fallback interval, which is maintained below whatever the
        // fence is doing — so this stays the right answer for the moment the
        // fence stops being the spine. It is NOT necessarily the delay to use.
        val stored = prefs.getLong(
            BgLocationStore.KEY_INTERVAL_MIN,
            LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
        )
        // Arm the next alarm BEFORE any blocking work, so the chain survives a
        // kill during the fix/network wait. The delay comes from
        // `nextDelayMinutes`, not from `stored`: behind a live fence this is a
        // watchdog on an hour, and reading `stored` here is what would collapse
        // it back to the adaptive interval on the first firing.
        LocationAlarmScheduler.schedule(appContext, LocationAlarmScheduler.nextDelayMinutes(appContext))

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
                //
                // The order used to matter a great deal: the hand-back below
                // cancelled the alarm from a callback, so anything that
                // scheduled afterwards won the race and left it running for
                // good. Now that arming only lengthens the alarm, losing that
                // race costs a shorter interval instead of a silent device —
                // which is the direction a race on a safety path should fail in.
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
                        if (armed) LocationAlarmScheduler.resetWatchdog(appContext)
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
