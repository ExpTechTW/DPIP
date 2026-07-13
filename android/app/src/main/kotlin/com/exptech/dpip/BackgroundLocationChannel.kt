package com.exptech.dpip

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Starts/stops autonomous background device-location reporting — the Android
 * counterpart of iOS `BackgroundLocationPlugin`. It drives
 * [LocationForegroundService], which keeps reporting to `updateDeviceLocation`
 * on distance-triggered moves while the app is backgrounded, so the report
 * doesn't need the Flutter isolate alive. The foreground `DeviceLocationReporter`
 * covers the app-open case; this is the terminated-state safety net.
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
                val intent = Intent(context, LocationForegroundService::class.java).apply {
                    action = LocationForegroundService.ACTION_START
                    putExtra(LocationForegroundService.EXTRA_TOKEN, token)
                    putExtra(LocationForegroundService.EXTRA_VERSION, version)
                    putExtra(LocationForegroundService.EXTRA_PLATFORM, platform)
                }
                ContextCompat.startForegroundService(context, intent)
                result.success(null)
            }

            "stop" -> {
                context.stopService(
                    Intent(context, LocationForegroundService::class.java),
                )
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
