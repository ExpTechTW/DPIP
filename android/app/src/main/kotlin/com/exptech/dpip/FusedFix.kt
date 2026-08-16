package com.exptech.dpip

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.SystemClock
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.Tasks
import java.util.concurrent.TimeUnit

/**
 * A single low-power fix from the Fused Location Provider.
 *
 * `BALANCED_POWER_ACCURACY` (~100 m from Wi-Fi/cell, no GNSS) is finer than any
 * township boundary, so it never spins the battery-hungry GPS chip. Accepts a
 * recent cached fix (`maxUpdateAge`) to avoid a fresh acquisition when possible,
 * and falls back to the last known location. Blocks briefly — call off the main
 * thread (the receivers' `goAsync` window).
 *
 * Returns null when it cannot get one, which is a real outcome on a device with
 * no Play services, no location permission, or location switched off — and
 * every path here used to swallow the reason. That mattered: "the fix was
 * null" is one of exactly two things `Last report: never` can mean, and there
 * was no way to tell which, or why. Each failure now leaves a breadcrumb; none
 * of it changes what the function returns.
 */
object FusedFix {
    private const val MAX_AGE_MS = 120_000L
    private const val DURATION_MS = 15_000L
    private const val LAST_LOCATION_TIMEOUT_MS = 3_000L

    @SuppressLint("MissingPermission")
    fun get(context: Context): Location? {
        val why = StringBuilder()
        val client = LocationServices.getFusedLocationProviderClient(context)
        val request = CurrentLocationRequest.Builder()
            .setPriority(Priority.PRIORITY_BALANCED_POWER_ACCURACY)
            .setMaxUpdateAgeMillis(MAX_AGE_MS)
            .setDurationMillis(DURATION_MS)
            .build()
        val current = try {
            Tasks.await(
                client.getCurrentLocation(request, null),
                DURATION_MS + 2_000L,
                TimeUnit.MILLISECONDS,
            )
        } catch (e: Exception) {
            why.append("current: ").append(e.javaClass.simpleName)
            null
        }
        if (current != null) return current
        if (why.isEmpty()) why.append("current: null")
        // Fall back to the last known location — but only if it's fresh, so a
        // stale fix can't report the wrong township or re-centre the geofence on
        // a point the device already left.
        val fallback = try {
            val last = Tasks.await(
                client.lastLocation, LAST_LOCATION_TIMEOUT_MS, TimeUnit.MILLISECONDS,
            )
            when {
                last == null -> {
                    why.append(", last: null")
                    null
                }
                !isFresh(last) -> {
                    why.append(", last: stale")
                    null
                }
                else -> last
            }
        } catch (e: Exception) {
            why.append(", last: ").append(e.javaClass.simpleName)
            null
        }
        if (fallback == null) BgLocationStore.note(context, "no fix — $why")
        return fallback
    }

    private fun isFresh(location: Location): Boolean {
        val ageNanos = SystemClock.elapsedRealtimeNanos() - location.elapsedRealtimeNanos
        return ageNanos in 0..(MAX_AGE_MS * 1_000_000L)
    }
}
