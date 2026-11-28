package com.exptech.dpip

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit
import kotlin.random.Random

/**
 * One report from a device that has gone quiet, in every location mode.
 *
 * The backend counts a device as active from its `/v2/location` reports, and
 * some devices stop sending them while they still receive alerts: a township
 * pinned by hand stops background reporting altogether, and a phone that never
 * moves gives the movement-driven paths nothing to report. So once a day a
 * WorkManager job asks whether the device's last successful report, from any
 * path ([BgLocationStore.reported]), is older than [QUIET_MS] plus this
 * install's [jitterMs], and if so sends exactly one.
 *
 * It never asks for a location. The point is the pinned township's reporting
 * point while one is pinned (Dart hands it over, [setManualPoint]), and
 * otherwise the point the last successful report sent. A device with no
 * successful report at all has nothing to resend, and is skipped.
 *
 * Like [BackgroundLocationWatchdog], this is deliberately not a location timer,
 * and it is independent of `start` / `stop`: nothing here touches the alarm,
 * the geofence or the background-location job.
 */
object ReportHeartbeat {
    const val UNIQUE_WORK = "report-heartbeat"
    private const val TAG = "report-heartbeat"
    private const val PERIOD_HOURS = 24L

    /** How long a device may go without a successful report. */
    const val QUIET_MS = 3L * 24 * 60 * 60 * 1000

    /** The jitter is drawn from [0, this). */
    const val JITTER_RANGE_MS = 24L * 60 * 60 * 1000

    private const val KEY_JITTER_MS = "heartbeat_jitter_ms"
    private const val KEY_MANUAL_LAT = "heartbeat_manual_lat"
    private const val KEY_MANUAL_LNG = "heartbeat_manual_lng"
    private const val KEY_LAST_RUN_AT = "heartbeat_last_run_at"
    private const val KEY_LAST_OUTCOME = "heartbeat_last_outcome"

