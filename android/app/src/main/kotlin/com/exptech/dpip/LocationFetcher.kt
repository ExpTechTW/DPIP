package com.exptech.dpip

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Looper
import androidx.core.content.ContextCompat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Gets a single device location for the background alarm, cheaply.
 *
 * Prefers a recent last-known fix (no sensor spin-up) and only asks the system
 * for a fresh one when that's stale. For a township-level report (~500 m is
 * plenty) it prefers the low-power **network** provider over GPS, and it
 * requires background-location permission on Android 10+ — a headless receiver
 * with only "while in use" can't fix, so this returns null and the receiver
 * backs off rather than spinning sensors for nothing. Runs on the caller's
 * background thread (the alarm receiver's `goAsync` window), blocking briefly on
 * the fresh-fix callback via a latch.
 */
object LocationFetcher {
    private const val FRESH_MS = 5 * 60 * 1000L
    private const val ACCEPTABLE_ACCURACY_M = 500f
    private const val CURRENT_TIMEOUT_MS = 8_000L

    /** The best fix available now, or null if none / no permission. */
    fun getFix(context: Context): Location? {
        if (!hasPermission(context)) return null
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

        val lastKnown = freshestLastKnown(lm)
        if (lastKnown != null && isFresh(lastKnown)) return lastKnown

        return requestCurrent(lm) ?: lastKnown
    }

    private fun granted(context: Context, permission: String) =
        ContextCompat.checkSelfPermission(context, permission) ==
            PackageManager.PERMISSION_GRANTED

    private fun hasPermission(context: Context): Boolean {
        val foreground = granted(context, Manifest.permission.ACCESS_FINE_LOCATION) ||
            granted(context, Manifest.permission.ACCESS_COARSE_LOCATION)
        if (!foreground) return false
        // Android 10+: a background fetch also needs ACCESS_BACKGROUND_LOCATION;
        // without it the fetch below would return null anyway.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return granted(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        }
        return true
    }

    private fun freshestLastKnown(lm: LocationManager): Location? {
        var best: Location? = null
        try {
            for (provider in lm.getProviders(true)) {
                val loc = lm.getLastKnownLocation(provider) ?: continue
                if (best == null || loc.time > best.time) best = loc
            }
        } catch (e: SecurityException) {
            return null
        }
        return best
    }

    private fun isFresh(location: Location): Boolean {
        val age = System.currentTimeMillis() - location.time
        val accuracy = if (location.hasAccuracy()) location.accuracy else Float.MAX_VALUE
        return age in 0..FRESH_MS && accuracy <= ACCEPTABLE_ACCURACY_M
    }

    // Township resolution only needs coarse accuracy, so prefer the low-power
    // network provider and fall back to GPS only when it's unavailable.
    private fun bestProvider(lm: LocationManager): String? = when {
        lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ->
            LocationManager.NETWORK_PROVIDER
        lm.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
        else -> null
    }

    private fun requestCurrent(lm: LocationManager): Location? {
        val provider = bestProvider(lm) ?: return null
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            requestCurrentModern(lm, provider)
        } else {
            requestSingleLegacy(lm, provider)
        }
    }

    // API 30+: getCurrentLocation with a real CancellationSignal we cancel on
    // timeout so a slow acquisition can't keep the radio powered.
    private fun requestCurrentModern(lm: LocationManager, provider: String): Location? {
        val latch = CountDownLatch(1)
        val holder = arrayOfNulls<Location>(1)
        val signal = CancellationSignal()
        val executor = Executors.newSingleThreadExecutor()
        try {
            lm.getCurrentLocation(provider, signal, executor) { loc ->
                holder[0] = loc
                latch.countDown()
            }
            if (!latch.await(CURRENT_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
                signal.cancel() // gave up — stop the acquisition
            }
        } catch (e: SecurityException) {
            return null
        } finally {
            executor.shutdown()
        }
        return holder[0]
    }

    // API 26–29: getCurrentLocation doesn't exist; a one-shot update covers the
    // sizeable minSdk-26 population that would otherwise never get a fresh fix.
    @Suppress("DEPRECATION")
    private fun requestSingleLegacy(lm: LocationManager, provider: String): Location? {
        val latch = CountDownLatch(1)
        val holder = arrayOfNulls<Location>(1)
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                holder[0] = location
                latch.countDown()
            }

            override fun onProviderEnabled(provider: String) {}

            override fun onProviderDisabled(provider: String) {}

            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        }
        try {
            lm.requestSingleUpdate(provider, listener, Looper.getMainLooper())
            latch.await(CURRENT_TIMEOUT_MS, TimeUnit.MILLISECONDS)
        } catch (e: SecurityException) {
            return null
        } finally {
            lm.removeUpdates(listener)
        }
        return holder[0]
    }
}
