package com.exptech.dpip.widget

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * The declarations a launcher and the framework read, asserted as declarations.
 *
 * These are the widget's contract with the *system*: the metadata decides whether
 * the widget can be resized, how it is configured, whether the launcher offers a
 * reconfigure button, and what the gallery shows; the manifest decides whether
 * the framework can reach the provider at all. None of it is exercised by
 * inflating a layout, and all of it fails silently when it is wrong — a missing
 * `configure` means the picker opens with no location chosen, and a missing
 * `widgetFeatures` means no reconfigure entry on a modern launcher.
 */
class WidgetRegistrationTest {
    private fun file(vararg candidates: String): File {
        for (candidate in candidates) {
            val file = File(candidate)
            if (file.isFile) return file
        }
        error("not found: ${candidates.joinToString()}")
    }

    private val metadata: String
        get() = file(
            "src/main/res/xml/weather_widget_info.xml",
            "app/src/main/res/xml/weather_widget_info.xml",
        ).readText()

    private val manifest: String
        get() = file("src/main/AndroidManifest.xml", "app/src/main/AndroidManifest.xml").readText()

    @Test
    fun `the metadata lets the framework schedule, configure and resize the widget`() {
        assertTrue(
            "updatePeriodMillis must be 0 — WorkManager owns the cadence",
            metadata.contains("android:updatePeriodMillis=\"0\""),
        )
        assertTrue(
            "the framework needs a configure Activity",
            metadata.contains(
                "android:configure=\"com.exptech.dpip.widget.WeatherWidgetConfigurationActivity\"",
            ),
        )
        assertTrue(
            "resizable in both directions",
            metadata.contains("android:resizeMode=\"horizontal|vertical\""),
        )
        assertTrue(
            "the initial layout is what a launcher draws before the first update",
            metadata.contains("android:initialLayout=\"@layout/widget_small\""),
        )
        assertTrue(
            "the resize range is bounded: responsive layouts must cover " +
                "minResize..maxResize, and an unbounded range leaves that " +
                "contract with nothing to stand on",
            metadata.contains("android:minResizeWidth=") &&
                metadata.contains("android:minResizeHeight=") &&
                metadata.contains("android:maxResizeWidth=") &&
                metadata.contains("android:maxResizeHeight="),
        )
    }

    @Test
    fun `the launcher owns reconfiguration without an in-widget settings button`() {
        // Older launchers without this system affordance require re-adding.
        assertTrue(
            metadata.contains("android:widgetFeatures=\"reconfigurable\""),
        )
        assertTrue(metadata.contains("android:configure="))
        for (name in listOf("widget_small", "widget_small_compact", "widget_medium",
            "widget_large", "widget_large_tight", "widget_empty")) {
            val layout = file("src/main/res/layout/$name.xml", "app/src/main/res/layout/$name.xml").readText()
            assertFalse("$name must not offer settings", layout.contains("@+id/widget_reconfigure"))
            assertFalse("$name must not draw a gear", layout.contains("@drawable/ic_widget_settings"))
        }
    }

    @Test
    fun `the gallery has a preview for every launcher generation`() {
        // API 31+ draws `previewLayout`; below that it asks for `previewImage`
        // and falls back to the app icon without one.
        assertTrue(metadata.contains("android:previewLayout=\"@layout/widget_preview\""))
        assertTrue(metadata.contains("android:previewImage=\"@drawable/widget_preview_image\""))
    }

    @Test
    fun `the provider, the reconcile receiver and the configuration Activity are declared`() {
        for (component in listOf(
            ".widget.WeatherWidgetProvider",
            ".widget.WidgetReconcileReceiver",
            ".widget.WeatherWidgetConfigurationActivity",
            ".widget.WidgetClockReceiver",
        )) {
            assertTrue("$component must be declared", manifest.contains(component))
        }
        assertTrue(manifest.contains("android.appwidget.action.APPWIDGET_UPDATE"))
        assertTrue(manifest.contains("android.appwidget.action.APPWIDGET_CONFIGURE"))
        assertTrue(manifest.contains("android.appwidget.provider"))
        // A clock change re-renders and re-arms the local redraw.
        assertTrue(manifest.contains("android.intent.action.TIME_SET"))
        assertTrue(manifest.contains("android.intent.action.TIMEZONE_CHANGED"))
    }

    @Test
    fun `the provider receiver is not exported and the configuration Activity is`() {
        // The APPWIDGET_UPDATE broadcast is sent by the system, which reaches a
        // non-exported receiver; the launcher is what starts the configuration
        // Activity, so that one has to be reachable.
        val provider = manifest.substring(manifest.indexOf(".widget.WeatherWidgetProvider"))
        assertTrue(provider.take(200).contains("android:exported=\"false\""))
        val activity = manifest.substring(
            manifest.indexOf(".widget.WeatherWidgetConfigurationActivity"),
        )
        assertTrue(activity.take(200).contains("android:exported=\"true\""))
        assertFalse(
            "the clock receiver must not be reachable by other apps",
            manifest.substring(manifest.indexOf(".widget.WidgetClockReceiver"))
                .take(200)
                .contains("android:exported=\"true\""),
        )
    }
}
