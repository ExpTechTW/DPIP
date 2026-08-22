package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

/** Records geofence delivery and hands location, registration, and HTTP to a job. */
class GeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        BgLocationStore.noteWake(app, "geofence")
        if (!BgLocationStore.enabled(app)) return

        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) {
            BgLocationStore.setArmed(app, false)
            BgLocationStore.prefs(app).edit()
                .putInt("last_geofence_error", event.errorCode)
                .putLong("last_geofence_error_at", System.currentTimeMillis())
                .apply()
            BgLocationStore.note(app, "geofence error ${event.errorCode}")
            LocationAlarmScheduler.ensure(app)
            BackgroundLocationJobService.enqueue(
                app,
                BackgroundLocationJobService.REASON_GEOFENCE_ERROR,
            )
            return
        }
        if (event.geofenceTransition != Geofence.GEOFENCE_TRANSITION_EXIT) return

        // Registration success is only an accepted request. A delivered EXIT is
        // the sole proof that the fast path works, and the only event allowed to
        // defer the independent alarm to its thirty-minute ceiling.
        BgLocationStore.prefs(app).edit()
            .putLong("last_geofence_transition_at", System.currentTimeMillis())
            .apply()
        LocationAlarmScheduler.onGeofenceTransition(app)
        BackgroundLocationJobService.enqueue(
            app,
            BackgroundLocationJobService.REASON_GEOFENCE_EXIT,
            event.triggeringLocation,
        )
    }
}
