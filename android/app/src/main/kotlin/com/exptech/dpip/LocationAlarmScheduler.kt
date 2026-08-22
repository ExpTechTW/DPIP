package com.exptech.dpip

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock

/**
 * Independent, bounded fallback behind Android's geofence fast path.
 *
 * The alarm is always present while reporting is enabled. It adapts between
 * ten and thirty minutes and never trusts the stored `geofence_armed` belief:
 * successful registration only proves that Play services accepted a request,
 * not that a future transition will be delivered. Only a real EXIT transition
 * may push the deadline back to the thirty-minute ceiling.
 */
object LocationAlarmScheduler {
    private const val REQUEST_CODE = 888888

    const val MIN_INTERVAL_MIN = 10L
    const val DEFAULT_INTERVAL_MIN = 10L
    const val MAX_INTERVAL_MIN = 30L

    private const val HIGH_MOVEMENT_M = 1000.0
    private const val LOW_MOVEMENT_M = 100.0
    private const val MINUTE_MS = 60_000L

    private const val KEY_SCHEDULED = "alarm_scheduled"
    private const val KEY_NEXT_ELAPSED = "alarm_next_elapsed"
    private const val KEY_NEXT_WALL = "alarm_next_wall"

    /** Chooses the next bounded fallback interval from movement since the last fix. */
    fun nextIntervalMinutes(distanceMeters: Double?, currentMinutes: Long): Long =
        when {
            distanceMeters == null -> DEFAULT_INTERVAL_MIN
            distanceMeters >= HIGH_MOVEMENT_M -> MIN_INTERVAL_MIN
            distanceMeters >= LOW_MOVEMENT_M -> DEFAULT_INTERVAL_MIN
            else -> (currentMinutes + 5).coerceAtMost(MAX_INTERVAL_MIN)
        }

    /** Schedules a fresh deadline and records the actual target for diagnostics. */
    fun schedule(context: Context, delayMinutes: Long) {
        val bounded = delayMinutes.coerceIn(MIN_INTERVAL_MIN, MAX_INTERVAL_MIN)
        scheduleAt(
            context,
            SystemClock.elapsedRealtime() + bounded * MINUTE_MS,
            System.currentTimeMillis() + bounded * MINUTE_MS,
        )
    }

    /**
     * Restores the existing deadline without moving it. If it already expired,
     * starts a new bounded interval. This makes repeated native `start` calls
     * idempotent instead of postponing the fallback every time Flutter resumes.
     */
    fun ensure(context: Context) {
        if (!BgLocationStore.enabled(context)) return
        val prefs = BgLocationStore.prefs(context)
        val elapsed = prefs.getLong(KEY_NEXT_ELAPSED, 0L)
        val wall = prefs.getLong(KEY_NEXT_WALL, 0L)
        if (elapsed > SystemClock.elapsedRealtime() && wall > System.currentTimeMillis()) {
            scheduleAt(context, elapsed, wall)
            return
        }
        schedule(context, storedInterval(context))
    }

    /** Recreates elapsed-realtime state after a reboot, when the old clock is invalid. */
    fun restartAfterBoot(context: Context) {
        if (!BgLocationStore.enabled(context)) return
        schedule(context, DEFAULT_INTERVAL_MIN)
    }

    /** A real transition is the only event allowed to defer the fallback. */
    fun onGeofenceTransition(context: Context) {
        if (!BgLocationStore.enabled(context)) return
        schedule(context, MAX_INTERVAL_MIN)
    }

    fun storedInterval(context: Context): Long =
        BgLocationStore.prefs(context)
            .getLong(BgLocationStore.KEY_INTERVAL_MIN, DEFAULT_INTERVAL_MIN)
            .coerceIn(MIN_INTERVAL_MIN, MAX_INTERVAL_MIN)

    /** Cancels the OS alarm. Only used when reporting is disabled. */
    fun cancel(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pendingIntent(context))
        BgLocationStore.prefs(context).edit()
            .putBoolean(KEY_SCHEDULED, false)
            .remove(KEY_NEXT_ELAPSED)
            .remove(KEY_NEXT_WALL)
            .apply()
    }

    /**
     * Whether this process successfully asked AlarmManager for a wake-up.
     *
     * AlarmManager has no query API. `PendingIntent.FLAG_NO_CREATE` only says a
     * matching PendingIntent token exists and stays non-null after cancellation,
     * so it must not be used as evidence that an alarm is scheduled.
     */
    fun isScheduled(context: Context): Boolean =
        BgLocationStore.enabled(context) &&
            BgLocationStore.prefs(context).getBoolean(KEY_SCHEDULED, false)

    fun nextWallTime(context: Context): Long? =
        BgLocationStore.prefs(context).getLong(KEY_NEXT_WALL, 0L).takeIf { it > 0L }

    private fun scheduleAt(context: Context, elapsed: Long, wall: Long) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.setAndAllowWhileIdle(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            elapsed,
            pendingIntent(context),
        )
        BgLocationStore.prefs(context).edit()
            .putBoolean(KEY_SCHEDULED, true)
            .putLong(KEY_NEXT_ELAPSED, elapsed)
            .putLong(KEY_NEXT_WALL, wall)
            .apply()
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
