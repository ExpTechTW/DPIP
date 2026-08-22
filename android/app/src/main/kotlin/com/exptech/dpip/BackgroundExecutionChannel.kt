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
 * chain of known vendor screens — several OS generations deep per brand —
 * ending at the standard app-details page rather than a single documented
 * intent.
 */
class BackgroundExecutionChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/background_execution"
        private const val TAG = "BackgroundExecution"

        /**
         * One way to reach a vendor's own battery / auto-start screen.
         *
         * Two shapes because the vendors use both: Huawei, Samsung and Meizu
         * publish broadcast-style *actions*, everyone else only has an activity
         * class. Actions are preferred where they exist — they survive the
         * vendor renaming the activity, which is the thing that actually breaks.
         */
        private sealed class Screen {
            data class Action(val name: String) : Screen()
            data class Component(val pkg: String, val cls: String) : Screen()
        }

        /**
         * Vendor screens, tried in order until one opens.
         *
         * Sourced from ExpTech's fork of `Disable-Battery-Optimizations`
         * (KillerManager's device table), which carries several OS generations
         * per vendor — hence the chains: OPPO alone has moved this screen
         * between `com.coloros.safecenter`, `com.oppo.safe` and
         * `com.color.safecenter`, and a device only has one of them. Ordered
         * most-specific first, so the user lands on the auto-start or
         * sleeping-apps list itself rather than a battery summary they then have
         * to navigate.
         *
         * Undocumented and version-specific by nature — these are activities
         * inside the vendor's own system app, so they move and disappear between
         * releases. Every one is attempted inside a try/catch and the standard
         * app-details page is the last resort: this can degrade, but it must
         * never throw or dead-end.
         *
         * Deliberately not probed with `resolveActivity` first: on Android 11+
         * package visibility hides these components unless the app declares a
         * `<queries>` entry for every vendor package, so a resolve check would
         * answer "unavailable" on precisely the devices that have the screen.
         * Trying and catching is both simpler and more accurate.
         */
        private val OEM_SCREENS: Map<String, List<Screen>> = buildMap {
            val miui = listOf(
                Screen.Component(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                ),
                Screen.Component(
                    "com.miui.powerkeeper",
                    "com.miui.powerkeeper.ui.HiddenAppsConfigActivity",
                ),
            )
            for (brand in listOf("xiaomi", "redmi", "poco")) put(brand, miui)

            val emui = listOf(
                Screen.Action("huawei.intent.action.HSM_BOOTAPP_MANAGER"),
                Screen.Component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
                ),
                Screen.Component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity",
                ),
                Screen.Action("huawei.intent.action.HSM_PROTECTED_APPS"),
                Screen.Component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                ),
            )
            for (brand in listOf("huawei", "honor")) put(brand, emui)

            // The first entry is the "sleeping apps" list itself — the screen
            // that actually holds the three-day timer, not the battery summary
            // a generic instruction would land on.
            put(
                "samsung",
                listOf(
                    Screen.Component(
                        "com.samsung.android.lool",
                        "com.samsung.android.sm.ui.battery.AppSleepListActivity",
                    ),
                    Screen.Action("com.samsung.android.sm.ACTION_BATTERY"),
                    Screen.Component(
                        "com.samsung.android.lool",
                        "com.samsung.android.sm.ui.battery.BatteryActivity",
                    ),
                ),
            )

            val coloros = listOf(
                Screen.Component(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                ),
                Screen.Component(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity",
                ),
                Screen.Component(
                    "com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity",
                ),
                Screen.Component(
                    "com.color.safecenter",
                    "com.color.safecenter.permission.startup.StartupAppListActivity",
                ),
                Screen.Component(
                    "com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity",
                ),
            )
            for (brand in listOf("oppo", "realme")) put(brand, coloros)

            put(
                "vivo",
                listOf(
                    Screen.Component(
                        "com.vivo.permissionmanager",
                        "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                    ),
                    Screen.Component(
                        "com.iqoo.secure",
                        "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
                    ),
                    Screen.Component(
                        "com.iqoo.secure",
                        "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
                    ),
                    Screen.Component(
                        "com.vivo.abe",
                        "com.vivo.applicationbehaviorengine.ui.ExcessivePowerManagerActivity",
                    ),
                ),
            )

            put(
                "oneplus",
                listOf(
                    Screen.Component(
                        "com.oneplus.security",
                        "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
                    ),
                    Screen.Component(
                        "com.oneplus.security",
                        "com.oneplus.security.autorun.AutorunMainActivity",
                    ),
                    Screen.Component(
                        "com.oneplus.security",
                        "com.oneplus.security.highpowerapp.view.HighPowerAppActivity",
                    ),
                ),
            )

            put(
                "meizu",
                listOf(
                    Screen.Action("com.meizu.power.PowerAppKilledNotification"),
                    Screen.Component(
                        "com.meizu.safe",
                        "com.meizu.safe.powerui.PowerAppPermissionActivity",
                    ),
                    Screen.Component(
                        "com.meizu.safe",
                        "com.meizu.safe.powerui.AppPowerManagerActivity",
                    ),
                ),
            )

            put(
                "asus",
                listOf(
                    Screen.Component(
                        "com.asus.mobilemanager",
                        "com.asus.mobilemanager.autostart.AutoStartActivity",
                    ),
                    Screen.Component(
                        "com.asus.mobilemanager",
                        "com.asus.mobilemanager.entry.FunctionActivity",
                    ),
                ),
            )

            put(
                "zte",
                listOf(
                    Screen.Component(
                        "com.zte.heartyservice",
                        "com.zte.heartyservice.autorun.AppAutoRunManager",
                    ),
                    Screen.Component(
                        "com.zte.heartyservice",
                        "com.zte.heartyservice.setting.ClearAppSettingsActivity",
                    ),
                ),
            )

            put(
                "letv",
                listOf(
                    Screen.Component(
                        "com.letv.android.letvsafe",
                        "com.letv.android.letvsafe.AutobootManageActivity",
                    ),
                ),
            )

            // The upstream table stores this class name with a leading space,
            // which silently never resolves. Corrected here on purpose — do not
            // "restore" it to match the source.
            put(
                "htc",
                listOf(
                    Screen.Component(
                        "com.htc.pitroad",
                        "com.htc.pitroad.landingpage.activity.LandingPageActivity",
                    ),
                ),
            )

            val transsion = listOf(
                Screen.Component(
                    "com.transsion.phonemaster",
                    "com.cyin.himgr.autostart.AutoStartActivity",
                ),
            )
            for (brand in listOf("tecno", "infinix", "itel")) put(brand, transsion)
        }

        /**
         * Manufacturers whose battery manager stops background work on a
         * days-not-months timescale. Every vendor with a screen above, plus any
         * that is known to do it without offering one to open — the row still has
         * to appear there, it just can only reach the app-details page.
         */
        private val AGGRESSIVE: Set<String> = OEM_SCREENS.keys + setOf("nokia")
    }

    private val vendor: String get() = Build.MANUFACTURER.lowercase()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            "openSystemSettings" -> result.success(openAppDetails())
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
        for (screen in OEM_SCREENS[vendor].orEmpty()) {
            val intent = when (screen) {
                is Screen.Action -> Intent(screen.name)
                is Screen.Component ->
                    Intent().setComponent(ComponentName(screen.pkg, screen.cls))
            }
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return "vendor"
            } catch (e: Exception) {
                Log.i(TAG, "vendor screen $screen unavailable", e)
            }
        }
        return openAppDetails()
    }

    /**
     * The standard Android restriction and an OEM's auto-start manager are two
     * different controls. This destination deliberately skips the OEM chain so
     * a user fixing Android's own "Restricted" state lands on DPIP's app page,
     * not on (for example) Samsung's sleeping-app list.
     */
    private fun openAppDetails(): String {
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
