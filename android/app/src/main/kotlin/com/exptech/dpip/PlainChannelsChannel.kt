package com.exptech.dpip

import android.app.NotificationChannel
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
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
 * survives ordinary launches, and Android would ignore the rewrite anyway.
 *
 * **Whoever creates a plain id first decides how it sounds, for good.** Android
 * freezes a channel's sound and audio attributes at creation, and deleting it
 * and creating the same id again brings the deleted one back as it was. So
 * Dart calls [ensure] before awesome registers anything, and on a fresh install
 * this is what creates every plain id; awesome then finds each one already
 * there and adopts it. The order matters because awesome builds every channel
 * with `USAGE_NOTIFICATION` whatever its `defaultRingtoneType` says
 * (`ChannelManager.setAndroidChannel` in AndroidAwnCore), which put the major
 * alerts on the notification volume. This side builds each channel the way
 * awesome would, except for the audio usage, which the catalogue decides
 * (`usage`, from `PlainChannels.usageOf` in Dart).
 *
 * The same freeze is why [usages] exists: an install whose plain ids an older
 * build created keeps that build's volumes through every update, and the only
 * way to know is to ask the system what each channel actually has. Dart compares
 * that with the catalogue and shows the notification settings page's entry
 * when they differ.
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
                val groups = call.argument<List<Map<*, *>>>("groups") ?: emptyList()
                val channels =
                    call.argument<List<Map<*, *>>>("channels") ?: emptyList()
                result.success(ensure(groups, channels))
            }

            "list" -> result.success(manager().notificationChannels.map { it.id })

            "usages" -> {
                val ids = call.argument<List<*>>("ids")
                if (ids == null || ids.any { it !is String || it.isBlank() }) {
                    result.error("invalid_ids", "ids must be non-empty strings", null)
                    return
                }
                result.success(usages(ids.filterIsInstance<String>()))
            }

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

    /**
     * The `AudioAttributes.USAGE_*` each of [ids] really plays on, read back
     * from the system rather than assumed from what this build would create.
     *
     * Left out: an id that does not exist, and a channel that plays no sound —
     * including one the user silenced in the OS settings, which has no volume
     * to be wrong about.
     */
    private fun usages(ids: List<String>): Map<String, Int> {
        val manager = manager()
        val usages = HashMap<String, Int>()
        for (id in ids) {
            val channel = manager.getNotificationChannel(id) ?: continue
            if (channel.sound == null) continue
            usages[id] = channel.audioAttributes?.usage ?: continue
        }
        return usages
    }

    /** Creates each missing group, then each missing channel; returns how many channels. */
    private fun ensure(groups: List<Map<*, *>>, channels: List<Map<*, *>>): Int {
        val manager = manager()
        // Groups first: Android rejects a channel that names a group it does
        // not have, and on a fresh install nothing has created them yet.
        val groupIds = manager.notificationChannelGroups.mapTo(HashSet()) { it.id }
        for (entry in groups) {
            val id = entry["id"] as? String ?: continue
            val name = entry["name"] as? String ?: continue
            if (!groupIds.add(id)) continue
            manager.createNotificationChannelGroup(NotificationChannelGroup(id, name))
        }

        var created = 0
        for (entry in channels) {
            val id = entry["id"] as? String ?: continue
            // Create-if-missing only: a channel that already exists may carry
            // settings the user tuned in the OS UI, and rewriting it would be
            // ignored for behaviour anyway — Android freezes created channels.
            if (manager.getNotificationChannel(id) != null) continue
            val channel = channelFrom(id, entry, groupIds) ?: continue
            manager.createNotificationChannel(channel)
            created++
        }
        return created
    }

    /**
     * The channel [entry] describes, field for field as awesome's own
     * `setAndroidChannel` would build it — so a channel created here is the
     * same channel an install whose ids awesome created has — with one
     * difference: the audio usage.
     */
    private fun channelFrom(
        id: String,
        entry: Map<*, *>,
        groupIds: Set<String>,
    ): NotificationChannel? {
        val name = entry["name"] as? String ?: return null
        val importance = (entry["importance"] as? Number)?.toInt()
            ?: NotificationManager.IMPORTANCE_DEFAULT

        val channel = NotificationChannel(id, name, importance)
        (entry["description"] as? String)?.let { channel.description = it }
        (entry["group"] as? String)?.takeIf { it in groupIds }?.let { channel.group = it }

        if (entry["playSound"] == false) {
            channel.setSound(null, null)
        } else {
            val usage = (entry["usage"] as? Number)?.toInt()
                ?: AudioAttributes.USAGE_NOTIFICATION
            val attributes = AudioAttributes.Builder()
                .setUsage(usage)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            channel.setSound(soundUri(entry["sound"] as? String, usage), attributes)
        }

        // In awesome's order: a vibration pattern switches vibration on by
        // itself, so the flag has to be set before it.
        channel.enableVibration(entry["enableVibration"] as? Boolean ?: true)
        vibrationPattern(entry["vibrationPattern"])?.let { channel.vibrationPattern = it }

        val lights = entry["enableLights"] as? Boolean ?: true
        channel.enableLights(lights)
        if (lights) (entry["ledColor"] as? Number)?.let { channel.lightColor = it.toInt() }

        if (entry["bypassDnd"] == true) channel.setBypassDnd(true)
        channel.setShowBadge(entry["showBadge"] as? Boolean ?: false)
        return channel
    }

    /**
     * The channel's own sound file, or — when it names none, or this APK does
     * not carry it — the device's default sound for the stream it plays on,
     * as awesome does.
     *
     * Read from the current APK resources, so the URI is correct by
     * construction — no stale numeric resource ids, ever.
     */
    private fun soundUri(sound: String?, usage: Int): Uri {
        if (sound != null) {
            val resId = context.resources.getIdentifier(sound, "raw", context.packageName)
            if (resId > 0) {
                return Uri.parse("android.resource://${context.packageName}/$resId")
            }
        }
        return RingtoneManager.getDefaultUri(
            if (usage == AudioAttributes.USAGE_ALARM) {
                RingtoneManager.TYPE_ALARM
            } else {
                RingtoneManager.TYPE_NOTIFICATION
            },
        )
    }

    /**
     * Dart's catalogue holds its patterns as `Int64List`, which the standard
     * codec delivers as a `LongArray` — not a `List`, which is what this used
     * to read, so every pattern was silently dropped.
     */
    private fun vibrationPattern(value: Any?): LongArray? {
        val pattern = when (value) {
            is LongArray -> value
            is IntArray -> value.map { it.toLong() }.toLongArray()
            is List<*> -> value.mapNotNull { (it as? Number)?.toLong() }.toLongArray()
            else -> return null
        }
        return pattern.takeIf { it.isNotEmpty() }
    }
}
