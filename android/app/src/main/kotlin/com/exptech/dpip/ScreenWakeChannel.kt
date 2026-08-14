package com.exptech.dpip

import android.app.Activity
import android.view.WindowManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Keeps the display on while a screen asks for it — the mesh conversation, so
 * a radio being watched doesn't go dark mid-exchange.
 *
 * Uses the window flag rather than a `PowerManager` wake lock on purpose: the
 * flag is scoped to this activity's visibility, so the screen stops being held
 * the moment the app is backgrounded or the activity is destroyed. A wake lock
 * would outlive both and could be leaked into the background.
 *
 * Takes the Activity, not the application context: window flags belong to a
 * window.
 */
class ScreenWakeChannel(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/screen_wake"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enable" -> {
                activity.runOnUiThread {
                    activity.window.addFlags(
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    )
                }
                result.success(null)
            }

            "disable" -> {
                activity.runOnUiThread {
                    activity.window.clearFlags(
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    )
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
