package com.exptech.dpip

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Starts/stops autonomous background device-location reporting — the Android
 * counterpart of iOS `BackgroundLocationPlugin`.
 *
 * Fast path (with Google Play services): a low-power **EXIT geofence**. An
 * independent 10–30 minute alarm remains behind it on every Android device and
 * repairs silent geofence loss. Long work runs in [BackgroundLocationJobService].
 * The foreground `DeviceLocationReporter` covers the app-open case; this is the
 * terminated/background safety net.
 */
class BackgroundLocationChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/background_location"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val token = call.argument<String>("token")
                val version = call.argument<String>("version")
                val platform = call.argument<Number>("platform")?.toInt()
                if (token == null || version == null || platform == null) {
                    result.error("bad_args", "Missing start args", null)
                    return
                }
                val wasEnabled = BgLocationStore.enabled(context)
                val sameConfig = BgLocationStore.configMatches(
                    context, token, version, platform,
                )
                val hadPermission = BgLocationStore.permissionReady(context)
                val hasPermission = GeofenceManager.hasPermission(context)

                if (!sameConfig) BgLocationStore.saveConfig(context, token, version, platform)
                BgLocationStore.setPermissionReady(context, hasPermission)
                LocationAlarmScheduler.ensure(context)
                BackgroundLocationWatchdog.ensure(context)

                // An unchanged start preserves both scheduler deadlines and does
                // no location work. Flutter calls this on resume; re-registering
                // the fence and taking a fix there caused the foreground wake storm.
                val reason = when {
                    !sameConfig && !wasEnabled -> BackgroundLocationJobService.REASON_START
                    hasPermission && !hadPermission ->
                        BackgroundLocationJobService.REASON_PERMISSION_RESTORED
                    !sameConfig -> BackgroundLocationJobService.REASON_CONFIG
                    else -> null
                }
                if (!hasPermission) {
                    BgLocationStore.setArmed(context, false)
                } else if (reason != null) {
                    BgLocationStore.note(
                        context,
                        "start: $reason gms=${GmsAvailability.available(context)}",
                    )
                    BackgroundLocationJobService.enqueue(context, reason)
                }
                result.success(null)
            }

            "stop" -> {
                BgLocationStore.disable(context)
                GeofenceManager.remove(context)
                LocationAlarmScheduler.cancel(context)
                BackgroundLocationWatchdog.cancel(context)
                BackgroundLocationJobService.cancel(context)
                result.success(null)
            }

            // WorkManager exposes real work state asynchronously. Query it off
            // the platform thread so opening Developer diagnostics cannot stall UI.
            "diagnostics" -> Thread {
                val snapshot = diagnostics()
                Handler(Looper.getMainLooper()).post { result.success(snapshot) }
            }.start()

            // Everything the background path recorded since the last drain, so
            // it can be written into the app's own log. A BroadcastReceiver has
            // no Flutter isolate, so nothing it does could reach `Log` — the
            // whole Android background path was invisible to the one diagnostic
            // a user is able to send.
            "drainBreadcrumbs" ->
                result.success(BgLocationStore.drainBreadcrumbs(context))

            // Runs the report path now, with the fix the OS last had. Makes the
            // background path testable without waiting for a geofence crossing,
            // which is the wait that has blocked every previous attempt at this.
            // Answered only once the work is done, on the main thread: the
            // caller re-reads the diagnostics the moment this returns, and
            // replying early would show it the *previous* attempt's outcome
            // and call it this one's.
            "reportNow" -> {
                val app = context.applicationContext
                Thread {
                    val fix = FusedFix.get(app)
                    if (fix == null) {
                        BgLocationStore.note(app, "reportNow: no fix")
                    } else {
                        BgLocationStore.note(app, "reportNow: reporting")
                        BgLocationStore.report(app, fix.latitude, fix.longitude)
                    }
                    Handler(Looper.getMainLooper()).post { result.success(null) }
                }.start()
            }

            else -> result.notImplemented()
        }
    }

    /**
     * A snapshot of whether background reporting is actually working, for the
     * developer page. Keys are shared with the iOS plugin so one UI renders both.
     *
     * The Geofencing API and AlarmManager expose no query for live registrations,
     * so diagnostics report the last accepted registration/scheduling calls and
     * the independent delivery/HTTP evidence beside them.
     */
    private fun diagnostics(): Map<String, Any?> {
        val prefs = BgLocationStore.prefs(context)
        val gms = GmsAvailability.available(context)
        // Armed means "something can actually produce a fix", not "something is
        // scheduled". Both spines need ACCESS_BACKGROUND_LOCATION: without it
        // `GeofenceManager.register` refuses and `LocationFetcher.getFix`
        // returns null on every alarm — so the page used to read
        // `armed: yes · spine: alarm` on precisely the device that could never
        // report, which is the healthiest-looking possible reading of the
        // broken state.
        val canFix = GeofenceManager.hasPermission(context)
        val fenceArmed = BgLocationStore.armed(context) && canFix
        val alarmArmed = LocationAlarmScheduler.isScheduled(context) && canFix
        val legacyAttemptAt = prefs.getLong(BgLocationStore.KEY_LEGACY_LAST_REPORT_AT, 0L)
        val attemptAt = prefs.getLong(BgLocationStore.KEY_LAST_ATTEMPT_AT, legacyAttemptAt)
        val legacyAttemptOk = prefs.getBoolean(BgLocationStore.KEY_LEGACY_LAST_REPORT_OK, false)
        val attemptOk = if (prefs.contains(BgLocationStore.KEY_LAST_ATTEMPT_OK)) {
            prefs.getBoolean(BgLocationStore.KEY_LAST_ATTEMPT_OK, false)
        } else {
            legacyAttemptOk
        }
        val legacyAttemptCode = prefs.getInt(BgLocationStore.KEY_LEGACY_LAST_REPORT_CODE, -1)
        val attemptCode = if (prefs.contains(BgLocationStore.KEY_LAST_ATTEMPT_CODE)) {
            prefs.getInt(BgLocationStore.KEY_LAST_ATTEMPT_CODE, -1)
        } else {
            legacyAttemptCode
        }
        val successAt = prefs.getLong(
            BgLocationStore.KEY_LAST_SUCCESS_AT,
            if (legacyAttemptOk) legacyAttemptAt else 0L,
        )
        val successCode = prefs.getInt(
            BgLocationStore.KEY_LAST_SUCCESS_CODE,
            if (legacyAttemptOk) legacyAttemptCode else 0,
        )
        return mapOf(
            "enabled" to BgLocationStore.enabled(context),
            "authorization" to authorization(),
            "armed" to (fenceArmed || alarmArmed),
            "spine" to when {
                fenceArmed -> "geofence"
                alarmArmed -> "alarm"
                else -> "none"
            },
            "hasToken" to (prefs.getString(BgLocationStore.KEY_TOKEN, null) != null),
            "blocked" to if (canFix) null else "background location not granted",
            // Wake counters. The first question in any background bug is
            // whether the OS ever called us, and nothing answered it before.
            "wakeGeofence" to prefs.getInt("wake_geofence_n", 0),
            "wakeAlarm" to prefs.getInt("wake_alarm_n", 0),
            "wakeBoot" to prefs.getInt("wake_boot_n", 0),
            "lastGeofenceError" to prefs.getInt("last_geofence_error", 0)
                .takeIf { it != 0 }
                ?.toString(),
            "lastGeofenceTransitionAt" to prefs
                .getLong("last_geofence_transition_at", 0L)
                .takeIf { it > 0L },
            "lastAttemptAt" to attemptAt.takeIf { it > 0L },
            "lastAttemptOk" to attemptOk.takeIf { attemptAt > 0L },
            "lastAttemptCode" to attemptCode.takeIf { attemptAt > 0L },
            "lastSuccessAt" to successAt.takeIf { it > 0L },
            "lastSuccessCode" to successCode.takeIf { successAt > 0L },
            "lastThrottledAt" to prefs.getLong(BgLocationStore.KEY_LAST_THROTTLED_AT, 0L)
                .takeIf { it > 0L },
            "throttledCount" to prefs.getInt(BgLocationStore.KEY_THROTTLED_N, 0),
            "nextAlarmAt" to LocationAlarmScheduler.nextWallTime(context),
            "centreLat" to (
                if (BgLocationStore.hasLast(context)) BgLocationStore.lastLat(context) else null
                ),
            "centreLng" to (
                if (BgLocationStore.hasLast(context)) BgLocationStore.lastLng(context) else null
                ),
            "detail" to buildString {
                append(if (gms) "Play services available" else "no Play services")
                append(", geofence ").append(if (fenceArmed) "armed" else "not armed")
                append(", alarm ")
                if (alarmArmed) {
                    append("scheduled, adaptive ")
                        .append(LocationAlarmScheduler.storedInterval(context))
                        .append(" min")
                } else {
                    append("not scheduled")
                }
            },
        ) + BackgroundLocationWatchdog.diagnostics(context)
    }

    /** The OS location authorization, in the same vocabulary the iOS side uses. */
    private fun authorization(): String {
        val fine = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        if (!fine && !coarse) return "denied"
        // ACCESS_BACKGROUND_LOCATION only exists from Q; before that, a
        // foreground grant already covered background use.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return "always"
        val background = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_BACKGROUND_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        return if (background) "always" else "whenInUse"
    }

}
