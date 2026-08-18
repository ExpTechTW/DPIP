package com.exptech.dpip

import android.content.Context
import android.content.SharedPreferences
import java.net.HttpURLConnection
import java.net.URL

/**
 * Shared persistence + reporting for background device-location reporting, used
 * by both the primary geofence spine ([GeofenceManager]/[GeofenceReceiver]) and
 * the Google-Play-services-less alarm fallback ([LocationAlarmScheduler]).
 *
 * State lives in prefs so any receiver can run with no Flutter isolate alive.
 */
object BgLocationStore {
    const val PREFS = "dpip_bg_location"
    const val KEY_ENABLED = "enabled"
    const val KEY_TOKEN = "token"
    const val KEY_VERSION = "version"
    const val KEY_PLATFORM = "platform"
    const val KEY_LAST_LAT = "last_lat"
    const val KEY_LAST_LNG = "last_lng"
    const val KEY_HAS_LAST = "has_last"
    const val KEY_INTERVAL_MIN = "interval_min" // alarm fallback only

    // Diagnostics. None of this drives behaviour — it exists so the developer
    // page can answer "is background reporting actually working?" from a user's
    // phone. The Geofencing API has no way to ask whether a fence is live, so
    // whether one was ever armed has to be remembered here.
    const val KEY_ARMED = "geofence_armed"
    const val KEY_LAST_REPORT_AT = "last_report_at"
    const val KEY_LAST_REPORT_OK = "last_report_ok"
    const val KEY_LAST_REPORT_CODE = "last_report_code"

    /** When a report was last *sent*, which is what the throttle measures. */
    const val KEY_LAST_SENT_AT = "last_sent_at"

