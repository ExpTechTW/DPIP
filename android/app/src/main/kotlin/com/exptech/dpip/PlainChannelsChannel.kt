package com.exptech.dpip

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Mirrors the notification catalogue under **plain, un-hashed channel IDs**.
 *
 * awesome_notifications derives each Android channel's ID from a hash of its
 * model, so the ID a locally-rendered notification targets is not stable
 * across builds. FCM's system-tray path cannot follow that dance at all: a
 * push carrying an FCM `notification` block is rendered by the SDK itself,
 * which looks up `android_channel_id` — the plain key from the backend —
 * verbatim, and falls back to the system default channel (system sound) the
 * moment it misses.
 *
 * [ensure] creates any missing plain-key channel straight through
 * NotificationManager. An existing channel is never touched — user tuning
 * survives ordinary launches, and the Dart-side catalogue-version gate is
 * what drives delete + re-create when the sound files themselves change.
 *
 * `list` and `delete` exist for the other end of a channel's life: the ids
 * earlier builds created and this one dropped, which Android keeps until the
 * app deletes them. *Which* ids are retired is decided in Dart
 * (`RetiredChannels`), where it is tested; this side only reports what exists
 * and deletes what it is told to.
 */
class PlainChannelsChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/plain_notification_channels"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ensure" -> {
                val channels =
                    call.argument<List<Map<*, *>>>("channels") ?: emptyList()
                result.success(ensure(channels))
            }

            "list" -> result.success(manager().notificationChannels.map { it.id })

            "delete" -> {
                val ids = call.argument<List<*>>("ids")
                if (ids == null || ids.any { it !is String || it.isBlank() }) {
                    result.error("invalid_ids", "ids must be non-empty strings", null)
                    return
                }
                result.success(delete(ids.filterIsInstance<String>()))
            }

            else -> result.notImplemented()
        }
    }

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** Deletes each of [ids] that exists; returns how many did. */
    private fun delete(ids: List<String>): Int {
        val manager = manager()
        var deleted = 0
        for (id in ids) {
            // Checked first so a repeat run reports 0 rather than a count of
            // deletes that did nothing — the log line says what changed.
            if (manager.getNotificationChannel(id) == null) continue
            manager.deleteNotificationChannel(id)
            deleted++
        }
        return deleted
    }

    private fun ensure(channels: List<Map<*, *>>): Int {
        val manager = manager()
        var created = 0
        for (entry in channels) {
            val id = entry["id"] as? String ?: continue
            // Create-if-missing only: a channel that already exists may carry
            // settings the user tuned in the OS UI, and rewriting it would be
            // ignored for behaviour anyway — Android freezes created channels.
            if (manager.getNotificationChannel(id) != null) continue

            val name = entry["name"] as? String ?: continue
            val importance = (entry["importance"] as? Number)?.toInt()
                ?: NotificationManager.IMPORTANCE_DEFAULT

            val channel = NotificationChannel(id, name, importance)
            (entry["description"] as? String)?.let { channel.description = it }
            (entry["group"] as? String)?.let { channel.group = it }

            // Read from the current APK resources, so the URI is correct by
            // construction — no stale numeric resource ids, ever.
            val sound = entry["sound"] as? String
            if (sound != null) {
                val resId =
                    context.resources.getIdentifier(sound, "raw", context.packageName)
                if (resId > 0) {
                    val attributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    channel.setSound(
                        Uri.parse("android.resource://${context.packageName}/$resId"),
                        attributes,
                    )
                }
            }

            (entry["vibrationPattern"] as? List<*>)?.let { pattern ->
                val longs = pattern.mapNotNull { (it as? Number)?.toLong() }
                    .toLongArray()
                if (longs.isNotEmpty()) channel.vibrationPattern = longs
            }
            (entry["ledColor"] as? Number)?.let { color ->
                channel.enableLights(true)
                channel.lightColor = color.toInt()
            }

            manager.createNotificationChannel(channel)
            created++
        }
        return created
    }
}
