package com.exptech.dpip

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hands the native log buffer to Dart and clears it in the same call.
 *
 * `take` reads the file and replaces it only after that read returns. An I/O
 * error is returned to Dart with the file left as it was.
 */
class NativeLogChannel(context: Context) : MethodChannel.MethodCallHandler {
    private val log = NativeLogs.open(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "take" -> {
                try {
                    result.success(log.take())
                } catch (_: Exception) {
                    result.error("native_log_io", "native log handoff failed", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val NAME = "com.exptech.dpip/native_log"
    }
}
