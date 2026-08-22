package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Records an alarm wake, preserves the chain, and hands all work to JobScheduler. */
class LocationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        BgLocationStore.noteWake(app, "alarm")
        if (!BgLocationStore.enabled(app)) return

        // Preserve continuity before handing off: if this process dies while the
        // job is waiting for a fix or HTTP, another alarm still exists.
        LocationAlarmScheduler.schedule(app, LocationAlarmScheduler.storedInterval(app))
        BackgroundLocationJobService.enqueue(
            app,
            BackgroundLocationJobService.REASON_ALARM,
        )
    }
}
