package com.exptech.dpip

import android.content.Context
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability

/**
 * Whether Google Play services (which host the Fused Location Provider and the
 * Geofencing API) are usable on this device. Selects the background spine: the
 * low-power geofence when present, the framework-`LocationManager` alarm
 * geofence fast path. [LocationAlarmScheduler] remains active independently on
 * every device.
 */
object GmsAvailability {
    fun available(context: Context): Boolean =
        GoogleApiAvailability.getInstance()
            .isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS
}
