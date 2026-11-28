package com.exptech.dpip.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * The system events the Widget has to answer on its own.
 *
 * * **Boot and app update.** WorkManager's work survives both, but the
 *   *instances* do not always: a launcher that restored them hands back ids
 *   this process has never seen. Reconciling against the launcher and asking
 *   for one refresh is what makes the Widget recover without the user opening
 *   the app.
 * * **Device clock or timezone change.** The calibrated anchor is monotonic, so
 *   neither moves it (`CalibratedClockTest`); what does change is the device
 *   offset the next redraw is scheduled in, and the boundaries on screen read
 *   against it. So this redraws and re-arms the redraw, and does not throw a
 *   perfectly good anchor away.
 *
 * `onReceive` runs inside a broadcast window on the main thread, so it only
 * touches a small table and enqueues; all network work is the refresh chain's.
 * Every action here is a protected system broadcast, which no other app can
 * send.
 */
class WidgetSystemReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                WidgetLog.info(context, "reconcile after ${intent.action}")
                WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Boot)
            }

            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> {
                WidgetLog.info(context, "clock changed action=${intent.action}")
                WidgetUpdater.updateAll(context)
                // Only when there is something to redraw: enqueuing work for a
                // home screen with no Widget would wake a worker to do nothing.
                if (WidgetStore.open(context).usedAddresses().isNotEmpty()) {
                    WidgetRefresh.scheduleLocalRerender(context, 0)
                }
            }
        }
    }
}
