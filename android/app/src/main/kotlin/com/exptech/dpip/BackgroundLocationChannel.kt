package com.exptech.dpip

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
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
                if (GmsAvailability.available(context)) {
                    // The alarm is NOT cancelled here. Arming the geofence needs
                    // a fix, and getting one can fail — location off at that
                    // moment, a 15 s BALANCED timeout indoors, no fresh cached
                    // fix. Cancelling first meant a failed arm left the device
                    // with neither spine and nothing scheduled to retry, so
                    // background reporting silently stopped until the next time
                    // the user opened the app. [armGeofence] stands the alarm
                    // down only once Play services confirms a fence is live.
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
                    ensureAlarm(appContext)
                    return@Thread
                }
                if (!BgLocationStore.enabled(appContext)) return@Thread
                // Arm the fence first (spine safety), then report.
                GeofenceManager.register(appContext, location.latitude, location.longitude) { armed ->
                    if (armed) {
                        LocationAlarmScheduler.cancel(appContext)
                    } else {
                        Log.w(TAG, "geofence refused — falling back to the alarm")
                        ensureAlarm(appContext)
                    }
                }
                BgLocationStore.report(appContext, location.latitude, location.longitude)
            } catch (e: Exception) {
                Log.w(TAG, "background location arm failed", e)
                ensureAlarm(appContext)
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
        val fenceArmed = BgLocationStore.armed(context)
        val alarmArmed = LocationAlarmScheduler.isScheduled(context)
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

    /** Schedules the fallback alarm at its stored interval, or the default. */
    private fun ensureAlarm(appContext: Context) {
        if (!BgLocationStore.enabled(appContext)) return
        val interval = BgLocationStore.prefs(appContext).getLong(
            BgLocationStore.KEY_INTERVAL_MIN,
            LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
        )
        LocationAlarmScheduler.schedule(appContext, interval)
    }
}
