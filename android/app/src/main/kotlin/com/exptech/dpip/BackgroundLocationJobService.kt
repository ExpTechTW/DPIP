package com.exptech.dpip

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.app.job.JobWorkItem
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/** Performs every long-running background-location operation outside receivers. */
class BackgroundLocationJobService : JobService() {
    companion object {
        const val REASON_START = "start"
        const val REASON_CONFIG = "config"
        const val REASON_PERMISSION_RESTORED = "permission-restored"
        const val REASON_ALARM = "alarm"
        const val REASON_GEOFENCE_EXIT = "geofence-exit"
        const val REASON_GEOFENCE_ERROR = "geofence-error"
        const val REASON_BOOT = "boot"
        const val REASON_WATCHDOG = "watchdog"

        private const val JOB_ID = 888892
        private const val EXTRA_REASON = "reason"
        private const val EXTRA_HAS_LOCATION = "has_location"
        private const val EXTRA_LAT = "lat"
        private const val EXTRA_LNG = "lng"
        private val executor = Executors.newSingleThreadExecutor()

        /** Queues an event without starting location or network work in the caller. */
        fun enqueue(context: Context, reason: String, location: Location? = null): Boolean {
            val app = context.applicationContext
            val intent = Intent()
                .putExtra(EXTRA_REASON, reason)
                .putExtra(EXTRA_HAS_LOCATION, location != null)
            if (location != null) {
                intent.putExtra(EXTRA_LAT, location.latitude)
                intent.putExtra(EXTRA_LNG, location.longitude)
            }
            val scheduler = app.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
            var accepted = submit(scheduler, jobInfo(app, expedited = true), intent, app)
            if (!accepted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Expedited quota is finite. A failed expedited enqueue must not
                // lose the event; fall back to the immediate regular-job path.
                accepted = submit(scheduler, jobInfo(app, expedited = false), intent, app)
            }
            if (!accepted) {
                BgLocationStore.note(app, "job enqueue failed: $reason")
            }
            return accepted
        }

        private fun jobInfo(context: Context, expedited: Boolean): JobInfo {
            val builder = JobInfo.Builder(
                JOB_ID,
                ComponentName(context, BackgroundLocationJobService::class.java),
            )
            if (expedited && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setExpedited(true)
            } else {
                // API 26–30 has no expedited jobs. A zero deadline is the
                // platform-supported way to avoid batching urgent work there.
                builder.setOverrideDeadline(0L)
            }
            return builder.build()
        }

        private fun submit(
            scheduler: JobScheduler,
            info: JobInfo,
            intent: Intent,
            context: Context,
        ): Boolean = try {
            scheduler.enqueue(info, JobWorkItem(intent)) == JobScheduler.RESULT_SUCCESS
        } catch (error: RuntimeException) {
            BgLocationStore.note(context, "job enqueue threw: ${error.javaClass.simpleName}")
            false
        }

        fun cancel(context: Context) {
            val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
            scheduler.cancel(JOB_ID)
        }
    }

    private val generation = AtomicInteger()
    private val main = Handler(Looper.getMainLooper())

    override fun onStartJob(params: JobParameters): Boolean {
        val run = generation.incrementAndGet()
        executor.execute { drain(params, run) }
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        generation.incrementAndGet()
        // An incomplete JobWorkItem is redelivered when constraints allow.
        return BgLocationStore.enabled(applicationContext)
    }

    private fun drain(params: JobParameters, run: Int) {
        while (generation.get() == run) {
            val item = params.dequeueWork() ?: break
            try {
                handle(item.intent)
            } catch (error: Exception) {
                BgLocationStore.note(
                    applicationContext,
                    "job failed: ${error.javaClass.simpleName}: ${error.message}",
                )
            }
            if (generation.get() != run) return
            params.completeWork(item)
        }
        if (generation.get() != run) return
        main.post {
            if (generation.get() == run) jobFinished(params, false)
        }
    }

