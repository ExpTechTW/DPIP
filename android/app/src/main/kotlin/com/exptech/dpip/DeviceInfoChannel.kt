package com.exptech.dpip

import android.annotation.SuppressLint
import android.app.ActivityManager
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
                    "manufacturer" to Build.MANUFACTURER,
                    "model" to Build.MODEL,
                    "osVersion" to Build.VERSION.RELEASE,
                    "sdkInt" to Build.VERSION.SDK_INT,
                    "identifier" to Settings.Secure.getString(
                        context.contentResolver,
                        Settings.Secure.ANDROID_ID,
                    ),
                    "totalMemoryMb" to totalMemoryMb(),
                ),
            )
            "getInstallSource" -> result.success(installSource())
            else -> result.notImplemented()
        }
    }

    /**
     * Where this build came from — which decides where an update prompt sends
     * the user. A sideloaded APK has no store page to update from, so it is
     * reported as such and gets the GitHub release instead.
     */
    private fun installSource(): String {
        val installer = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.packageManager
                    .getInstallSourceInfo(context.packageName)
                    .installingPackageName
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getInstallerPackageName(context.packageName)
            }
        } catch (e: Exception) {
            // The package can be queried out from under us (uninstalling while
            // running); an unknown installer is a sideload for our purposes.
            null
        }
        return if (installer == "com.android.vending") "playStore" else "sideload"
    }

    /** Total physical RAM in MiB — the cheap proxy for the low-end tier. */
    private fun totalMemoryMb(): Long {
        val mem = ActivityManager.MemoryInfo()
        (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
            .getMemoryInfo(mem)
        return mem.totalMem / 1024 / 1024
    }
}
