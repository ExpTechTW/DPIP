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
     *
     * Always the adaptive interval, never [WATCHDOG_MIN], and deliberately not
     * [nextDelayMinutes]. Every call site of this function is a site that has
     * just established there is *no* fence, so the stored `armed` belief can
     * only be wrong here — and wrong in the expensive direction, handing a
     * fenceless device an hour of silence instead of five minutes.
     */
    fun ensure(context: Context) {
        if (!BgLocationStore.enabled(context)) return
        val interval = BgLocationStore.prefs(context)
            .getLong(BgLocationStore.KEY_INTERVAL_MIN, DEFAULT_INTERVAL_MIN)
        schedule(context, interval)
    }

    /**
     * How long the geofence may stay silent before the alarm goes looking.
     *
     * A geofence that arms is not a geofence that fires. The fence went live on
     * a Pixel 9, the alarm was cancelled because it had, and the device then
     * reported nothing for 133 minutes — no wake, no error, nothing to notice.
     * `dumpsys alarm` held no pending alarm, `geofence_armed` was true, and the
     * only breadcrumb was "arm: geofence live". Cancelling on `armed` made "the
     * fence is working" and "the fence is dead" the same observation.
     *
     * So the alarm is a watchdog now, and the fence is what pets it: every time
     * the fence proves it is alive the hour starts again, and the alarm only
     * ever actually fires after a full hour of fence silence. Behind a working
     * fence that costs nothing — a moving device re-arms far more often than
     * hourly, so the alarm is perpetually pushed out and never runs.
     */
    const val WATCHDOG_MIN = 60L

    /**
     * The delay the next alarm should use, given what the spine currently is.
     *
     * Two regimes, one switch. With a geofence armed the alarm is a watchdog and
     * the fence is the spine, so an hour is right. With no fence — a de-Googled
     * device, or one where registration was refused — the alarm *is* the spine,
     * and [nextIntervalMinutes]' adaptive 5–60 is right.
     *
     * Read from [BgLocationStore.armed] rather than from a second stored
     * interval on purpose. [BgLocationStore.KEY_INTERVAL_MIN] stays what it has
     * always been — the adaptive fallback value — and goes on being maintained
     * underneath a live fence, so a device whose fence dies drops straight back
     * onto a current interval instead of a stale one.
     *
     * `armed` is a belief, and nothing clears it when a fence dies quietly, so
     * this can say "watchdog" about a device that has no fence. That is the one
     * place the belief is allowed to be wrong: it costs an hour, which is the
     * bound the watchdog was chosen to give in the first place. [ensure] is the
     * function for every site that *knows* there is no fence.
     */
    fun nextDelayMinutes(context: Context): Long =
        if (BgLocationStore.armed(context)) {
            WATCHDOG_MIN
        } else {
            BgLocationStore.prefs(context)
                .getLong(BgLocationStore.KEY_INTERVAL_MIN, DEFAULT_INTERVAL_MIN)
        }

    /**
     * Restarts the hour, for when the geofence has just proved it is alive.
     *
     * Both proofs count: a fence that *arms* is talking to Play services, and a
     * fence that *fires* is doing its job. Either one resets the countdown.
     *
     * Deliberately not [cancel]: the fence is the fast path, not the only path.
     */
    fun resetWatchdog(context: Context) {
        if (!BgLocationStore.enabled(context)) return
        schedule(context, WATCHDOG_MIN)
    }

    /** Cancels any pending wake-up. Only for turning reporting off entirely. */
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
