package com.exptech.dpip

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock

/**
 * Timing policy and scheduling for background device-location reporting.
 *
 * Instead of a battery-hungry continuous foreground service, a single
 * self-rescheduling alarm wakes the app just often enough and adapts its
 * interval to how far the device moved since the last fix — short when moving,
 * backing off to an hour when still. This mirrors the legacy
 * `android_alarm_manager_plus` design, but native (no plugin) and using the
 * Doze-friendly inexact `setAndAllowWhileIdle`, so it stays gentle on the
 * battery. All state lives in [PREFS] so the alarm receiver and the boot
 * receiver can run without the Flutter isolate.
 *
 * Deliberate tradeoff: `setAndAllowWhileIdle` is throttled in Doze to roughly
 * one fire per ~9 min (and less in deep App-Standby buckets), so
 * [MIN_INTERVAL_MIN] (5) is best-effort, not guaranteed, while the device dozes.
 * That's accepted here in exchange for not running a foreground service or
 * holding the exact-alarm permission — background township updates don't need
 * sub-10-minute precision.
 */
object LocationAlarmScheduler {
    const val PREFS = "dpip_bg_location"
    const val KEY_ENABLED = "enabled"
    const val KEY_TOKEN = "token"
    const val KEY_VERSION = "version"
    const val KEY_PLATFORM = "platform"
    const val KEY_LAST_LAT = "last_lat"
    const val KEY_LAST_LNG = "last_lng"
    const val KEY_HAS_LAST = "has_last"
    const val KEY_INTERVAL_MIN = "interval_min"

    private const val REQUEST_CODE = 888888

    const val MIN_INTERVAL_MIN = 5L
    const val DEFAULT_INTERVAL_MIN = 10L
    const val MAX_INTERVAL_MIN = 60L
    private const val HIGH_MOVEMENT_M = 1000.0
    private const val LOW_MOVEMENT_M = 100.0

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /**
     * The next interval (minutes) given the [distanceMeters] moved since the last
     * fix: 5 min moving fast (≥1 km), 10 min moving a little (≥100 m), otherwise
     * back off +5 min up to an hour. A null distance (no previous fix) uses the
     * default. Mirrors the legacy `_calculateNextInterval`.
     */
    fun nextIntervalMinutes(distanceMeters: Double?, currentMinutes: Long): Long =
        when {
            distanceMeters == null -> DEFAULT_INTERVAL_MIN
            distanceMeters >= HIGH_MOVEMENT_M -> MIN_INTERVAL_MIN
            distanceMeters >= LOW_MOVEMENT_M -> DEFAULT_INTERVAL_MIN
            else -> (currentMinutes + 5).coerceAtMost(MAX_INTERVAL_MIN)
        }

    /** Schedules the next wake-up [delayMinutes] from now (inexact, Doze-friendly). */
    fun schedule(context: Context, delayMinutes: Long) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = SystemClock.elapsedRealtime() + delayMinutes * 60_000L
        am.setAndAllowWhileIdle(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            triggerAt,
            pendingIntent(context),
        )
    }

    /** Cancels any pending wake-up. */
    fun cancel(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pendingIntent(context))
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, LocationAlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
