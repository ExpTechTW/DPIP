package com.exptech.dpip.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms the Widget's work after a boot or an app update.
 *
 * Neither event is delivered to WorkManager as a request to re-run: its own
 * work survives both, but the *instances* do not always, and a launcher that
 * restored them hands back ids this process has never seen. Reconciling from the
 * instance table on each of these is what makes the Widget recover without the
 * user opening the app — the state a user who "just rebooted" is in.
 *
 * `onReceive` runs inside a broadcast window on the main thread, so it only
 * touches a small table and enqueues; all actual work is the Worker's.
 */
class WidgetReconcileReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                WidgetLog.info(context, "reconcile after ${intent.action}")
                WidgetUpdater.reconcile(context)
            }
        }
    }

}
