package com.exptech.dpip

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Returns basic device identity, replacing the `device_info_plus` plugin. */
class DeviceInfoChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/device_info"
    }

    @SuppressLint("HardwareIds")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceInfo" -> result.success(
                mapOf(
                    "model" to Build.MODEL,
                    "osVersion" to Build.VERSION.RELEASE,
                    "sdkInt" to Build.VERSION.SDK_INT,
                    "identifier" to Settings.Secure.getString(
                        context.contentResolver,
                        Settings.Secure.ANDROID_ID,
                    ),
                ),
            )
            else -> result.notImplemented()
        }
    }
}
