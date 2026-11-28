package com.exptech.dpip.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock

/**
 * Moves the rain chart along while it is on screen.
 *
 * The chart starts at "now", so it goes wrong by a minute every minute, and a
 * `RemoteViews` cannot redraw itself. This asks for a cache-only redraw about
 * every five minutes — never a fetch — and only while some instance draws a
 * chart: [WidgetUpdater] re-arms it after a render that drew one and cancels it
 * after a full render that drew none.
 *
 * A **non-wakeup**, inexact alarm on purpose. It costs nothing while the screen
 * is off (the alarm waits for the device to wake, and a home screen nobody can
 * see does not need its chart moved), it batches with other alarms, and it needs
 * no exact-alarm permission. The trade is that a redraw may arrive a few minutes
 * late; the chart is computed against the clock at the moment it is drawn, so a
 * late redraw is late, never wrong.
 *
 * The broadcast is explicit to the non-exported provider, so nothing else can
 * deliver it.
 */
internal object WidgetRainTicker {
    const val ACTION_TICK = "com.exptech.dpip.widget.RAIN_TICK"
    const val intervalMilliseconds = 5 * 60 * 1_000L

    private const val REQUEST_CODE = 0x5241_494E

    fun arm(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        alarms.set(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + intervalMilliseconds,
            intent(context),
        )
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)?.cancel(intent(context))
    }

    private fun intent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        REQUEST_CODE,
        Intent(context, WeatherWidgetProvider::class.java).setAction(ACTION_TICK),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
