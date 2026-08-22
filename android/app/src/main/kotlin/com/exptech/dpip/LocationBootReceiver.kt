package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restores scheduling after reboot/update and delegates repair to JobScheduler. */
class LocationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        BgLocationStore.noteWake(app, "boot")
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        if (!BgLocationStore.enabled(app)) return

        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            LocationAlarmScheduler.restartAfterBoot(app)
        } else {
            LocationAlarmScheduler.ensure(app)
        }
        BackgroundLocationWatchdog.ensure(app)
        BackgroundLocationJobService.enqueue(
            app,
            BackgroundLocationJobService.REASON_BOOT,
        )
    }
}