    /**
     * Creates the single periodic job, or keeps the one already there — its
     * schedule is static, so `KEEP` costs nothing on a relaunch. Called on
     * every app start, whatever the mode and the location permission.
     */
    fun ensure(context: Context) {
        val request = PeriodicWorkRequest.Builder(
            ReportHeartbeatWorker::class.java,
            PERIOD_HOURS,
            TimeUnit.HOURS,
        )
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            .addTag(TAG)
            .build()
        WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
            UNIQUE_WORK,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    /**
     * This install's fixed share of [JITTER_RANGE_MS], drawn once and kept.
     *
     * Without it, every device that went quiet at the same moment — a release,
     * an outage that failed every report — would come due at the same moment
     * three days later, and so would every heartbeat after it.
     */
    fun jitterMs(context: Context, random: Random = Random.Default): Long {
        val prefs = BgLocationStore.prefs(context)
        if (prefs.contains(KEY_JITTER_MS)) return prefs.getLong(KEY_JITTER_MS, 0L)
        val jitter = random.nextLong(0L, JITTER_RANGE_MS)
        prefs.edit().putLong(KEY_JITTER_MS, jitter).apply()
        return jitter
    }

    /** The pinned township's reporting point, sent instead of the last report's. */
    fun setManualPoint(context: Context, lat: Double, lng: Double) {
        BgLocationStore.prefs(context).edit()
            .putLong(KEY_MANUAL_LAT, lat.toRawBits())
            .putLong(KEY_MANUAL_LNG, lng.toRawBits())
            .apply()
    }

    fun clearManualPoint(context: Context) {
        BgLocationStore.prefs(context).edit()
            .remove(KEY_MANUAL_LAT)
            .remove(KEY_MANUAL_LNG)
            .apply()
    }

    internal fun manualPoint(context: Context): Point? {
        val prefs = BgLocationStore.prefs(context)
        if (!prefs.contains(KEY_MANUAL_LAT) || !prefs.contains(KEY_MANUAL_LNG)) return null
        return Point(
            Double.fromBits(prefs.getLong(KEY_MANUAL_LAT, 0L)),
            Double.fromBits(prefs.getLong(KEY_MANUAL_LNG, 0L)),
        )
    }

    data class Point(val lat: Double, val lng: Double)

    /** What one run decides, before any request. */
    sealed interface Decision {
        data class Skip(val reason: String) : Decision
        data class Send(val point: Point, val source: String) : Decision
    }

    /**
     * The due rule and the point, as a pure function of what is stored.
     *
     * Due once the last success is **more than** [QUIET_MS] + [jitterMs] old.
     * A last success stamped in the future is a clock that moved, not a recent
     * report, and would otherwise hold the heartbeat off for as long as the
     * clock was wrong; one report puts a sane stamp back.
     */
    internal fun decide(
        now: Long,
        reported: BgLocationStore.Reported?,
        jitterMs: Long,
        manual: Point?,
    ): Decision {
        if (reported == null) return Decision.Skip("no successful report yet")
        val age = now - reported.at
        val threshold = QUIET_MS + jitterMs
        if (age in 0..threshold) {
            return Decision.Skip("not due, last success ${age / HOUR_MS} h ago")
        }
        return if (manual != null) {
            Decision.Send(manual, "pinned township")
        } else {
            Decision.Send(Point(reported.lat, reported.lng), "last reported point")
        }
    }

    /**
     * One heartbeat: decide, send at most once, and leave a trace. A failure
     * of any kind — a 429 included — only leaves the trace; the record stays
     * as it was, so the next daily run is due again and retries.
     */
    fun run(context: Context, now: Long): String {
        val outcome = try {
            when (
                val decision = decide(
                    now,
                    BgLocationStore.reported(context),
                    jitterMs(context),
                    manualPoint(context),
                )
            ) {
                is Decision.Skip -> decision.reason
                is Decision.Send -> {
                    val code = BgLocationStore.reportOnce(
                        context,
                        now,
                        decision.point.lat,
                        decision.point.lng,
                    )
                    "due, ${decision.source}: " + when {
                        code == null -> "a report went out inside the last minute, skipped"
                        code == BgLocationStore.NO_TOKEN -> "no push token, not sent"
                        code == BgLocationStore.NO_VERSION -> "no app version, not sent"
                        code in 200..299 -> "sent ($code)"
                        code < 0 -> "failed (no answer)"
                        else -> "failed ($code)"
                    }
                }
            }
        } catch (error: Exception) {
            "failed: ${error.javaClass.simpleName}"
        }
        BgLocationStore.prefs(context).edit()
            .putLong(KEY_LAST_RUN_AT, now)
            .putString(KEY_LAST_OUTCOME, outcome)
            .apply()
        BgLocationStore.note(context, "heartbeat: $outcome")
        return outcome
    }

    /**
     * The heartbeat's own evidence for the developer page, beside — never
     * inside — the background path's. Call off the main thread: the job
     * state is a WorkManager future.
     */
    fun diagnostics(context: Context): Map<String, Any?> {
        val state = try {
            WorkManager.getInstance(context.applicationContext)
                .getWorkInfosForUniqueWork(UNIQUE_WORK)
                .get(2, TimeUnit.SECONDS)
                .firstOrNull { !it.state.isFinished }
                ?.state
                ?.name
                ?.lowercase()
                ?: "missing"
        } catch (_: Exception) {
            "query unavailable"
        }
        val prefs = BgLocationStore.prefs(context)
        val reported = BgLocationStore.reported(context)
        return mapOf(
            "heartbeatState" to state,
            "heartbeatLastRunAt" to prefs.getLong(KEY_LAST_RUN_AT, 0L).takeIf { it > 0L },
            "heartbeatLastOutcome" to prefs.getString(KEY_LAST_OUTCOME, null),
            "heartbeatDueAt" to reported?.let { it.at + QUIET_MS + jitterMs(context) },
            "reportedAt" to reported?.at,
        )
    }

    private const val HOUR_MS = 60L * 60 * 1000
}

/** The daily entry point; always succeeds, because the next run is the retry. */
class ReportHeartbeatWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {
    override fun doWork(): Result {
        ReportHeartbeat.run(applicationContext, System.currentTimeMillis())
        return Result.success()
    }
}
