package com.exptech.dpip.widget

import android.app.Application
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentSender
import android.os.Bundle
import android.view.View
import android.widget.FrameLayout
import androidx.test.core.app.ApplicationProvider
import com.exptech.dpip.MainActivity
import com.exptech.dpip.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.fakes.RoboIntentSender

/** Invoke the intent attached by RemoteViews.apply, including its platform flags. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 35])
class WidgetPendingIntentWiringTest {
    private val sent = mutableListOf<PendingIntent>()
    private val context: Context = object : ContextWrapper(ApplicationProvider.getApplicationContext()) {
        override fun startIntentSender(
            intent: IntentSender, fillInIntent: Intent?, flagsMask: Int,
            flagsValues: Int, extraFlags: Int, options: Bundle?,
        ) {
            // Observe the actual sender invoked by the framework click listener.
            // Robolectric exposes its token without Android's private view tags;
            // delegation still performs the real shadow broadcast/activity send.
            sent += (intent as RoboIntentSender).pendingIntent
            super.startIntentSender(intent, fillInIntent, flagsMask, flagsValues, extraFlags, options)
        }
    }

    private fun rendered(id: Int): View = WidgetRenderer.render(
        context,
        WidgetPresenter.present(
            sizeClass = WidgetSizeClass.Small,
            strings = WidgetUpdater.strings(context),
            address = WidgetAddress.Saved("407"), locationName = null, stored = null, forecast = null,
            locationDegradation = null, isCatalogMember = true,
            calibratedNowMilliseconds = null, latitude = null, longitude = null,
        ), id,
    ).apply(context, FrameLayout(context))

    private fun pendingIntent(root: View, viewId: Int): PendingIntent {
        val target = root.findViewById<View>(viewId)
        assertEquals(View.VISIBLE, target.visibility)
        assertTrue(target.isEnabled)
        val count = sent.size
        assertTrue(target.performClick())
        assertEquals("the applied click must invoke exactly one PendingIntent", count + 1, sent.size)
        return sent.last()
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

    @Test
    @Config(sdk = [26, 35])
    fun `reapply removes and restores the actual refresh intent across feedback states`() {
        // Start with an actionable no-data face, then reapply on that very
        // layout so a previous listener cannot hide behind a newly inflated view.
        val base = WidgetPresenter.present(
            sizeClass = WidgetSizeClass.Small,
            strings = WidgetUpdater.strings(context),
            address = WidgetAddress.Saved("407"), locationName = null, stored = null, forecast = null,
            locationDegradation = null, isCatalogMember = true,
            calibratedNowMilliseconds = null, latitude = null, longitude = null,
        )
        val view = WidgetRenderer.render(context, base, 11).apply(context, FrameLayout(context))
        val original = pendingIntent(view, R.id.widget_refresh)
        val refresh = view.findViewById<View>(R.id.widget_refresh)
        val app = shadowOf(ApplicationProvider.getApplicationContext<Application>())
        for (feedback in listOf(WidgetRefreshFeedback.Running, WidgetRefreshFeedback.Failed,
            WidgetRefreshFeedback.Queued, null)) {
            WidgetRenderer.render(context, base.copy(refreshFeedback = feedback), 11).reapply(context, view)
            val busy = feedback == WidgetRefreshFeedback.Queued || feedback == WidgetRefreshFeedback.Running
            if (busy) {
                val count = app.broadcastIntents.size
                val sends = sent.size
                assertEquals(View.VISIBLE, refresh.visibility)
                assertFalse(refresh.isEnabled)
                assertFalse(refresh.hasOnClickListeners())
                assertFalse(refresh.performClick())
                assertEquals(count, app.broadcastIntents.size)
                assertEquals(sends, sent.size)
            } else {
                assertEquals(original, pendingIntent(view, R.id.widget_refresh))
                assertEquals(11, app.broadcastIntents.last { it.action == WidgetRenderer.ACTION_REFRESH }
                    .getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1))
                assertEquals(ComponentName(context, WeatherWidgetProvider::class.java),
                    app.broadcastIntents.last().component)
            }
        }
        val count = app.broadcastIntents.size
        val sends = sent.size
        WidgetRenderer.render(context, base.copy(canRefresh = false), 11).reapply(context, view)
        assertEquals(View.GONE, refresh.visibility)
        assertFalse(refresh.isEnabled)
        assertFalse(refresh.hasOnClickListeners())
        assertFalse(refresh.performClick())
        assertEquals(count, app.broadcastIntents.size)
        assertEquals(sends, sent.size)
        // Rendering another instance while A is hidden must not retarget A
        // when reapply restores its listener.
        val other = rendered(12)
        assertNotEquals(original, pendingIntent(other, R.id.widget_refresh))
        WidgetRenderer.render(context, base, 11).reapply(context, view)
        assertEquals(View.VISIBLE, refresh.visibility)
        assertEquals(original, pendingIntent(view, R.id.widget_refresh))
        val delivered = app.broadcastIntents.last()
        assertEquals(WidgetRenderer.ACTION_REFRESH, delivered.action)
        assertEquals(ComponentName(context, WeatherWidgetProvider::class.java), delivered.component)
        assertEquals(11, delivered.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1))
    }
}
