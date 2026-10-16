package com.exptech.dpip.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.Button
import android.widget.ListView
import androidx.test.core.app.ApplicationProvider
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.WorkManagerTestInitHelper
import com.exptech.dpip.R
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

/**
 * The configuration screen's result contract.
 *
 * The two directions are different and both matter: an *add* that is cancelled
 * must leave the user with no Widget, and a *reconfigure* that is cancelled must
 * leave the existing Widget exactly as it was. The first version answered
 * `RESULT_CANCELED` in both cases, which would ask the launcher to undo a
 * reconfiguration the user had merely backed out of.
 */
@RunWith(RobolectricTestRunner::class)
@org.robolectric.annotation.Config(sdk = [26, 35])
class WeatherWidgetConfigurationActivityTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private lateinit var store: WidgetStore

    private val appWidgetId = 42

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        // The Activity uses the process singleton; a stale one would keep a
        // connection to the previous test's deleted file.
        WidgetStore.resetForTest()
        store = WidgetStore.openUncached(context)
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
    }

    @After
    fun tearDown() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
    }

    private fun intent(appWidgetId: Int = this.appWidgetId) =
        Intent(context, WeatherWidgetConfigurationActivity::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_CONFIGURE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }

    private fun launch(id: Int = appWidgetId) = Robolectric.buildActivity(
        WeatherWidgetConfigurationActivity::class.java,
        intent(id),
    ).create().start().resume()

    private fun catalog(vararg codes: String) {
        store.writeCatalog(
            codes.map { WidgetCatalogLocation.create(it, "第${it}區", "縣", 24.181, 120.645)!! },
            1L,
        )
    }

    @Test
    fun `an invalid instance id finishes immediately as cancelled`() {
        val controller = Robolectric.buildActivity(
            WeatherWidgetConfigurationActivity::class.java,
            intent(appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID),
        ).create()

        val activity = controller.get()
        assertTrue(activity.isFinishing)
        assertEquals(Activity.RESULT_CANCELED, shadowOf(activity).resultCode)
    }

    @Test
    fun `cancelling an add leaves nothing behind`() {
        catalog("407")
        val controller = launch()

        controller.get().findViewById<Button>(R.id.widget_config_cancel).performClick()

        assertTrue(controller.get().isFinishing)
        assertEquals(Activity.RESULT_CANCELED, shadowOf(controller.get()).resultCode)
        assertNull(store.readInstance(appWidgetId))
    }

    @Test
    fun `cancelling a reconfigure keeps the configured town`() {
        catalog("407", "100")
        store.writeInstance(appWidgetId, WidgetAddress.Saved("407"), "407", 1L)
        val controller = launch()

        controller.get().findViewById<Button>(R.id.widget_config_cancel).performClick()

        // "No change" is what the launcher understands as RESULT_OK here; the
        // stored choice is untouched either way.
        assertEquals(Activity.RESULT_OK, shadowOf(controller.get()).resultCode)
        assertEquals(WidgetAddress.Saved("407"), store.readInstance(appWidgetId)!!.address)
    }

    @Test
    fun `choosing a town stores it, results ok, and asks for that source`() {
        catalog("407", "100")
        val controller = launch()

        val list = controller.get().findViewById<ListView>(R.id.widget_config_list)
        // Row 0 is the current position; row 1 is the first saved town. The
        // listener is invoked directly: `performItemClick` needs a laid-out
        // child view and Robolectric has not measured the list.
        list.onItemClickListener!!.onItemClick(list, null, 1, 1)

        assertTrue(controller.get().isFinishing)
        assertEquals(Activity.RESULT_OK, shadowOf(controller.get()).resultCode)
        assertEquals(WidgetAddress.Saved("407"), store.readInstance(appWidgetId)!!.address)

        val work = WorkManager.getInstance(context)
            .getWorkInfosForUniqueWork(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
            .get()
        assertEquals(1, work.size)
        assertTrue(work.first().state == WorkInfo.State.ENQUEUED)
    }

    @Test
    fun `an empty catalog says so and offers the app instead of inventing a location`() {
        val controller = launch()
        val activity = controller.get()

        assertEquals(View.VISIBLE, activity.findViewById<View>(R.id.widget_config_message).visibility)
        assertEquals(View.VISIBLE, activity.findViewById<View>(R.id.widget_config_open_app).visibility)
        val list = activity.findViewById<ListView>(R.id.widget_config_list)
        // Only the current-position row is offered.
        assertEquals(1, list.adapter.count)
    }

    @Test
    fun `a populated catalog explains the choice and offers the saved towns`() {
        catalog("407", "100")
        val activity = launch().get()

        assertEquals(View.VISIBLE, activity.findViewById<View>(R.id.widget_config_message).visibility)
        assertEquals(View.GONE, activity.findViewById<View>(R.id.widget_config_open_app).visibility)
        val list = activity.findViewById<ListView>(R.id.widget_config_list)
        // Current position plus the two saved towns.
        assertEquals(3, list.adapter.count)
    }

    @Test
    fun `the current-position row is offered first and selects the current location`() {
        catalog("407")
        val activity = launch().get()
        val list = activity.findViewById<ListView>(R.id.widget_config_list)
        assertEquals(2, list.adapter.count)
        // Row 0 is the current position: choosing it stores the current-location
        // address rather than any saved town.
        list.onItemClickListener!!.onItemClick(list, null, 0, 0)
        assertEquals(WidgetAddress.CurrentLocation, store.readInstance(appWidgetId)!!.address)
    }

    // ── The reused-instance path (`singleTop` + the gear's `CLEAR_TOP`) ──

    /**
     * The two widgets the reuse path is about: A's screen is already open when
     * B's gear is tapped.
     */
    private fun twoConfiguredWidgets(): Pair<Int, Int> {
        catalog("407", "100", "200")
        val a = 42
        val b = 43
        store.writeInstance(a, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(b, WidgetAddress.Saved("100"), "100", 1L)
        return a to b
    }

    @Test
    fun `a second gear tap retargets the live screen to that widget`() {
        val (a, b) = twoConfiguredWidgets()
        val controller = launch(a)

        // A has not finished. The launcher delivers B's intent to the same
        // `singleTop` instance, exactly as `CLEAR_TOP` does on a device.
        controller.newIntent(intent(b))

        // Row 0 is current position; rows 1..3 are 407, 100, 200. Choosing 200
        // must land on B — the widget whose gear was tapped last.
        val list = controller.get().findViewById<ListView>(R.id.widget_config_list)
        list.onItemClickListener!!.onItemClick(list, null, 3, 3)

        assertEquals(
            "the choice must land on the widget whose gear was tapped last",
            WidgetAddress.Saved("200"),
            store.readInstance(b)!!.address,
        )
        assertEquals(
            "the widget whose screen was open first must be untouched",
            WidgetAddress.Saved("407"),
            store.readInstance(a)!!.address,
        )
    }

    @Test
    fun `cancelling after a second gear tap leaves both widgets configured`() {
        val (a, b) = twoConfiguredWidgets()
        val controller = launch(a)

        controller.newIntent(intent(b))
        controller.get().findViewById<Button>(R.id.widget_config_cancel).performClick()

        // B exists, so the reused screen is a reconfigure: "no change" is
        // RESULT_OK, and neither widget moves.
        assertEquals(Activity.RESULT_OK, shadowOf(controller.get()).resultCode)
        assertEquals(WidgetAddress.Saved("407"), store.readInstance(a)!!.address)
        assertEquals(WidgetAddress.Saved("100"), store.readInstance(b)!!.address)
    }
}
