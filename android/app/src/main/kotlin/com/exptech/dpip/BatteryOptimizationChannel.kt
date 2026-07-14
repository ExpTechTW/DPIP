package com.exptech.dpip

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reports and requests exemption from Android battery optimization (Doze), so
 * background disaster reporting keeps running. Drives the onboarding "省電白名單"
 * step. Requesting shows the system exemption dialog; the app can't await the
 * user's choice, so callers re-check [isIgnoring] on resume.
 */
class BatteryOptimizationChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/battery_optimization"
    }

    @SuppressLint("BatteryLife")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isIgnoring" -> {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                result.success(pm.isIgnoringBatteryOptimizations(context.packageName))
            }

            "request" -> {
                try {
                    val intent = Intent(
                        Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                        Uri.parse("package:${context.packageName}"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("battery_request_failed", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }
}
