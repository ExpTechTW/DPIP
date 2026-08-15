package com.exptech.dpip

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import androidx.core.content.PackageManagerCompat
import androidx.core.content.UnusedAppRestrictionsConstants
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reports and opens the setting behind Android's **unused-app restrictions** —
 * permission auto-reset and app hibernation.
 *
 * This is the one system behaviour that silently ends background disaster
 * reporting for precisely the users it exists to protect: someone who installs
 * DPIP, grants "Allow all the time", and then never opens it again because
 * nothing has happened. After a few months of no interaction Android revokes
 * the runtime permissions it granted, and from Android 12 also *force-stops*
 * the package and clears its caches.
 *
 * Neither the geofence nor the alarm survives that. A force-stopped package is
 * in the stopped state and receives no broadcasts at all — `BOOT_COMPLETED`
 * included — until the user explicitly launches it, so the boot re-arm cannot
 * recover it; on Android 15 force-stop additionally cancels the app's
 * `PendingIntent`s, which takes the geofence and the alarm outright. Meanwhile
 * `BgLocationStore.enabled` is still true, so nothing in the app believes
 * anything is wrong.
 *
 * It is not a permission and cannot be requested: the exemption is a toggle the
 * user sets in system settings, so all this can do is report the state and take
 * them there. Distinct from the battery-optimization exemption
 * ([BatteryOptimizationChannel]), which covers Doze and does not cover this.
 *
 * OEM "sleeping apps" managers (Samsung, MIUI, EMUI) apply the same stopped
 * state on a days-not-months timescale and are not reachable through this API;
 * they need the user to exempt the app in the vendor's own battery UI.
 */
class UnusedAppRestrictionsChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/unused_app_restrictions"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> status(result)

            "openSettings" -> {
                try {
                    val intent = IntentCompat.createManageUnusedAppRestrictionsIntent(
                        context, context.packageName,
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("unused_app_restrictions_failed", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Resolves to `"exempt"`, `"restricted"` or `"unavailable"`.
     *
     * `DISABLED` is the good state — the user has turned restrictions *off* for
     * this app, so nothing will hibernate it. Every flavour of "on"
     * (`API_30_BACKPORT` on 6–10 via Play services, `API_30` auto-reset,
     * `API_31` full hibernation) is reported the same way, because the fix the
     * user has to make is identical and the version is already on the
     * developer page.
     *
     * The result callback must fire exactly once and on the main thread, which
     * is why the listener runs on the main executor rather than the future's
     * completing thread.
     */
    private fun status(result: MethodChannel.Result) {
        try {
            val future = PackageManagerCompat.getUnusedAppRestrictionsStatus(context)
            future.addListener(
                {
                    val value = try {
                        when (future.get()) {
                            UnusedAppRestrictionsConstants.DISABLED -> "exempt"
                            UnusedAppRestrictionsConstants.API_30_BACKPORT,
                            UnusedAppRestrictionsConstants.API_30,
                            UnusedAppRestrictionsConstants.API_31,
                            -> "restricted"
                            // ERROR and FEATURE_NOT_AVAILABLE both mean "this
                            // device cannot tell us", which must not be shown as
                            // a problem the user can fix.
                            else -> "unavailable"
                        }
                    } catch (e: Exception) {
                        "unavailable"
                    }
                    result.success(value)
                },
                ContextCompat.getMainExecutor(context),
            )
        } catch (e: Exception) {
            result.success("unavailable")
        }
    }
}
