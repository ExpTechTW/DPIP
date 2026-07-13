package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms the background location alarm after a reboot.
 *
 * The alarm uses elapsed-realtime triggers, which the system clears on restart,
 * so without this a device that reboots would silently stop reporting. Only
 * reschedules when reporting was enabled, at the last adapted interval.
 */
class LocationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val prefs = LocationAlarmScheduler.prefs(context)
        if (!prefs.getBoolean(LocationAlarmScheduler.KEY_ENABLED, false)) return
        LocationAlarmScheduler.schedule(
            context,
            prefs.getLong(
                LocationAlarmScheduler.KEY_INTERVAL_MIN,
                LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
            ),
        )
    }
}
