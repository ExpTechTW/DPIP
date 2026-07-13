package com.exptech.dpip

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Starts/stops autonomous background device-location reporting — the Android
 * counterpart of iOS `BackgroundLocationPlugin`. Rather than a battery-hungry
 * continuous foreground service, it drives a single self-rescheduling alarm
 * ([LocationAlarmScheduler]) whose interval adapts to movement, so the report to
 * `updateDeviceLocation` keeps targeting the right township with minimal wake-ups
 * while the app is backgrounded. The foreground `DeviceLocationReporter` covers
 * the app-open case; this is the terminated-state safety net.
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
                LocationAlarmScheduler.prefs(context).edit()
                    .putBoolean(LocationAlarmScheduler.KEY_ENABLED, true)
                    .putString(LocationAlarmScheduler.KEY_TOKEN, token)
                    .putString(LocationAlarmScheduler.KEY_VERSION, version)
                    .putInt(LocationAlarmScheduler.KEY_PLATFORM, platform)
                    .putLong(
                        LocationAlarmScheduler.KEY_INTERVAL_MIN,
                        LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
                    )
                    .apply()
                LocationAlarmScheduler.schedule(
                    context, LocationAlarmScheduler.DEFAULT_INTERVAL_MIN,
                )
                result.success(null)
            }

            "stop" -> {
                LocationAlarmScheduler.prefs(context).edit()
                    .putBoolean(LocationAlarmScheduler.KEY_ENABLED, false)
                    .apply()
                LocationAlarmScheduler.cancel(context)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
