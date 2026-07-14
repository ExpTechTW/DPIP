package com.exptech.dpip

import android.content.Context
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
                    // Exactly one spine active: drop any leftover alarm.
                    LocationAlarmScheduler.cancel(context)
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

            else -> result.notImplemented()
        }
    }

    // Take an initial fix off the main thread, report it, and arm the geofence
    // around it. If no fix lands this launch, nothing is armed — the after-frame
    // start() retries on the next app open.
    private fun armGeofence(appContext: Context) {
        Thread {
            try {
                val location = FusedFix.get(appContext)
                if (location != null && BgLocationStore.enabled(appContext)) {
                    // Arm the fence first (spine safety), then report.
                    GeofenceManager.register(appContext, location.latitude, location.longitude)
                    BgLocationStore.report(appContext, location.latitude, location.longitude)
                }
            } catch (e: Exception) {
                // Best-effort; the next app open retries.
            }
        }.start()
    }
}
