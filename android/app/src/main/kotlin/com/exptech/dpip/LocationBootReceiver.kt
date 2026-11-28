package com.exptech.dpip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restores scheduling after reboot/update and delegates repair to JobScheduler.
 *
 * The report heartbeat is armed here too, before the background-location
 * check: it runs in every mode (manual included, where background reporting is
 * off), and an app update that is never opened would otherwise leave the
 * device without it until the next launch.
 */
class LocationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        BgLocationStore.noteWake(app, "boot")
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        ReportHeartbeat.ensure(app)
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
