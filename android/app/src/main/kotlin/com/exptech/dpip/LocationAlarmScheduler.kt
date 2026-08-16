package com.exptech.dpip

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock

/**
 * Timing policy + scheduling for the **GMS-less fallback** background spine.
 *
 * On devices with Google Play services the primary spine is the low-power
 * geofence ([GeofenceManager]); this adaptive-interval alarm is the fallback for
 * de-Googled devices, where geofencing/FLP are unavailable. A single
 * self-rescheduling alarm adapts its interval to distance moved — short when
 * moving, backing off to an hour when still — using Doze-friendly inexact
 * `setAndAllowWhileIdle`. Config/last-fix live in [BgLocationStore].
 *
 * Deliberate tradeoff: `setAndAllowWhileIdle` is throttled in Doze to roughly
 * one fire per ~9 min, so [MIN_INTERVAL_MIN] is best-effort — accepted here to
 * avoid a foreground service or the exact-alarm permission.
 */
object LocationAlarmScheduler {
    private const val REQUEST_CODE = 888888

    const val MIN_INTERVAL_MIN = 5L
    const val DEFAULT_INTERVAL_MIN = 10L
    const val MAX_INTERVAL_MIN = 60L
    private const val HIGH_MOVEMENT_M = 1000.0
    private const val LOW_MOVEMENT_M = 100.0

    /**
     * The next interval (minutes) given the [distanceMeters] moved since the last
     * fix: 5 min moving fast (≥1 km), 10 min moving a little (≥100 m), otherwise
     * back off +5 min up to an hour. A null distance (no previous fix) uses the
     * default.
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

    /**
     * Schedules the fallback at its stored interval — the "the geofence did not
     * take, don't leave this device with nothing" path.
     *
     * Every place that arms a geofence needs this, because every one of them can
     * fail: the channel on app start, [GeofenceReceiver] re-centring after an
     * exit or recovering from a GEOFENCE_NOT_AVAILABLE, and
     * [LocationBootReceiver] after a reboot. A failure with no fallback is
     * silent and permanent — the geofence is the only spine on a Play-services
     * device, so nothing is left to notice or retry.
     */
    fun ensure(context: Context) {
        if (!BgLocationStore.enabled(context)) return
        val interval = BgLocationStore.prefs(context)
            .getLong(BgLocationStore.KEY_INTERVAL_MIN, DEFAULT_INTERVAL_MIN)
        schedule(context, interval)
    }

    /** Cancels any pending wake-up. */
    fun cancel(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pendingIntent(context))
    }

    /**
     * Whether an alarm is currently pending — diagnostics only.
     *
     * `FLAG_NO_CREATE` returns null when no matching PendingIntent exists, which
     * is the only way to ask AlarmManager "is something scheduled?"; there is no
     * query API. It must carry the same flags and request code as
     * [pendingIntent] or it will not match.
     */
    fun isScheduled(context: Context): Boolean {
        val intent = Intent(context, LocationAlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) != null
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
