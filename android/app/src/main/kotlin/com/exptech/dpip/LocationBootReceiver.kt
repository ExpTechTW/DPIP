package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms the background spine after a reboot.
 *
 * Geofences are cleared by the system on reboot (and on a Play-services update
 * or app-data clear), and the fallback alarm uses elapsed-realtime triggers that
 * also clear — so without this a device that reboots would silently stop
 * reporting. Re-registers the geofence around the last centre (GMS) or the
 * fallback alarm (de-Googled), only when reporting was enabled.
 */
class LocationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val appContext = context.applicationContext
        if (!BgLocationStore.enabled(appContext)) return

        if (!GmsAvailability.available(appContext) || !BgLocationStore.hasLast(appContext)) {
            LocationAlarmScheduler.ensure(appContext)
            return
        }
        // Registration is a binder call into Play services, so hold the
        // broadcast open until it answers — the other two receivers already do,
        // and without it this one can be killed mid-flight. It also carries the
        // fallback: BOOT_COMPLETED regularly lands before GMS location is ready,
        // and a not-yet-initialised network location provider is exactly what
        // returns GEOFENCE_NOT_AVAILABLE. A boot that failed to arm used to
        // leave the device silent until the user next opened the app.
        val pending = goAsync()
        GeofenceManager.register(
            appContext, BgLocationStore.lastLat(appContext), BgLocationStore.lastLng(appContext),
        ) { armed ->
            if (!armed) LocationAlarmScheduler.ensure(appContext)
            pending.finish()
        }
    }
}
