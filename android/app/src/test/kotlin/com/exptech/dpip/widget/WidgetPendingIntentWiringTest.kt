package com.exptech.dpip.widget

import android.app.Application
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.view.View
import android.widget.FrameLayout
import androidx.test.core.app.ApplicationProvider
import com.exptech.dpip.MainActivity
import com.exptech.dpip.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/** Read the intent attached by RemoteViews.apply, including its platform flags. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class WidgetPendingIntentWiringTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()

    private fun rendered(id: Int): View = WidgetRenderer.render(
        context,
        WidgetPresenter.present(
            sizeClass = WidgetSizeClass.Small,
            strings = WidgetUpdater.strings(context),
            address = null, locationName = null, stored = null, forecast = null,
            locationDegradation = null, isCatalogMember = false,
            calibratedNowMilliseconds = null, latitude = null, longitude = null,
        ), id,
    ).apply(context, FrameLayout(context))

    private fun pendingIntent(root: View, viewId: Int): PendingIntent {
        // Framework RemoteViews stores the applied PendingIntent here for host
        // transitions. Do not recreate it with the production requestCode formula:
        // that would test our copy rather than the renderer's actual attachment.
        val tagId = context.resources.getIdentifier("pending_intent_tag", "id", "android")
        assertTrue("framework PendingIntent tag must exist", tagId != 0)
        val pending = root.findViewById<View>(viewId).getTag(tagId)
        assertTrue("the rendered target must carry a PendingIntent", pending is PendingIntent)
        return pending as PendingIntent
    }

    @Test fun `render B does not retarget A refresh action component or instance id`() {
        val a = rendered(11)
        val refreshA = pendingIntent(a, R.id.widget_refresh)
        val b = rendered(12)
        val refreshB = pendingIntent(b, R.id.widget_refresh)
        assertNotEquals(refreshA, refreshB)
        for ((pending, id) in listOf(refreshA to 11, refreshB to 12)) {
            val shadow = shadowOf(pending)
            assertTrue(shadow.isBroadcast)
            assertEquals(PendingIntent.FLAG_IMMUTABLE, shadow.flags and PendingIntent.FLAG_IMMUTABLE)
            assertEquals(WidgetRenderer.ACTION_REFRESH, shadow.savedIntent.action)
            assertEquals(ComponentName(context, WeatherWidgetProvider::class.java), shadow.savedIntent.component)
            assertEquals(id, shadow.savedIntent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID,
            ))
        }
        // Send A after B has rendered. Intent identity ignores extras, so removing
        // per-instance identity would rewrite this very token to carry B's id.
        assertTrue(a.findViewById<View>(R.id.widget_refresh).performClick())
        val delivered = shadowOf(ApplicationProvider.getApplicationContext<Application>())
            .broadcastIntents.last { it.action == WidgetRenderer.ACTION_REFRESH }
        assertEquals(11, delivered.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1))
        assertEquals(ComponentName(context, WeatherWidgetProvider::class.java), delivered.component)
    }

    @Test fun `surface pending intent opens home in explicit MainActivity and is immutable`() {
        val a = rendered(11)
        val open = pendingIntent(a, android.R.id.background)
        rendered(12)
        val shadow = shadowOf(open)
        assertTrue(shadow.isActivity)
        assertEquals(PendingIntent.FLAG_IMMUTABLE, shadow.flags and PendingIntent.FLAG_IMMUTABLE)
        assertEquals(WidgetRenderer.ACTION_OPEN_HOME, shadow.savedIntent.action)
        assertEquals(ComponentName(context, MainActivity::class.java), shadow.savedIntent.component)
        assertTrue(a.findViewById<View>(android.R.id.background).performClick())
        val delivered = shadowOf(ApplicationProvider.getApplicationContext<Application>()).nextStartedActivity
        assertNotNull(delivered)
        assertEquals(WidgetRenderer.ACTION_OPEN_HOME, delivered.action)
        assertEquals(ComponentName(context, MainActivity::class.java), delivered.component)
    }
}
