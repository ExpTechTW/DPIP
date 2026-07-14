package com.exptech.dpip

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

/**
 * Registers a single self-re-centering **EXIT geofence** around the last
 * reported point — the primary, event-driven background spine.
 *
 * Why this over a periodic alarm: the OS monitors the geofence with low-power
 * cell/Wi-Fi sensors and fires only when the device actually leaves the area, so
 * a parked phone costs zero wakeups; the monitoring runs in the Google Play
 * services process, so it keeps firing even after an aggressive OEM battery
 * manager kills our app; and it's Doze-exempt. On exit, [GeofenceReceiver]
 * re-centres and reports. It is the direct Android analog of the iOS Significant
 * Location Change design.
 */
object GeofenceManager {
    private const val TAG = "GeofenceManager"
    private const val ID = "dpip.bg.town"
    private const val RADIUS_M = 200f
    // Trade responsiveness for power: the OS may batch the exit check up to this.
    private const val RESPONSIVENESS_MS = 300_000 // 5 min
    private const val REQUEST_CODE = 888891

    /** Whether background reporting can be armed (FINE + background location). */
    fun hasPermission(context: Context): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        if (!fine) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    /**
     * (Re-)registers the geofence centred on ([lat], [lng]). Adding a geofence
     * with the same id replaces the previous one, so this re-centres in place.
     * The centre is persisted only once registration actually succeeds, so a
     * failed (re-)arm can't leave the store believing a dead fence is live.
     */
    @SuppressLint("MissingPermission")
    fun register(context: Context, lat: Double, lng: Double) {
        if (!hasPermission(context)) {
            Log.w(TAG, "background/fine location not granted — geofence not armed")
            return
        }
        val geofence = Geofence.Builder()
            .setRequestId(ID)
            .setCircularRegion(lat, lng, RADIUS_M)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_EXIT)
            .setNotificationResponsiveness(RESPONSIVENESS_MS)
            .build()
        val request = GeofencingRequest.Builder()
            // Fire immediately if we register while already OUTSIDE (e.g. re-arm
            // around a stale centre after a reboot/GMS update) so the spine
            // self-heals; harmless when the device is inside.
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_EXIT)
            .addGeofence(geofence)
            .build()
        LocationServices.getGeofencingClient(context)
            .addGeofences(request, pendingIntent(context))
            .addOnSuccessListener { BgLocationStore.saveLast(context, lat, lng) }
            .addOnFailureListener { e -> Log.w(TAG, "addGeofences failed", e) }
    }

    fun remove(context: Context) {
        LocationServices.getGeofencingClient(context).removeGeofences(pendingIntent(context))
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GeofenceReceiver::class.java)
        // Geofencing requires a MUTABLE PendingIntent (the OS writes the
        // transition/location into it).
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }
}
