package com.exptech.dpip

import android.annotation.SuppressLint
import android.app.ActivityManager
import android.content.Context
import android.content.pm.ApplicationInfo
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
     * the user. A debuggable build (flutter run, Android Studio, adb) is a
     * development environment and says so: the flag is part of the build, not
     * an installer record, so it holds even though adb leaves no installer. A
     * non-store release has no store page to update from and gets the GitHub
     * release instead.
     */
    private fun installSource(): String {
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            return "development"
        }
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
            // running); an unknown installer means no store did it.
            null
        }
        return if (installer == "com.android.vending") "playStore" else "github"
    }

    /** Total physical RAM in MiB — the cheap proxy for the low-end tier. */
    private fun totalMemoryMb(): Long {
        val mem = ActivityManager.MemoryInfo()
        (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
            .getMemoryInfo(mem)
        return mem.totalMem / 1024 / 1024
    }
}
