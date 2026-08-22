package com.exptech.dpip

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Durable self-healing layer behind the geofence and alarm paths.
 *
 * WorkManager is deliberately not a third location timer. A healthy run only
 * verifies the unique work and restores a missing/expired alarm deadline. It
 * asks the existing job path for a fix only after every native activity signal
 * has been quiet longer than the alarm's maximum interval plus Doze grace.
 */
object BackgroundLocationWatchdog {
    private const val UNIQUE_WORK = "background-location-watchdog"
    private const val TAG = "background-location-watchdog"
    private const val INTERVAL_MIN = 30L
    private const val DOZE_GRACE_MIN = 15L
    private const val TIMEOUT_MS =
        (LocationAlarmScheduler.MAX_INTERVAL_MIN + DOZE_GRACE_MIN) * 60_000L

    private const val KEY_LAST_RUN_AT = "watchdog_last_run_at"
    private const val KEY_RUN_N = "watchdog_run_n"
    private const val KEY_LAST_REPAIR_AT = "watchdog_last_repair_at"
    private const val KEY_REPAIR_N = "watchdog_repair_n"
    private const val KEY_BASELINE_AT = "watchdog_baseline_at"

    /** Creates or updates the single watchdog without resetting its enqueue time. */
    fun ensure(context: Context) {
        if (!BgLocationStore.enabled(context)) return
        val prefs = BgLocationStore.prefs(context)
        if (!prefs.contains(KEY_BASELINE_AT)) {
            // First enable has no wake/report evidence yet. Give the initial job
            // the same 45-minute window before diagnostics call it overdue.
            prefs.edit().putLong(KEY_BASELINE_AT, System.currentTimeMillis()).apply()
        }
        val request = PeriodicWorkRequest.Builder(
            BackgroundLocationWatchdogWorker::class.java,
            INTERVAL_MIN,
            TimeUnit.MINUTES,
        )
            // `start` already queues the initial report. Waiting one period keeps
            // first install/resume from producing a duplicate location request.
            .setInitialDelay(INTERVAL_MIN, TimeUnit.MINUTES)
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10L, TimeUnit.MINUTES)
            .addTag(TAG)
            .build()
        WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
            UNIQUE_WORK,
            // The specification is static, so KEEP avoids both duplicate work
            // and an unnecessary WorkManager generation on every Flutter resume.
            // REPLACE would postpone the watchdog on every native start.
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context.applicationContext).cancelUniqueWork(UNIQUE_WORK)
        BgLocationStore.prefs(context).edit().remove(KEY_BASELINE_AT).apply()
    }

    internal fun lastActivityAt(context: Context): Long {
        val prefs = BgLocationStore.prefs(context)
        return maxOf(
            prefs.getLong("wake_alarm_at", 0L),
            prefs.getLong("last_geofence_transition_at", 0L),
            prefs.getLong(BgLocationStore.KEY_LAST_ATTEMPT_AT, 0L),
            prefs.getLong(KEY_BASELINE_AT, 0L),
        )
    }

    internal fun isOverdue(now: Long, lastActivityAt: Long): Boolean =
        lastActivityAt <= 0L || now - lastActivityAt > TIMEOUT_MS

    internal fun recordRun(context: Context, now: Long) {
        val prefs = BgLocationStore.prefs(context)
        prefs.edit()
            .putLong(KEY_LAST_RUN_AT, now)
            .putInt(KEY_RUN_N, prefs.getInt(KEY_RUN_N, 0) + 1)
            .apply()
    }

    internal fun recordRepair(context: Context, now: Long) {
        val prefs = BgLocationStore.prefs(context)
        prefs.edit()
            .putLong(KEY_LAST_REPAIR_AT, now)
            .putInt(KEY_REPAIR_N, prefs.getInt(KEY_REPAIR_N, 0) + 1)
            .apply()
    }

    /**
     * Live WorkManager state plus persisted execution evidence for diagnostics.
     * Call off the main thread because WorkManager's query is a future.
     */
    fun diagnostics(context: Context): Map<String, Any?> {
        val infos = try {
            WorkManager.getInstance(context.applicationContext)
                .getWorkInfosForUniqueWork(UNIQUE_WORK)
                .get(2, TimeUnit.SECONDS)
        } catch (_: Exception) {
            null
        }
        val info = infos?.firstOrNull { !it.state.isFinished } ?: infos?.firstOrNull()
        val prefs = BgLocationStore.prefs(context)
        val lastActivityAt = lastActivityAt(context)
        val state = info?.state
        return mapOf(
            "watchdogState" to when {
                infos == null -> "query unavailable"
                state == null -> "missing"
                else -> state.name.lowercase()
            },
            "watchdogScheduled" to (state == WorkInfo.State.ENQUEUED ||
                state == WorkInfo.State.BLOCKED || state == WorkInfo.State.RUNNING),
            "watchdogNextAt" to info?.nextScheduleTimeMillis
                ?.takeIf { it > 0L && it < Long.MAX_VALUE },
            "watchdogLastRunAt" to prefs.getLong(KEY_LAST_RUN_AT, 0L).takeIf { it > 0L },
            "watchdogRunCount" to prefs.getInt(KEY_RUN_N, 0),
            "watchdogLastRepairAt" to prefs
                .getLong(KEY_LAST_REPAIR_AT, 0L)
                .takeIf { it > 0L },
            "watchdogRepairCount" to prefs.getInt(KEY_REPAIR_N, 0),
            "watchdogLastActivityAt" to lastActivityAt.takeIf { it > 0L },
            "watchdogOverdue" to (BgLocationStore.enabled(context) &&
                isOverdue(System.currentTimeMillis(), lastActivityAt)),
        )
    }
}

/** Periodic entry point; all expensive work remains in BackgroundLocationJobService. */
class BackgroundLocationWatchdogWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    override fun doWork(): Result {
        val app = applicationContext
        val now = System.currentTimeMillis()
        BackgroundLocationWatchdog.recordRun(app, now)
        if (!BgLocationStore.enabled(app)) return Result.success()

        // This is cheap and idempotent: a live future deadline is preserved;
        // an expired/lost one is recreated without acquiring a location.
        LocationAlarmScheduler.ensure(app)

        val lastActivityAt = BackgroundLocationWatchdog.lastActivityAt(app)
        if (!BackgroundLocationWatchdog.isOverdue(now, lastActivityAt)) {
            return Result.success()
        }

        if (!GeofenceManager.hasPermission(app)) {
            BgLocationStore.setArmed(app, false)
            BgLocationStore.note(app, "watchdog: overdue, background location unavailable")
            return Result.success()
        }

        BackgroundLocationWatchdog.recordRepair(app, now)
        val quietFor = if (lastActivityAt <= 0L) {
            "never active"
        } else {
            "quiet ${(now - lastActivityAt) / 60_000L} min"
        }
        BgLocationStore.note(app, "watchdog: repairing overdue path ($quietFor)")
        return if (
            BackgroundLocationJobService.enqueue(
                app,
                BackgroundLocationJobService.REASON_WATCHDOG,
            )
        ) {
            Result.success()
        } else {
            Result.retry()
        }
    }
}
