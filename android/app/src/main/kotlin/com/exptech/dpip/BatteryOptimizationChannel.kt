package com.exptech.dpip

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reports and requests exemption from Android battery optimization (Doze), so
 * background disaster reporting keeps running. Drives the onboarding "省電白名單"
 * step. Requesting shows the system exemption dialog; the app can't await the
 * user's choice, so callers re-check [isIgnoring] on resume.
 *
 * Three screens can be involved, and which exist is a property of the ROM:
 * the package-scoped grant dialog, the system's exemption list, and the app's
 * own settings page. The first two are the only ones that change the setting,
 * so a device that has neither gets no row at all — see [canOpen].
 */
class BatteryOptimizationChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/battery_optimization"
        private const val TAG = "BatteryOptimization"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isIgnoring" -> {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                result.success(pm.isIgnoringBatteryOptimizations(context.packageName))
            }

            "canOpen" -> result.success(canOpen())

            // Answers with where it landed — `dialog`, `list`, `appDetails` or
            // `none` — so the caller can log it instead of guessing why a tap
            // appeared to do nothing.
            "request" -> result.success(request())

            else -> result.notImplemented()
        }
    }

    /**
     * The destinations [request] tries, narrowest first.
     *
     * The dialog is a one-tap grant. The list page is the form Google tells
     * most apps to use, and some ROMs ship it instead of the dialog. The app
     * details page takes no package data and is where a user can still reach
     * battery settings by hand, so it is the last resort rather than a
     * destination of its own.
     */
    @SuppressLint("BatteryLife")
    private fun screens(): List<Intent> = listOf(
        Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:${context.packageName}"),
        ),
        Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
        Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${context.packageName}"),
        ),
    ).onEach { it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

    /**
     * Whether a screen that actually controls the exemption exists here.
     *
     * The app details page is deliberately excluded: it is not where this
     * setting lives, so a device that only has it has nothing this row could
     * change and the row is hidden instead of opening the wrong page.
     */
    private fun canOpen(): Boolean {
        return try {
            screens().take(2).any { context.packageManager.resolveActivity(it, 0) != null }
        } catch (e: Exception) {
            // A failed probe is not a "no" — hiding a row the user can still
            // fix would be the worse of the two errors.
            Log.w(TAG, "cannot resolve a battery screen", e)
            true
        }
    }

    /** Opens the first screen that exists, and names it for the log. */
    private fun request(): String {
        for ((index, intent) in screens().withIndex()) {
            try {
                context.startActivity(intent)
                return when (index) {
                    0 -> "dialog"
                    1 -> "list"
                    else -> "appDetails"
                }
            } catch (e: Exception) {
                Log.i(TAG, "battery screen $index unavailable", e)
            }
        }
        return "none"
    }
}
