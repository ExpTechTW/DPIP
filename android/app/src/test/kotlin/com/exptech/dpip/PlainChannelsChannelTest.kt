package com.exptech.dpip

import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import androidx.test.core.app.ApplicationProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The channel each plain id is created with is the channel it keeps: Android
 * freezes a channel's sound at creation. These pin that what Dart sends is what
 * gets created — above all the audio usage, which once came out as
 * `USAGE_ALARM` for every channel with a sound file, putting reports and
 * monitors on the alarm volume (#660).
 */
@RunWith(RobolectricTestRunner::class)
class PlainChannelsChannelTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val manager: NotificationManager
        get() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private lateinit var channel: PlainChannelsChannel

    @Before
    fun setUp() {
        manager.notificationChannels.forEach { manager.deleteNotificationChannel(it.id) }
        channel = PlainChannelsChannel(context)
    }

    private class RecordingResult : MethodChannel.Result {
        var value: Any? = null
        var errorCode: String? = null

        override fun success(result: Any?) {
            value = result
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            this.errorCode = errorCode
        }

        override fun notImplemented() {
            errorCode = "notImplemented"
        }
    }

    private fun call(method: String, arguments: Map<String, Any?>) =
        RecordingResult().also { channel.onMethodCall(MethodCall(method, arguments), it) }

    private fun ensure(vararg channels: Map<String, Any?>, groups: List<Map<String, Any?>> = emptyList()) =
        call("ensure", mapOf("groups" to groups, "channels" to channels.toList()))

    private fun entry(id: String, vararg fields: Pair<String, Any?>) =
        mapOf("id" to id, "name" to id, "importance" to 4) + fields

    @Test
    fun `a general channel is created on the notification stream`() {
        ensure(entry("report-general-v2", "playSound" to true, "usage" to 5, "sound" to "report"))

        val created = manager.getNotificationChannel("report-general-v2")
        assertEquals(AudioAttributes.USAGE_NOTIFICATION, created.audioAttributes.usage)
        assertTrue(created.sound.toString().startsWith("android.resource://${context.packageName}/"))
    }

    @Test
    fun `an alarm channel is created on the alarm stream`() {
        ensure(entry("eew_alert-important-v2", "playSound" to true, "usage" to 4, "sound" to "eew_alert"))

        val created = manager.getNotificationChannel("eew_alert-important-v2")
        assertEquals(AudioAttributes.USAGE_ALARM, created.audioAttributes.usage)
        assertEquals(
            AudioAttributes.CONTENT_TYPE_SONIFICATION,
            created.audioAttributes.contentType,
        )
    }

    @Test
    fun `no usage at all means the notification stream, never the alarm`() {
        ensure(entry("announcement-general-v2", "sound" to "info"))

        val created = manager.getNotificationChannel("announcement-general-v2")
        assertEquals(AudioAttributes.USAGE_NOTIFICATION, created.audioAttributes.usage)
    }

    @Test
    fun `a channel with no file of its own gets the default sound for its stream`() {
        ensure(
            entry("mesh_message", "playSound" to true, "usage" to 5),
            entry("alarm_without_file", "playSound" to true, "usage" to 4, "sound" to "missing"),
        )

        assertEquals(
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
            manager.getNotificationChannel("mesh_message").sound,
        )
        assertEquals(
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
            manager.getNotificationChannel("alarm_without_file").sound,
        )
    }

    @Test
    fun `a silent channel gets no sound`() {
        ensure(entry("eew_alert-silent-v2", "playSound" to false))

        assertNull(manager.getNotificationChannel("eew_alert-silent-v2").sound)
    }

    @Test
    fun `groups are created first, so a fresh install files its channels`() {
        ensure(
            entry("eq-v2", "group" to "group_eq", "usage" to 5, "sound" to "eq"),
            entry("orphan", "group" to "group_missing"),
            groups = listOf(mapOf("id" to "group_eq", "name" to "地震")),
        )

        assertEquals("地震", manager.notificationChannelGroups.single { it.id == "group_eq" }.name)
        assertEquals("group_eq", manager.getNotificationChannel("eq-v2").group)
        // A group nobody sent is not invented, and does not cost the channel.
        assertNull(manager.getNotificationChannel("orphan").group)
    }

    @Test
    fun `vibration, lights and badge are built the way awesome builds them`() {
        ensure(
            entry(
                "eew-important-v2",
                "usage" to 4,
                "enableVibration" to true,
                // How the standard codec delivers Dart's Int64List.
                "vibrationPattern" to longArrayOf(0, 1000, 200),
                "enableLights" to true,
                "ledColor" to 0xFFF44336.toInt(),
                "showBadge" to false,
            ),
        )

        val created = manager.getNotificationChannel("eew-important-v2")
        assertArrayEquals(longArrayOf(0, 1000, 200), created.vibrationPattern)
        assertTrue(created.shouldVibrate())
        assertTrue(created.shouldShowLights())
        assertEquals(0xFFF44336.toInt(), created.lightColor)
        assertFalse(created.canShowBadge())
    }

    @Test
    fun `an existing channel is never rewritten`() {
        ensure(entry("eq-v2", "usage" to 4, "sound" to "eq"))

        val result = ensure(entry("eq-v2", "usage" to 5, "sound" to "eq"))

        assertEquals(0, result.value)
        assertEquals(
            AudioAttributes.USAGE_ALARM,
            manager.getNotificationChannel("eq-v2").audioAttributes.usage,
        )
    }
}
