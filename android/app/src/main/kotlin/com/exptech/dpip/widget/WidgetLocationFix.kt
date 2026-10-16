package com.exptech.dpip.widget

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.SystemClock
import androidx.core.content.ContextCompat
import com.exptech.dpip.FusedFix
import com.exptech.dpip.GmsAvailability
import com.exptech.dpip.LocationFetcher

/**
 * A position with the two facts that decide whether it may be trusted.
 *
 * The accuracy and the age travel with the coordinate rather than being judged
 * and discarded inside the acquisition, because the township resolver needs
 * them: a 400-metre fix ten metres inside a boundary is *not* in that township
 * with any confidence, and only the resolver knows where the boundary is.
 */
data class WidgetFix(
    val latitude: Double,
    val longitude: Double,
    val accuracyMeters: Double,
    val ageMilliseconds: Long,
)

/** What a position acquisition produced, or why it could not. */
sealed interface WidgetLocationFixResult {
    data class Acquired(val fix: WidgetFix) : WidgetLocationFixResult

    /** A permission is missing, so no fresh fix is possible without the app. */
    data object NotAuthorized : WidgetLocationFixResult

    /** Location is switched off, or no provider is enabled. */
    data object Disabled : WidgetLocationFixResult

    /** A fix arrived but was too old or too coarse to call a position. */
    data object Unusable : WidgetLocationFixResult

    /** No fix could be obtained at all. */
    data object Failed : WidgetLocationFixResult

    /**
     * The degradation to store for this outcome, or null for an acquired fix.
     *
     * Every non-acquired outcome maps to *something*, which is the point: a
     * timeout and a null are as much a reason to say "the position is not
     * available" as a denied permission is, and the previous version recorded
     * only the permission cases.
     */
    val degradation: WidgetLocationDegradation?
        get() = when (this) {
            is Acquired -> null
            NotAuthorized -> WidgetLocationDegradation.Permission
            Disabled -> WidgetLocationDegradation.Disabled
            Unusable -> WidgetLocationDegradation.UnusableFix
            Failed -> WidgetLocationDegradation.Unavailable
        }
}

/**
 * A single position for the Current Location Widget, with its own quality gate.
 *
 * The underlying capabilities are reused — `FusedFix` where Play services exist
 * and `LocationFetcher` where they do not — because the Widget is not a second
 * location stack. What it must not reuse is their leniency: `LocationFetcher`
 * falls back to a last-known fix when a fresh one fails, which was written for
 * a reporter that only needs "roughly where" and is exactly the behaviour the
 * plan forbids here. A last-known fix can place a Widget in a township the
 * device left an hour ago, and it would be drawn as the current position with
 * no way for the user to tell.
 *
 * So every fix is re-validated here, on age and accuracy, and a rejection is
 * `Unusable` rather than a quiet substitution. Age is read from
 * `elapsedRealtimeNanos`, never from the wall clock: a device whose date is
 * wrong would otherwise make a stale fix look fresh.
 *
 * Background location is required because this runs in a headless Worker. With
 * only "while in use", the correct answer is "the app has to be open", not a
 * fix the OS would refuse to hand over.
 */
object WidgetLocationFix {
    const val maximumAgeMilliseconds = 5 * 60 * 1_000L
    const val maximumAccuracyMeters = 500.0

    fun acquire(context: Context): WidgetLocationFixResult {
        if (!hasForegroundPermission(context)) return WidgetLocationFixResult.NotAuthorized
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !hasBackgroundPermission(context)) {
            return WidgetLocationFixResult.NotAuthorized
        }

        if (!isLocationEnabled(context)) return WidgetLocationFixResult.Disabled

        val location = try {
            if (GmsAvailability.available(context)) FusedFix.get(context)
            else LocationFetcher.getFix(context)
        } catch (_: SecurityException) {
            return WidgetLocationFixResult.NotAuthorized
        } catch (_: Exception) {
            return WidgetLocationFixResult.Failed
        } ?: return WidgetLocationFixResult.Failed

        val fix = toFix(location) ?: return WidgetLocationFixResult.Unusable
        return WidgetLocationFixResult.Acquired(fix)
    }

    /**
     * The fix as a [WidgetFix], or null when it is not trustworthy.
     *
     * Pure, so the age and accuracy rules are testable without a device.
     */
    fun toFix(location: Location): WidgetFix? {
        if (!location.latitude.isFinite() || !location.longitude.isFinite()) return null
        if (location.latitude !in -90.0..90.0 || location.longitude !in -180.0..180.0) return null

        val ageNanos = SystemClock.elapsedRealtimeNanos() - location.elapsedRealtimeNanos
        if (ageNanos < 0) return null
        val ageMilliseconds = ageNanos / 1_000_000L
        if (ageMilliseconds > maximumAgeMilliseconds) return null

        // A provider that reports no accuracy is treated as unusable rather than
        // as perfect: the value feeds the boundary-uncertainty test, and "no
        // accuracy" is not the same as "exact".
        if (!location.hasAccuracy()) return null
        val accuracy = location.accuracy.toDouble()
        if (!accuracy.isFinite() || accuracy < 0 || accuracy > maximumAccuracyMeters) return null

        return WidgetFix(
            latitude = location.latitude,
            longitude = location.longitude,
            accuracyMeters = accuracy,
            ageMilliseconds = ageMilliseconds,
        )
    }

    fun hasForegroundPermission(context: Context): Boolean =
        granted(context, Manifest.permission.ACCESS_FINE_LOCATION) ||
            granted(context, Manifest.permission.ACCESS_COARSE_LOCATION)

    fun hasBackgroundPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return hasForegroundPermission(context)
        return granted(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
    }

    private fun isLocationEnabled(context: Context): Boolean = try {
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ||
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
            manager.isProviderEnabled(LocationManager.PASSIVE_PROVIDER)
    } catch (_: Exception) {
        false
    }

    private fun granted(context: Context, permission: String): Boolean =
        ContextCompat.checkSelfPermission(context, permission) ==
            PackageManager.PERMISSION_GRANTED
}