    /** How many triggers the throttle has dropped, for the diagnostics page. */
    const val KEY_THROTTLED_N = "throttled_n"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    fun saveConfig(context: Context, token: String, version: String, platform: Int) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, true)
            .putString(KEY_TOKEN, token)
            .putString(KEY_VERSION, version)
            .putInt(KEY_PLATFORM, platform)
            .apply()
    }

    fun disable(context: Context) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, false)
            .putBoolean(KEY_ARMED, false)
            .apply()
    }

    /** Records whether a geofence is currently monitoring — diagnostics only. */
    fun setArmed(context: Context, armed: Boolean) {
        prefs(context).edit().putBoolean(KEY_ARMED, armed).apply()
    }

    fun armed(context: Context): Boolean = prefs(context).getBoolean(KEY_ARMED, false)

    fun saveLast(context: Context, lat: Double, lng: Double) {
        prefs(context).edit()
            .putBoolean(KEY_HAS_LAST, true)
            .putFloat(KEY_LAST_LAT, lat.toFloat())
            .putFloat(KEY_LAST_LNG, lng.toFloat())
            .apply()
    }

    fun hasLast(context: Context): Boolean = prefs(context).getBoolean(KEY_HAS_LAST, false)

    fun lastLat(context: Context): Double =
        prefs(context).getFloat(KEY_LAST_LAT, 0f).toDouble()

    fun lastLng(context: Context): Double =
        prefs(context).getFloat(KEY_LAST_LNG, 0f).toDouble()

    /**
     * Reports coordinates to `updateDeviceLocation` (blocking — call off the
     * main thread). Best-effort: a failure is swallowed and retried on the next
     * trigger. coreExclusiveApi is tnn1-only (no failover).
     */
    fun report(context: Context, lat: Double, lng: Double) {
        val prefs = prefs(context)

        // At most one report a minute, across every trigger.
        //
        // Four callers fire this independently — the geofence, the alarm
        // fallback, and two paths from Dart — and nothing coordinated them, so
        // a crossing that arrived alongside an alarm sent two reports seconds
        // apart. The server answers 429, the location never lands, and the app
        // looks like it stopped reporting: on the device this was found on,
        // `last_report_code` was 429 with the geofence armed and a fix in hand.
        //
        // Measured from KEY_LAST_SENT_AT, not KEY_LAST_REPORT_AT: the latter is
        // stamped on every outcome including this one, so gating on it would
        // let a burst of triggers push the window ahead of itself and starve
        // reporting entirely.
        val now = System.currentTimeMillis()
        val sent = prefs.getLong(KEY_LAST_SENT_AT, 0L)
        if (sent > 0L && now - sent < MIN_REPORT_INTERVAL_MS) {
            prefs.edit()
                .putInt(KEY_THROTTLED_N, prefs.getInt(KEY_THROTTLED_N, 0) + 1)
                .apply()
            stamp(prefs, THROTTLED)
            return
        }
        // Stamped even on the way out. These two returns sat *above* the stamp,
        // so a run that never had a token was indistinguishable from one that
        // never happened — and "never happened" is what the developer page
        // showed for both, which is the ambiguity that made this bug survive
        // three attempts. A negative code is a reason, not an HTTP status.
        val token = prefs.getString(KEY_TOKEN, null)
            ?: return stamp(prefs, NO_TOKEN)
        val version = prefs.getString(KEY_VERSION, null)
            ?: return stamp(prefs, NO_VERSION)
        val platform = prefs.getInt(KEY_PLATFORM, 0)
        var code = -1
        try {
            val url = URL(
                "https://api.core-tnn1.exptech.dev/api/v2/location/" +
                    "$platform/$token/$version/$lat,$lng",
            )
            (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 10_000
                readTimeout = 10_000
                code = responseCode // fire the request
                disconnect()
            }
            prefs.edit().putLong(KEY_LAST_SENT_AT, now).apply()
        } catch (e: Exception) {
            // Best-effort; the next trigger retries. The outcome is still
            // recorded below — "tried at T and failed" is the diagnostic that
            // separates "never fired" from "fires but cannot reach the server".
            //
            // The exception's name is kept, because -1 on its own is not a
            // diagnosis. On a device where the alarm path failed three times
            // running while the app's own SSE connections were live, -1 was
            // everything the app could say, and it fits UnknownHostException,
            // a timeout, a TLS failure and a Doze network block equally well.
            noteWake(context, "report failed: ${e.javaClass.simpleName}")
        }
        stamp(prefs, code)
    }

    /** Dropped by the throttle — a report went out less than a minute ago. */
    const val THROTTLED = -4

    /** The floor between two reports, whichever trigger asks. */
    const val MIN_REPORT_INTERVAL_MS = 60_000L

    /** No push token stored — the report has nowhere to go. */
    const val NO_TOKEN = -2

    /** No app version stored, which the endpoint's path needs. */
    const val NO_VERSION = -3

    private fun stamp(prefs: SharedPreferences, code: Int) {
        prefs.edit()
            .putLong(KEY_LAST_REPORT_AT, System.currentTimeMillis())
            .putBoolean(KEY_LAST_REPORT_OK, code in 200..299)
            .putInt(KEY_LAST_REPORT_CODE, code)
            .apply()
    }

    /**
     * A bounded ring of what the background path did, drained into the app's
     * own log at the next launch.
     *
     * Every background wake runs in a `BroadcastReceiver` with no Flutter
     * isolate, so nothing it does can reach `Log` — and `android.util.Log` is
     * logcat, which nobody can read from their own phone. The Android
     * background path was therefore invisible *by construction*, which is why
     * three attempts at this bug had nothing to go on.
     */
    fun note(context: Context, message: String) {
        val prefs = prefs(context)
        val existing = prefs.getString(KEY_BREADCRUMBS, "").orEmpty()
        val line = "${System.currentTimeMillis()}\t$message"
        val kept = (existing.split('\n').filter { it.isNotBlank() } + line)
            .takeLast(BREADCRUMB_LIMIT)
        prefs.edit().putString(KEY_BREADCRUMBS, kept.joinToString("\n")).apply()
    }

    /** Reads the ring and clears it, so a line is reported once. */
    fun drainBreadcrumbs(context: Context): List<String> {
        val prefs = prefs(context)
        val all = prefs.getString(KEY_BREADCRUMBS, "").orEmpty()
        if (all.isBlank()) return emptyList()
        prefs.edit().remove(KEY_BREADCRUMBS).apply()
        return all.split('\n').filter { it.isNotBlank() }
    }

    /**
     * Records that the OS woke us, before any guard can return.
     *
     * The highest-value question in a background-location bug is whether the
     * wake happened at all, and nothing anywhere answered it: every receiver
     * returned early on a disabled or unpermitted device without leaving a
     * trace, so "the OS never called us" and "we ignored the call" looked
     * identical.
     */
    fun noteWake(context: Context, kind: String) {
        val prefs = prefs(context)
        prefs.edit()
            .putLong("wake_${kind}_at", System.currentTimeMillis())
            .putInt("wake_${kind}_n", prefs.getInt("wake_${kind}_n", 0) + 1)
            .apply()
        note(context, "woke: $kind")
    }

    private const val KEY_BREADCRUMBS = "breadcrumbs"
    private const val BREADCRUMB_LIMIT = 50
}
