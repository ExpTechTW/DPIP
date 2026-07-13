package com.exptech.dpip

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.net.HttpURLConnection
import java.net.URL

/**
 * A foreground service that reports the device location to
 * `updateDeviceLocation` on distance-triggered moves, so location alerts keep
 * targeting the right township while the app is backgrounded.
 *
 * Uses the framework [LocationManager] (no Google Play Services dependency, per
 * the native-first convention) with a distance filter, and issues the GET itself
 * off the main thread. A low-importance ongoing notification satisfies the
 * foreground-service requirement; on Android 14+ it declares the `location`
 * service type.
 */
class LocationForegroundService : Service(), LocationListener {

    companion object {
        const val ACTION_START = "com.exptech.dpip.LOCATION_START"
        const val ACTION_STOP = "com.exptech.dpip.LOCATION_STOP"
        const val EXTRA_TOKEN = "token"
        const val EXTRA_VERSION = "version"
        const val EXTRA_PLATFORM = "platform"

        private const val CHANNEL_ID = "dpip_background_location"
        private const val NOTIF_ID = 4801
        private const val MIN_TIME_MS = 5 * 60 * 1000L // 5 minutes
        private const val MIN_DISTANCE_M = 250f
    }

    private var token: String? = null
    private var version: String? = null
    private var platform: Int = 0
    private var listening = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopUpdates()
            stopSelf()
            return START_NOT_STICKY
        }
        token = intent?.getStringExtra(EXTRA_TOKEN) ?: token
        version = intent?.getStringExtra(EXTRA_VERSION) ?: version
        platform = intent?.getIntExtra(EXTRA_PLATFORM, platform) ?: platform

        startForegroundNotification()
        startUpdates()
        return START_STICKY
    }

    private fun startForegroundNotification() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "背景定位",
                    NotificationManager.IMPORTANCE_MIN,
                ).apply { description = "在背景更新所在地以推送在地災害警報" },
            )
        }
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DPIP 背景定位")
            .setContentText("持續更新所在地以推送在地災害警報")
            .setSmallIcon(R.drawable.ic_stat_name)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun startUpdates() {
        if (listening) return
        val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                lm.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER, MIN_TIME_MS, MIN_DISTANCE_M, this,
                )
            }
            if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                lm.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER, MIN_TIME_MS, MIN_DISTANCE_M, this,
                )
            }
            listening = true
        } catch (e: SecurityException) {
            // Location permission not granted — idle until it is.
        }
    }

    private fun stopUpdates() {
        if (!listening) return
        (getSystemService(Context.LOCATION_SERVICE) as LocationManager).removeUpdates(this)
        listening = false
    }

    override fun onLocationChanged(location: Location) {
        val t = token ?: return
        val v = version ?: return
        report(platform, t, v, location.latitude, location.longitude)
    }

    override fun onDestroy() {
        stopUpdates()
        super.onDestroy()
    }

    private fun report(platform: Int, token: String, version: String, lat: Double, lng: Double) {
        Thread {
            try {
                // coreExclusiveApi is tnn1-only (no failover).
                val url = URL(
                    "https://api.core-tnn1.exptech.dev/api/v2/location/" +
                        "$platform/$token/$version/$lat,$lng",
                )
                (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 10_000
                    readTimeout = 10_000
                    responseCode // fire the request
                    disconnect()
                }
            } catch (e: Exception) {
                // Best-effort; the next move retries.
            }
        }.start()
    }

    override fun onProviderEnabled(provider: String) {}

    override fun onProviderDisabled(provider: String) {}

    @Deprecated("Required by LocationListener on API < 29")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
}
