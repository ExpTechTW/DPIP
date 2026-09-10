package com.exptech.dpip

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Android-owned labels and app-specific Settings destinations.
 *
 * A generic app-details intent is a poor fallback for every permission: Android
 * exposes a dedicated notification page, and Android 11+ exposes the exact,
 * localized label the user must choose for background location. Keeping those
 * details native also means the Flutter guide matches the device language even
 * when DPIP itself is using a different locale.
 */
class PermissionSettingsChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/permission_settings"
        private const val TAG = "PermissionSettings"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "backgroundLocationOptionLabel" -> result.success(backgroundLocationOptionLabel())
            "openNotificationSettings" -> result.success(openNotificationSettings())
            "urgentNotificationChannelStatus" -> urgentNotificationChannelStatus(call, result)
            "openNotificationChannelSettings" -> openNotificationChannelSettings(call, result)
            else -> result.notImplemented()
        }
    }

    private fun urgentNotificationChannelStatus(call: MethodCall, result: MethodChannel.Result) {
        val channelIds = call.argument<List<*>>("channelIds")
        if (channelIds == null || channelIds.isEmpty() || channelIds.any { it !is String || it.isBlank() }) {
            result.error("invalid_channel_ids", "channelIds must be non-empty strings", null)
            return
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        val statuses = channelIds.associate { rawId ->
            val id = rawId as String
            val channel = manager.getNotificationChannel(id)
            id to channel?.let {
                mapOf(
                    "id" to it.id,
                    "name" to it.name.toString(),
                    "bypassesDnd" to it.canBypassDnd(),
                )
            }
        }
        result.success(statuses)
    }

    private fun openNotificationChannelSettings(call: MethodCall, result: MethodChannel.Result) {
        val channelId = call.argument<String>("channelId")
        if (channelId.isNullOrBlank()) {
            result.error("invalid_channel_id", "channelId must be a non-empty string", null)
            return
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(channelId) == null) {
            result.error("unknown_channel", "Notification channel does not exist", null)
            return
        }
        result.success(openNotificationChannelSettings(channelId))
    }

    private fun openNotificationChannelSettings(channelId: String): String {
        try {
            context.startActivity(
                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    .putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            return "channel"
        } catch (e: Exception) {
            Log.i(TAG, "channel notification settings unavailable", e)
        }
        return openNotificationSettings()
    }

    private fun backgroundLocationOptionLabel(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        return context.packageManager.backgroundPermissionOptionLabel.toString()
    }

    /** Opens DPIP's own notification switch, with app details as a safe fallback. */
    private fun openNotificationSettings(): String {
        try {
            context.startActivity(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            return "notifications"
        } catch (e: Exception) {
            Log.i(TAG, "app notification settings unavailable", e)
        }

        return try {
            context.startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            "appDetails"
        } catch (e: Exception) {
            Log.w(TAG, "no notification settings screen could be opened", e)
            "none"
        }
    }
}
