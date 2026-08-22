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
    /**
     * How far the device must get from the last reported point before the fence
     * calls it a move.
     *
     * 150 m, not the 200 m this used to be, and not less than 150 either. The
     * geofencing service positions the device from network location — Wi-Fi and
     * cell, not GNSS — which Google documents as accurate to 20–50 m with Wi-Fi
     * around and to hundreds of metres without it. A fence tighter than about
     * 100 m sits inside that error, and the device then oscillates in and out of
     * it without moving at all. 150 m is the tightest radius that is still
     * outside the noise.
     */
    private const val RADIUS_M = 150f

    /**
     * How long the service may sit on a delivered transition before telling us.
     *
     * Read it as an entitlement to be late that we hand to Play services, not as
     * a sampling rate — the reference calls it "best-effort notification
     * responsiveness", and warns that a small value "doesn't necessarily mean
     * you will get notified right after the user enters or exits a geofence:
     * internally, the geofence might adjust the responsiveness value to save
     * power". A lower number cannot make delivery faster than the platform
     * manages; it only stops us asking it to wait longer than that.
     *
     * Two minutes, down from the five this used to be. Five was the wrong trade
     * for an app whose report decides which township the user is pushed
     * earthquake alerts for: it granted Play services the right to hold a
     * crossing for longer than the whole end-to-end latency usually is, on top
     * of the 2-6 minutes of detection the guide already warns about.
     *
     * Not 0 either, even though 0 is the Builder's own default. Since Android
     * 8.0 the background location limits put practical responsiveness at
     * "approximately two minutes" whatever is asked for, and the reference says
     * plainly that a bigger value "can save power significantly" — so the cost
     * is monotone in what we request while the delivery below ~2 min is not
     * ours to buy. 0 would pay a wakeup premium for latency the platform has
     * already said it will not deliver.
     */
    private const val RESPONSIVENESS_MS = 120_000 // 2 min
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
     * The centre is persisted only once Play services accepts registration, so
     * a refused re-arm cannot replace the last usable centre. Acceptance is not
     * treated as proof that transitions are healthy; only [GeofenceReceiver]
     * may defer the independent alarm after a real EXIT delivery.
     *
     * [onArmed] reports whether Play services accepted the registration.
     * Registration is asynchronous, so a caller that needs to know — the one
     * deciding whether the alarm fallback can be stood down — cannot infer it
     * from this function returning. It is invoked on the main looper (Play
     * services' default listener thread), exactly once, for every outcome
     * including the permission refusal above.
     *
     * Deliberately a callback and not a blocking await: [LocationBootReceiver]
     * and [GeofenceReceiver]'s error path both call this straight from
     * `onReceive`, and `Tasks.await` throws when called on the main thread.
     */
    @SuppressLint("MissingPermission")
    fun register(
        context: Context,
        lat: Double,
        lng: Double,
        onArmed: ((Boolean) -> Unit)? = null,
    ) {
        if (!BgLocationStore.enabled(context)) {
            onArmed?.invoke(false)
            return
        }
        if (!hasPermission(context)) {
            Log.w(TAG, "background/fine location not granted — geofence not armed")
            BgLocationStore.setArmed(context, false)
            onArmed?.invoke(false)
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
            // around a stale centre after a reboot or a Play-services update) so
            // the spine self-heals; harmless when the device is inside.
            //
            // EXIT *alone*, never OR'd with ENTER. The flag is documented as
            // "trigger GEOFENCE_TRANSITION_EXIT at the moment when the geofence
            // is added and if the device is already outside that geofence", but
            // android/location-samples#103 reports that combining the two
            // initial triggers yields enter events only — so adding an ENTER bit
            // here would silently cost the self-heal this line exists for.
            //
            // Best-effort, not a guarantee; the independent alarm remains
            // scheduled even after registration succeeds.
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_EXIT)
            .addGeofence(geofence)
            .build()
        LocationServices.getGeofencingClient(context)
            .addGeofences(request, pendingIntent(context))
            .addOnSuccessListener {
                // stop() can race an in-flight binder request. If it won while
                // Play services was answering, remove the late registration
                // instead of resurrecting background work after disable.
                if (!BgLocationStore.enabled(context)) {
                    remove(context)
                    onArmed?.invoke(false)
                    return@addOnSuccessListener
                }
                BgLocationStore.saveLast(context, lat, lng)
                BgLocationStore.setArmed(context, true)
                onArmed?.invoke(true)
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "addGeofences failed", e)
                BgLocationStore.setArmed(context, false)
                onArmed?.invoke(false)
            }
    }

    fun remove(context: Context) {
        BgLocationStore.setArmed(context, false)
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
