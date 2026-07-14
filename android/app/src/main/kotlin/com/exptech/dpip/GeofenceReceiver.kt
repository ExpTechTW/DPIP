package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

/**
 * Fires when the device **exits** its current geofence: re-centres the geofence
 * around the fresh triggering point, then reports the township.
 *
 * Because the geofence is monitored by (and this broadcast dispatched through)
 * the Google Play services process, it keeps working after our own app process
 * is killed by an OEM battery manager — the key robustness win over the in-app
 * alarm. The fix + re-register + POST run off the main thread in a `goAsync`
 * window; everything reads from [BgLocationStore] so no Flutter isolate is
 * needed.
 *
 * The geofence is re-centred on `event.triggeringLocation` — the location that
 * caused the exit, which is fresh and by definition *outside* the old fence, so
 * (unlike a possibly-stale last-known fix) the new fence is correctly centred on
 * where the device actually is. Re-centring runs BEFORE the POST so a mid-work
 * process kill can't leave the spine un-armed (the report is retried on the next
 * move). If the platform supplies no triggering location and no fresh fix, or on
 * a geofence error, it re-arms around the last centre — combined with
 * `INITIAL_TRIGGER_EXIT` an already-outside device re-fires immediately, so the
 * spine self-heals instead of dying.
 */
class GeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        if (!BgLocationStore.enabled(appContext)) return
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) {
            reArm(appContext) // service dropped the fence (e.g. location toggled)
            return
        }
        if (event.geofenceTransition != Geofence.GEOFENCE_TRANSITION_EXIT) return

        val pending = goAsync()
        Thread {
            try {
                val location = event.triggeringLocation ?: FusedFix.get(appContext)
                if (location != null && BgLocationStore.enabled(appContext)) {
                    // Re-centre first (spine safety), then report (best-effort).
                    GeofenceManager.register(appContext, location.latitude, location.longitude)
                    BgLocationStore.report(appContext, location.latitude, location.longitude)
                } else if (location == null) {
                    // No fix at all — re-arm around the last centre so a future
                    // EXIT can still fire (the current fence is already exited).
                    reArm(appContext)
                }
            } catch (e: Exception) {
                // Best-effort.
            } finally {
                pending.finish()
            }
        }.start()
    }

    private fun reArm(context: Context) {
        if (BgLocationStore.enabled(context) && BgLocationStore.hasLast(context)) {
            GeofenceManager.register(
                context, BgLocationStore.lastLat(context), BgLocationStore.lastLng(context),
            )
        }
    }
}