    private fun handle(intent: Intent) {
        val app = applicationContext
        if (!BgLocationStore.enabled(app)) return
        val reason = intent.getStringExtra(EXTRA_REASON).orEmpty()
        BgLocationStore.note(app, "job: $reason")

        val permitted = GeofenceManager.hasPermission(app)
        BgLocationStore.setPermissionReady(app, permitted)
        if (!permitted) {
            BgLocationStore.setArmed(app, false)
            BgLocationStore.note(app, "job: background location unavailable")
            if (reason == REASON_ALARM) scheduleAfterMissingFix(app)
            return
        }

        val location = suppliedLocation(intent) ?: currentLocation(app)
        if (!BgLocationStore.enabled(app)) return
        val nextAlarm = if (reason == REASON_ALARM) {
            val current = LocationAlarmScheduler.storedInterval(app)
            val next = if (location == null) {
                (current + 5).coerceAtMost(LocationAlarmScheduler.MAX_INTERVAL_MIN)
            } else {
                LocationAlarmScheduler.nextIntervalMinutes(
                    distanceFromLast(app, location),
                    current,
                )
            }
            BgLocationStore.prefs(app).edit()
                .putLong(BgLocationStore.KEY_INTERVAL_MIN, next)
                .apply()
            next
        } else {
            null
        }

        if (location != null) {
            if (GmsAvailability.available(app)) {
                registerAndWait(app, location.latitude, location.longitude)
            } else {
                BgLocationStore.setArmed(app, false)
                BgLocationStore.saveLast(app, location.latitude, location.longitude)
            }
            if (!BgLocationStore.enabled(app)) return
            BgLocationStore.report(app, location.latitude, location.longitude)
        } else {
            BgLocationStore.note(app, "job: no fix for $reason")
            reRegisterLastCentre(app)
        }

        if (reason == REASON_ALARM && BgLocationStore.enabled(app)) {
            LocationAlarmScheduler.schedule(
                app,
                nextAlarm ?: LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
            )
        }
    }

    private fun scheduleAfterMissingFix(context: Context) {
        val next = (LocationAlarmScheduler.storedInterval(context) + 5)
            .coerceAtMost(LocationAlarmScheduler.MAX_INTERVAL_MIN)
        BgLocationStore.prefs(context).edit()
            .putLong(BgLocationStore.KEY_INTERVAL_MIN, next)
            .apply()
        LocationAlarmScheduler.schedule(context, next)
    }

    private fun suppliedLocation(intent: Intent): Location? {
        if (!intent.getBooleanExtra(EXTRA_HAS_LOCATION, false)) return null
        return Location("geofence").apply {
            latitude = intent.getDoubleExtra(EXTRA_LAT, 0.0)
            longitude = intent.getDoubleExtra(EXTRA_LNG, 0.0)
        }
    }

    private fun currentLocation(context: Context): Location? {
        if (GmsAvailability.available(context)) {
            try {
                FusedFix.get(context)?.let { return it }
            } catch (error: Exception) {
                BgLocationStore.note(context, "fused fix failed: ${error.javaClass.simpleName}")
            }
        }
        return LocationFetcher.getFix(context)
    }

    private fun registerAndWait(context: Context, lat: Double, lng: Double) {
        val settled = CountDownLatch(1)
        GeofenceManager.register(context, lat, lng) { armed ->
            BgLocationStore.note(
                context,
                if (armed) {
                    "geofence registration accepted"
                } else {
                    "geofence registration failed"
                },
            )
            settled.countDown()
        }
        if (!settled.await(10, TimeUnit.SECONDS)) {
            BgLocationStore.note(context, "geofence registration timed out")
        }
    }

    private fun reRegisterLastCentre(context: Context) {
        if (!GmsAvailability.available(context) || !BgLocationStore.hasLast(context)) return
        registerAndWait(
            context,
            BgLocationStore.lastLat(context),
            BgLocationStore.lastLng(context),
        )
    }

    private fun distanceFromLast(context: Context, location: Location): Double? {
        if (!BgLocationStore.hasLast(context)) return null
        val results = FloatArray(1)
        Location.distanceBetween(
            BgLocationStore.lastLat(context),
            BgLocationStore.lastLng(context),
            location.latitude,
            location.longitude,
            results,
        )
        return results[0].toDouble()
    }
}
