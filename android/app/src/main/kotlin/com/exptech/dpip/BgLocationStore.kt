package com.exptech.dpip

import android.content.Context
import android.content.SharedPreferences
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * Shared persistence + reporting for background device-location reporting, used
 * by both the geofence fast path ([GeofenceManager]/[GeofenceReceiver]) and the
 * independent alarm fallback ([LocationAlarmScheduler]).
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
    const val KEY_INTERVAL_MIN = "interval_min"
    const val KEY_PERMISSION_READY = "permission_ready"

    // Diagnostics. None of this drives behaviour — it exists so the developer
    // page can answer "is background reporting actually working?" from a user's
    // phone. The Geofencing API has no way to ask whether a fence is live, so
    // whether one was ever armed has to be remembered here.
    const val KEY_ARMED = "geofence_armed"
    const val KEY_LAST_ATTEMPT_AT = "last_attempt_at"
    const val KEY_LAST_ATTEMPT_OK = "last_attempt_ok"
    const val KEY_LAST_ATTEMPT_CODE = "last_attempt_code"
    const val KEY_LAST_SUCCESS_AT = "last_success_at"
    const val KEY_LAST_SUCCESS_CODE = "last_success_code"
    const val KEY_LAST_THROTTLED_AT = "last_throttled_at"

    // Read-only migration source for builds that predate split diagnostics.
    const val KEY_LEGACY_LAST_REPORT_AT = "last_report_at"
    const val KEY_LEGACY_LAST_REPORT_OK = "last_report_ok"
    const val KEY_LEGACY_LAST_REPORT_CODE = "last_report_code"

    /** When a report was last *sent*, which is what the throttle measures. */
    const val KEY_LAST_SENT_AT = "last_sent_at"

    /** How many triggers the throttle has dropped, for the diagnostics page. */
    const val KEY_THROTTLED_N = "throttled_n"

    /**
     * Which identity `start` last armed with, hashed — the token need not be
     * stored twice. [KEY_TOKEN] and its siblings can no longer answer that,
     * because Dart now writes them in every mode ([saveIdentity]).
     */
    const val KEY_STARTED_WITH = "started_with"

    // The device's last successful report from **any** path — this one, the
    // Dart foreground reports and the [ReportHeartbeat] — and the point it
    // sent. Kept apart from KEY_LAST_SUCCESS_AT, which is the background
    // path's own evidence on the diagnostics page and would stop meaning
    // anything if a foreground report could write it. Device time; the
    // coordinates as raw double bits, so the heartbeat resends exactly them.
    const val KEY_REPORTED_AT = "reported_at"
    const val KEY_REPORTED_LAT = "reported_lat"
    const val KEY_REPORTED_LNG = "reported_lng"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    /** Whether `start` is already armed with exactly this identity. */
    fun configMatches(context: Context, token: String, version: String, platform: Int): Boolean {
        val prefs = prefs(context)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return false
        // Builds before the heartbeat wrote the identity keys from `start`
        // alone, so on a device that has not started since, they still say
        // what it started with.
        val startedWith = prefs.getString(KEY_STARTED_WITH, null)
            ?: return prefs.getString(KEY_TOKEN, null) == token &&
                prefs.getString(KEY_VERSION, null) == version &&
                prefs.getInt(KEY_PLATFORM, Int.MIN_VALUE) == platform
        return startedWith == configId(token, version, platform)
    }

    fun saveConfig(context: Context, token: String, version: String, platform: Int) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, true)
            .putString(KEY_TOKEN, token)
            .putString(KEY_VERSION, version)
            .putInt(KEY_PLATFORM, platform)
            .putString(KEY_STARTED_WITH, configId(token, version, platform))
            .apply()
    }

    /**
     * Stores what a report is sent as — push token, app version, platform —
     * without enabling anything. Dart hands it over in every mode, because the
     * [ReportHeartbeat] reports from devices that never `start`: a township
     * pinned by hand, or no "Always" grant. [disable] keeps it.
     *
     * [configMatches] reads [KEY_STARTED_WITH], not these, so a new token that
     * arrives here first still makes the next `start` report it.
     */
    fun saveIdentity(context: Context, token: String, version: String, platform: Int) {
        val prefs = prefs(context)
        if (prefs.getString(KEY_TOKEN, null) == token &&
            prefs.getString(KEY_VERSION, null) == version &&
            prefs.contains(KEY_PLATFORM) &&
            prefs.getInt(KEY_PLATFORM, 0) == platform
        ) {
            return
        }
        prefs.edit()
            .putString(KEY_TOKEN, token)
            .putString(KEY_VERSION, version)
            .putInt(KEY_PLATFORM, platform)
            .apply()
    }

    private fun configId(token: String, version: String, platform: Int): String =
        MessageDigest.getInstance("SHA-256")
            .digest("$platform\n$version\n$token".toByteArray())
            .joinToString("") { "%02x".format(it) }

    /** The device's last successful report, from any path, or null if none. */
    data class Reported(val at: Long, val lat: Double, val lng: Double)

    /** Records a 2xx sent at [at] (device time) from [lat], [lng]. */
    fun recordReported(context: Context, at: Long, lat: Double, lng: Double) {
        prefs(context).edit()
            .putLong(KEY_REPORTED_AT, at)
            .putLong(KEY_REPORTED_LAT, lat.toRawBits())
            .putLong(KEY_REPORTED_LNG, lng.toRawBits())
            .apply()
    }

    fun reported(context: Context): Reported? {
        val prefs = prefs(context)
        if (!prefs.contains(KEY_REPORTED_AT) ||
            !prefs.contains(KEY_REPORTED_LAT) ||
            !prefs.contains(KEY_REPORTED_LNG)
        ) {
            return null
        }
        return Reported(
            prefs.getLong(KEY_REPORTED_AT, 0L),
            Double.fromBits(prefs.getLong(KEY_REPORTED_LAT, 0L)),
            Double.fromBits(prefs.getLong(KEY_REPORTED_LNG, 0L)),
        )
    }

    fun disable(context: Context) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, false)
            .putBoolean(KEY_ARMED, false)
            .putBoolean(KEY_PERMISSION_READY, false)
            .apply()
    }

    fun permissionReady(context: Context): Boolean =
        prefs(context).getBoolean(KEY_PERMISSION_READY, false)

    fun setPermissionReady(context: Context, ready: Boolean) {
        prefs(context).edit().putBoolean(KEY_PERMISSION_READY, ready).apply()
    }

    /** Records the last accepted geofence registration — diagnostics only. */
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
    @Synchronized
    fun report(context: Context, lat: Double, lng: Double) {
        if (!enabled(context)) return
        val prefs = prefs(context)

        // Before the throttle on purpose. The throttle below exists to spare the
        // server a 429; the local track has no server to spare, and dropping a
        // fix the OS took the trouble to deliver would put holes in the history
        // for a reason that has nothing to do with it.
        LocationTrackStore.record(context, lat, lng)

        // At most one report a minute, across every trigger.
        //
        // Four callers fire this independently — the geofence, the alarm
        // fallback, and two paths from Dart — and nothing coordinated them, so
        // a crossing that arrived alongside an alarm sent two reports seconds
        // apart. The server answers 429, the location never lands, and the app
        // looks like it stopped reporting: on the device this was found on,
        // `last_report_code` was 429 with the geofence armed and a fix in hand.
        //
        // A throttled trigger is not a report attempt. Keep it in its own fields
        // so it cannot overwrite the last HTTP result shown by diagnostics.
        val now = System.currentTimeMillis()
        val sent = prefs.getLong(KEY_LAST_SENT_AT, 0L)
        if (sent > 0L && now - sent < MIN_REPORT_INTERVAL_MS) {
            prefs.edit()
                .putInt(KEY_THROTTLED_N, prefs.getInt(KEY_THROTTLED_N, 0) + 1)
                .putLong(KEY_LAST_THROTTLED_AT, now)
                .apply()
            return
        }
        // A negative code is a reason no HTTP request could be made.
        val token = prefs.getString(KEY_TOKEN, null)
            ?: return stampAttempt(prefs, now, NO_TOKEN)
        val version = prefs.getString(KEY_VERSION, null)
            ?: return stampAttempt(prefs, now, NO_VERSION)
        val platform = prefs.getInt(KEY_PLATFORM, 0)

        // Reserve the one-minute slot before opening the connection. Multiple
        // JobWorkItems and a foreground report can otherwise pass the throttle
        // together and issue duplicate requests.
        prefs.edit().putLong(KEY_LAST_SENT_AT, now).apply()
        // Best-effort; the next trigger retries. The outcome is still recorded
        // below — "tried at T and failed" is the diagnostic that separates
        // "never fired" from "fires but cannot reach the server".
        val code = send(context, "report", platform, token, version, lat, lng)
        stampAttempt(prefs, now, code)
        if (code in 200..299) {
            prefs.edit()
                .putLong(KEY_LAST_SUCCESS_AT, now)
                .putInt(KEY_LAST_SUCCESS_CODE, code)
                .apply()
            recordReported(context, now, lat, lng)
        }
    }

    /**
     * Sends one report for the [ReportHeartbeat], under the same lock and the
     * same one-a-minute floor as [report], and records a 2xx. Blocking — call
     * off the main thread.
     *
     * Unlike [report] it ignores [enabled] — the heartbeat reports in every
     * mode — and records nothing on the local track, because the point is a
     * resend, not a fix. Its attempts stay out of the background path's
     * diagnostics too; the heartbeat keeps its own.
     *
     * The HTTP status; [NO_TOKEN] or [NO_VERSION] when no request could be
     * made; null when a report went out inside the last minute.
     */
    @Synchronized
    fun reportOnce(context: Context, now: Long, lat: Double, lng: Double): Int? {
        val prefs = prefs(context)
        val sent = prefs.getLong(KEY_LAST_SENT_AT, 0L)
        if (sent in 1..now && now - sent < MIN_REPORT_INTERVAL_MS) return null
        val token = prefs.getString(KEY_TOKEN, null) ?: return NO_TOKEN
        val version = prefs.getString(KEY_VERSION, null) ?: return NO_VERSION
        val platform = prefs.getInt(KEY_PLATFORM, 0)
        prefs.edit().putLong(KEY_LAST_SENT_AT, now).apply()
        val code = send(context, "heartbeat", platform, token, version, lat, lng)
        if (code in 200..299) recordReported(context, now, lat, lng)
        return code
    }

    /** One `GET` against an absolute URL, answering the HTTP status. */
    fun interface Transport {
        fun get(url: String): Int
    }

    /** The real network. Tests swap in their own, so nothing reaches production. */
    @Volatile
    internal var transport: Transport = Transport { url ->
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "GET"
            connection.connectTimeout = 10_000
            connection.readTimeout = 10_000
            connection.responseCode // fires the request
        } finally {
            connection.disconnect()
        }
    }

    internal fun reportUrl(
        platform: Int,
        token: String,
        version: String,
        lat: Double,
        lng: Double,
    ): String = "https://api.core-tnn1.exptech.dev/api/v2/location/" +
        "$platform/$token/$version/$lat,$lng"

    /**
     * Fires `updateDeviceLocation` once; the HTTP status, or -1 when no answer
     * came. coreExclusiveApi is tnn1-only (no failover). Never throws.
     */
    private fun send(
        context: Context,
        label: String,
        platform: Int,
        token: String,
        version: String,
        lat: Double,
        lng: Double,
    ): Int = try {
        transport.get(reportUrl(platform, token, version, lat, lng))
    } catch (e: Exception) {
        // The exception's name is kept, because -1 on its own is not a
        // diagnosis. On a device where the alarm path failed three times
        // running while the app's own SSE connections were live, -1 was
        // everything the app could say, and it fits UnknownHostException, a
        // timeout, a TLS failure and a Doze network block equally well.
        note(context, "$label failed: ${e.javaClass.simpleName}")
        -1
    }

    /** The floor between two reports, whichever trigger asks. */
    const val MIN_REPORT_INTERVAL_MS = 60_000L

    /** No push token stored — the report has nowhere to go. */
    const val NO_TOKEN = -2

    /** No app version stored, which the endpoint's path needs. */
    const val NO_VERSION = -3

    private fun stampAttempt(prefs: SharedPreferences, at: Long, code: Int) {
        prefs.edit()
            .putLong(KEY_LAST_ATTEMPT_AT, at)
            .putBoolean(KEY_LAST_ATTEMPT_OK, code in 200..299)
            .putInt(KEY_LAST_ATTEMPT_CODE, code)
            .apply()
    }

    /**
     * A bounded ring of what the background path did, drained into the app's
     * own log at the next launch.
     *
     * Every background wake begins in a receiver and continues in a native job,
     * with no Flutter isolate, so nothing it does can reach `Log` as it happens.
     */
    @Synchronized
    fun note(context: Context, message: String) {
        val prefs = prefs(context)
        val existing = prefs.getString(KEY_BREADCRUMBS, "").orEmpty()
        val line = "${System.currentTimeMillis()}\t$message"
        val kept = (existing.split('\n').filter { it.isNotBlank() } + line)
            .takeLast(BREADCRUMB_LIMIT)
        prefs.edit().putString(KEY_BREADCRUMBS, kept.joinToString("\n")).apply()
    }

    /** Reads the ring and clears it, so a line is reported once. */
    @Synchronized
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
    @Synchronized
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
