package com.exptech.dpip

import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Whether the OS will still *run* this app's background work — the layer below
 * permissions, and the one that fails silently.
 *
 * A device can hold every permission DPIP asks for and still never report: the
 * user (or an OEM's battery manager) can put the app in the **restricted**
 * background state, at which point alarms, jobs and network access from the
 * background stop, while every permission still reads "granted". Nothing in the
 * app would notice.
 *
 * Two signals, both AOSP and both readable without a permission:
 *  - [ActivityManager.isBackgroundRestricted] — the user set this app to
 *    "Restricted" in battery settings. Actionable: they can unset it.
 *  - [UsageStatsManager.getAppStandbyBucket] — how aggressively the system is
 *    throttling us. Not directly settable, so it is reported for diagnosis
 *    rather than raised as a problem to fix.
 *
 * **OEM battery managers are not covered by either**, and cannot be. Samsung
 * ("sleeping"/"deep sleeping" apps, after roughly 3 and 16 days of non-use),
 * Xiaomi, Huawei, OPPO and vivo each add a layer with no query API and no
 * exemption intent — Samsung's own guidance for developers is that there is
 * nothing to call. All this class can do is recognise the manufacturer and open
 * the vendor's own screen, which is why [openOemSettings] is a best-effort
 * chain of known component names ending at the standard app-details page rather
 * than a single documented intent.
 */
class BackgroundExecutionChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/background_execution"
        private const val TAG = "BackgroundExecution"

        /**
         * Vendor battery/auto-start screens, tried in order for a manufacturer.
         *
         * Undocumented and version-specific by nature — these are activities in
         * the vendor's own system app, so they move and disappear between OS
         * releases. That is why every one is attempted inside a try/catch and
         * the standard app-details page is the last resort: this can degrade,
         * but it must never throw or dead-end.
         *
         * Deliberately not probed with `resolveActivity` first: on Android 11+
         * package visibility hides these components unless the app declares a
         * `<queries>` entry for each vendor package, so a resolve check would
         * answer "unavailable" on precisely the devices that have the screen.
         * Trying and catching is both simpler and more accurate.
         */
        private val OEM_SCREENS: Map<String, List<ComponentName>> = mapOf(
            "xiaomi" to listOf(
                ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                ),
            ),
            "redmi" to listOf(
                ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                ),
            ),
            "poco" to listOf(
                ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                ),
            ),
            "huawei" to listOf(
                ComponentName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                ),
            ),
            "honor" to listOf(
                ComponentName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                ),
            ),
            "oppo" to listOf(
                ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                ),
            ),
            "realme" to listOf(
                ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                ),
            ),
            "vivo" to listOf(
                ComponentName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                ),
            ),
            "letv" to listOf(
                ComponentName(
                    "com.letv.android.letvsafe",
                    "com.letv.android.letvsafe.AutobootManageActivity",
                ),
            ),
            "tecno" to listOf(
                ComponentName(
                    "com.transsion.phonemaster",
                    "com.cyin.himgr.autostart.AutoStartActivity",
                ),
            ),
            "infinix" to listOf(
                ComponentName(
                    "com.transsion.phonemaster",
                    "com.cyin.himgr.autostart.AutoStartActivity",
                ),
            ),
        )

        /**
         * Manufacturers whose battery manager is known to stop background work
         * on a days-not-months timescale, whether or not [OEM_SCREENS] has a
         * component for them.
         *
         * Samsung and OnePlus are here without a component on purpose: their
         * setting lives inside a screen with no stable entry point, so the row
         * still has to appear (their users are the most affected) but the button
         * can only reach the app-details page.
         */
        private val AGGRESSIVE = setOf(
            "xiaomi", "redmi", "poco", "huawei", "honor", "oppo", "realme",
            "vivo", "oneplus", "samsung", "letv", "tecno", "infinix", "meizu",
            "asus", "nokia", "sony", "zte",
        )
    }

    private val vendor: String get() = Build.MANUFACTURER.lowercase()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            "openOemSettings" -> result.success(openOemSettings())
            else -> result.notImplemented()
        }
    }

    private fun status(): Map<String, Any?> {
        return mapOf(
            "restricted" to backgroundRestricted(),
            "standbyBucket" to standbyBucket(),
            "manufacturer" to Build.MANUFACTURER,
            // Whether to offer the vendor row at all. Keyed on the manufacturer
            // rather than on whether a component resolves, because package
            // visibility makes the latter unanswerable (see OEM_SCREENS).
            "vendorManaged" to (vendor in AGGRESSIVE),
        )
    }

    /**
     * Whether the user put this app in the "Restricted" battery state, or false
     * below API 28 where the state does not exist.
     *
     * The version guard is load-bearing: `minSdk` is 26, and the call compiles
     * against the newer `compileSdk` regardless, so without it API 26–27 devices
     * would take a `NoSuchMethodError` the moment the permission page opened.
     */
    private fun backgroundRestricted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.isBackgroundRestricted
    }

    /**
     * The app's own standby bucket, or null below API 28.
     *
     * `getAppStandbyBucket()` with no argument answers for the caller and needs
     * no `PACKAGE_USAGE_STATS` grant — the permission is only required to ask
     * about *another* package.
     */
    private fun standbyBucket(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
        return try {
            val usage = context.getSystemService(Context.USAGE_STATS_SERVICE)
                as UsageStatsManager
            when (usage.appStandbyBucket) {
                UsageStatsManager.STANDBY_BUCKET_ACTIVE -> "active"
                UsageStatsManager.STANDBY_BUCKET_WORKING_SET -> "workingSet"
                UsageStatsManager.STANDBY_BUCKET_FREQUENT -> "frequent"
                UsageStatsManager.STANDBY_BUCKET_RARE -> "rare"
                // 45, API 31+. Named rather than referenced by constant so this
                // still compiles against an older SDK.
                45 -> "restricted"
                50 -> "never"
                else -> "unknown"
            }
        } catch (e: Exception) {
            Log.w(TAG, "standby bucket unavailable", e)
            null
        }
    }

    /**
     * Opens the vendor's battery/auto-start screen, falling back to the app's
     * own system settings page.
     *
     * Returns the name of what it managed to open, so the caller can tell the
     * user where they landed instead of guessing — "we opened something" is not
     * a useful thing to say when the vendor screen is three menus from where the
     * instructions assume.
     */
    private fun openOemSettings(): String {
        for (component in OEM_SCREENS[vendor].orEmpty()) {
            try {
                context.startActivity(
                    Intent().setComponent(component)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                return "vendor"
            } catch (e: Exception) {
                Log.i(TAG, "vendor screen ${component.className} unavailable", e)
            }
        }
        return try {
            context.startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            "appDetails"
        } catch (e: Exception) {
            Log.w(TAG, "no settings screen could be opened", e)
            "none"
        }
    }
}
