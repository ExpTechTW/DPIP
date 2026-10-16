package com.exptech.dpip.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-renders after the system says its clock moved.
 *
 * The calibrated anchor is *monotonic*, so a device time or timezone change
 * cannot move it — that property is what stops a clock change from making an old
 * observation look fresh, and it is tested directly
 * (`CalibratedClockTest`). What does change is the *offset* between calibrated
 * time and the device clock, which is what the local-redraw schedule is
 * expressed in: a redraw that was scheduled for "in 12 minutes" is now at the
 * wrong moment, and the snapshot's own day/night and staleness boundaries have
 * to be re-read against the new device reading.
 *
 * So this does not invalidate the anchor — that would throw away a perfectly
 * good server instant and show "outdated" until the next synchronization. It
 * re-renders and re-arms the schedule, which re-derives the offset from the
 * anchor against the clock as it is now.
 *
 * `exported="false"`: these are system broadcasts, and the receiver does not
 * need to be reachable by anything else.
 */
class WidgetClockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> {
                WidgetLog.info(context, "clock changed action=${intent.action}")
                WidgetUpdater.updateAll(context)
                // Only when there is something to redraw: enqueuing work for a
                // home screen with no Widget would wake a worker to do nothing.
                if (WidgetUpdater.addresses(context).isNotEmpty()) {
                    WidgetRefreshScheduler.scheduleLocalRerender(context, 0)
                }
            }
        }
    }
}
