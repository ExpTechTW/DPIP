package com.exptech.dpip

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Starts/stops autonomous background device-location reporting — the Android
 * counterpart of iOS `BackgroundLocationPlugin`.
 *
 * Primary spine (with Google Play services): a low-power, event-driven,
 * OEM-kill-resistant **EXIT geofence** ([GeofenceManager]) — an initial fix is
 * taken and a geofence armed around it; the OS reports only real moves. Fallback
 * (de-Googled devices): the adaptive-interval alarm ([LocationAlarmScheduler]).
 * The foreground `DeviceLocationReporter` covers the app-open case; this is the
 * terminated/background safety net.
 */
class BackgroundLocationChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/background_location"
        private const val TAG = "DpipBgLocation"
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
                BgLocationStore.saveConfig(context, token, version, platform)
                BgLocationStore.note(
                    context,
                    "start: gms=${GmsAvailability.available(context)} " +
                        "bgPermission=${GeofenceManager.hasPermission(context)}",
                )
                if (GmsAvailability.available(context)) {
                    // The alarm is NOT cancelled here. Arming the geofence needs
                    // a fix, and getting one can fail — location off at that
                    // moment, a 15 s BALANCED timeout indoors, no fresh cached
                    // fix. Cancelling first meant a failed arm left the device
                    // with neither spine and nothing scheduled to retry, so
                    // background reporting silently stopped until the next time
                    // the user opened the app. [armGeofence] stands the alarm
                    // down only once Play services confirms a fence is live.
                    //
                    // Schedule before arming, not after. Arming waits on a fix
                    // (up to ~20 s) and then on an asynchronous registration,
                    // and on a first-ever enable — or any stop/start from the
                    // developer page, which cancels the alarm — there is nothing
                    // pending for that whole window. A process death inside it
                    // left reporting enabled with no fence and no alarm, and
                    // nothing that would ever notice.
                    LocationAlarmScheduler.ensure(context)
                    armGeofence(context.applicationContext)
                } else {
                    GeofenceManager.remove(context)
                    BgLocationStore.prefs(context).edit()
                        .putLong(
                            BgLocationStore.KEY_INTERVAL_MIN,
                            LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
                        )
                        .apply()
                    LocationAlarmScheduler.schedule(
                        context, LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
                    )
                }
                result.success(null)
            }

            "stop" -> {
                BgLocationStore.disable(context)
                GeofenceManager.remove(context)
                LocationAlarmScheduler.cancel(context)
                result.success(null)
            }

            "diagnostics" -> result.success(diagnostics())

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

    // Take an initial fix off the main thread, arm the geofence around it, and
    // report it.
    //
    // Every path out of here leaves exactly one spine armed. The geofence is the
    // one worth having — Play services keeps monitoring it after an OEM battery
    // manager kills our process — but it can only be armed from a fix we do not
    // always get, and `addGeofences` can still refuse afterwards. So the alarm
    // stays scheduled until the fence is confirmed live, and is (re)scheduled if
    // it is not. Both running briefly is harmless: the report is an idempotent
    // GET, and the next successful arm cancels the alarm.
    private fun armGeofence(appContext: Context) {
        Thread {
            try {
                val location = FusedFix.get(appContext)
                if (location == null) {
                    Log.w(TAG, "no fix available — geofence not armed, keeping the alarm")
                    BgLocationStore.note(appContext, "arm: no fix, alarm only")
                    LocationAlarmScheduler.ensure(appContext)
                    return@Thread
                }
                if (!BgLocationStore.enabled(appContext)) return@Thread
                // Arm the fence first (spine safety), then report.
                GeofenceManager.register(appContext, location.latitude, location.longitude) { armed ->
                    if (armed) {
                        BgLocationStore.note(appContext, "arm: geofence live")
                        LocationAlarmScheduler.resetWatchdog(appContext)
                    } else {
                        Log.w(TAG, "geofence refused — falling back to the alarm")
                        BgLocationStore.note(appContext, "arm: geofence refused, alarm only")
                        LocationAlarmScheduler.ensure(appContext)
                    }
                }
                BgLocationStore.report(appContext, location.latitude, location.longitude)
            } catch (e: Exception) {
                Log.w(TAG, "background location arm failed", e)
                BgLocationStore.note(appContext, "arm failed: ${e.javaClass.simpleName}: ${e.message}")
                LocationAlarmScheduler.ensure(appContext)
            }
        }.start()
    }

    /**
     * A snapshot of whether background reporting is actually working, for the
     * developer page. Keys are shared with the iOS plugin so one UI renders both.
     *
     * `armed` is the honest answer to "is anything monitoring right now", which
     * is the question a user's bug report needs and the one nothing here could
     * previously answer: the Geofencing API cannot be queried, so it is tracked
     * as state; the alarm can be, via a no-create PendingIntent probe.
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
        val lastReportAt = prefs.getLong(BgLocationStore.KEY_LAST_REPORT_AT, 0L)
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
            "lastGeofenceError" to (
                prefs.getInt("last_geofence_error", 0).takeIf { it != 0 }
            ),
            "lastReportAt" to (if (lastReportAt == 0L) null else lastReportAt),
            "lastReportOk" to (
                if (lastReportAt == 0L) null
                else prefs.getBoolean(BgLocationStore.KEY_LAST_REPORT_OK, false)
                ),
            "lastReportCode" to (
                if (lastReportAt == 0L) null
                else prefs.getInt(BgLocationStore.KEY_LAST_REPORT_CODE, -1)
                ),
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
                    append("scheduled every ")
                        .append(
                            prefs.getLong(
                                BgLocationStore.KEY_INTERVAL_MIN,
                                LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
                            ),
                        )
                        .append(" min")
                } else {
                    append("not scheduled")
                }
            },
        )
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
