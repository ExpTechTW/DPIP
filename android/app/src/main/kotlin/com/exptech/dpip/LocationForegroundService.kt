package com.exptech.dpip

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class LocationForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "dpip_location_fg_channel"
        const val CHANNEL_NAME = "DPIP Location Foreground"
        const val NOTIFICATION_ID = 888888
        const val ACTION_START = "com.exptech.dpip.action.START_LOCATION_FG"
        const val ACTION_STOP = "com.exptech.dpip.action.STOP_LOCATION_FG"

        fun start(context: Context) {
            val i = Intent(context, LocationForegroundService::class.java)
            i.action = ACTION_START
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
        }

        fun stop(context: Context) {
            val i = Intent(context, LocationForegroundService::class.java)
            i.action = ACTION_STOP
            context.startService(i)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createChannelIfNeeded()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        when (action) {
            ACTION_START -> {
                val notification = buildNotification()
                startForeground(NOTIFICATION_ID, notification)
                // service stays alive while Dart does location work
            }
            ACTION_STOP -> {
                stopForeground(true)
                stopSelf()
            }
            else -> {
                // default: start foreground to be safe
                val notification = buildNotification()
                startForeground(NOTIFICATION_ID, notification)
            }
        }
        // We don't want the service to restart automatically if killed after stopSelf()
        return START_NOT_STICKY
    }

    private fun buildNotification(): Notification {
        // Tapping notification opens the app (MainActivity)
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                PendingIntent.FLAG_MUTABLE
            else
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("正在更新位置")
            .setContentText("取得 GPS 位置中...")
            .setSmallIcon(R.drawable.ic_stat_name) // 確保這個 resource 存在
            .setContentIntent(pendingIntent)
            .setOngoing(true) // important: ongoing makes it an "ongoing" notification
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val chan = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_DEFAULT)
            chan.setShowBadge(false)
            chan.lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            nm.createNotificationChannel(chan)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}