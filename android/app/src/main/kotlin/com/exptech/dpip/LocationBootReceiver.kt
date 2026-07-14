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
        if (!BgLocationStore.enabled(context)) return

        if (GmsAvailability.available(context) && BgLocationStore.hasLast(context)) {
            GeofenceManager.register(
                context, BgLocationStore.lastLat(context), BgLocationStore.lastLng(context),
            )
        } else {
            val interval = BgLocationStore.prefs(context).getLong(
                BgLocationStore.KEY_INTERVAL_MIN, LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
            )
            LocationAlarmScheduler.schedule(context, interval)
        }
    }
}
