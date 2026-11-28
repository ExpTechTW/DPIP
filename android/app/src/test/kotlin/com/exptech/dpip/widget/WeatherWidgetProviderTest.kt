package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.WorkManagerTestInitHelper
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * The provider's lifecycle: restore, delete, and the "update now" tap.
 *
 * The restore path is the one with a failure that leaves no trace — a row copied
 * to the new id without deleting the old one keeps its source "in use" forever,
 * so the Widget keeps fetching for a home-screen instance that no longer exists.
 */
@RunWith(RobolectricTestRunner::class)
class WeatherWidgetProviderTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private lateinit var store: WidgetStore
    private val provider = WeatherWidgetProvider()

    @Before
    fun setUp() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        store = WidgetStore.open(context)
        WorkManagerTestInitHelper.initializeTestWorkManager(
            context,
            WidgetSchedulingOnlyWorkerFactory.configuration(),
        )
        store.writeCatalog(
            listOf(
                WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!,
                WidgetCatalogLocation.create("100", "中正區", "臺北市", 25.032, 121.518)!!,
            ),
            1L,
        )
    }

    @After
    fun tearDown() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
    }

    private fun manager(): AppWidgetManager = AppWidgetManager.getInstance(context)

    private fun states(name: String): List<WorkInfo.State> =
        WorkManager.getInstance(context).getWorkInfosForUniqueWork(name).get().map { it.state }

    private fun pending(name: String): List<WorkInfo> =
        WorkManager.getInstance(context).getWorkInfosForUniqueWork(name).get()
            .filter { it.state == WorkInfo.State.ENQUEUED || it.state == WorkInfo.State.BLOCKED }

    private fun bindLive(vararg ids: Int) {
        for (id in ids) {
            org.robolectric.Shadows.shadowOf(manager()).addBoundWidget(
                id,
                android.appwidget.AppWidgetProviderInfo().apply {
                    provider = android.content.ComponentName(context, WeatherWidgetProvider::class.java)
                },
            )
        }
    }

    @Test
    fun `successful empty reconciliation cancels widget work but not another feature`() {
        val workManager = WorkManager.getInstance(context)
        val other = androidx.work.OneTimeWorkRequestBuilder<WeatherWidgetRefreshWorker>()
            .setInitialDelay(1, java.util.concurrent.TimeUnit.DAYS).build()
        workManager.enqueueUniqueWork("other-feature", androidx.work.ExistingWorkPolicy.KEEP, other)
        WidgetRefresh.schedulePeriodic(context)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update, WidgetAddress.Saved("407"))
        WidgetRefresh.scheduleLocalRerender(context, 60_000)

        WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Restored)

        for (name in listOf(
            WidgetRefresh.periodicWorkName,
            WidgetRefresh.refreshWorkName,
            WidgetRefresh.localRerenderWorkName,
        )) assertTrue("$name must be cancelled", pending(name).isEmpty())
        assertEquals(listOf(WorkInfo.State.ENQUEUED), states("other-feature"))
    }

    @Test
    fun `failed reconcile transaction rolls back choices and retains periodic recovery`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        store.writeInstance(12, address, "407", 1L)
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL(
                "CREATE TRIGGER refuse_delete BEFORE DELETE ON widget_instances WHEN OLD.app_widget_id = 12 " +
                    "BEGIN SELECT RAISE(ABORT, 'temporary delete failure'); END",
            )
            try {
                WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Restored)
                assertEquals(setOf(11, 12), store.readInstances().map { it.appWidgetId }.toSet())
                assertTrue(states(WidgetRefresh.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
                assertTrue("untrusted rows must not be fetched", states(WidgetRefresh.refreshWorkName).isEmpty())
            } finally {
                database.execSQL("DROP TRIGGER refuse_delete")
            }
        }
        WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Restored)
        assertTrue(store.readInstances().isEmpty())
        assertTrue(pending(WidgetRefresh.periodicWorkName).isEmpty())
    }

    @Test
    fun `failed delete authority reads do not cancel work for surviving widgets`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        WidgetRefresh.schedulePeriodic(context)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update, address)
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL("ALTER TABLE widget_instances RENAME TO unavailable_instances")
            try {
                provider.onDeleted(context, intArrayOf(11))
                assertTrue(states(WidgetRefresh.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
                assertTrue(states(WidgetRefresh.refreshWorkName).contains(WorkInfo.State.ENQUEUED))
            } finally {
                database.execSQL("ALTER TABLE unavailable_instances RENAME TO widget_instances")
            }
        }
        assertEquals(address, store.readInstance(11)?.address)
    }

    @Test
    fun `cold reconcile asks once for the survivors and keeps the periodic clock`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(13, WidgetAddress.CurrentLocation, null, 1L)
        store.writeInstance(99, WidgetAddress.Saved("100"), "100", 1L)
        bindLive(11, 12, 13)
        WidgetRefresh.schedulePeriodic(context)
        val workManager = WorkManager.getInstance(context)
        val periodicId = workManager.getWorkInfosForUniqueWork(WidgetRefresh.periodicWorkName).get().single().id
        // Simulate the native store being reopened in a cold process. The
        // periodic request already exists and UPDATE must not restart its clock.
        WidgetStore.resetForTest()
        store = WidgetStore.open(context)

        WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Boot)

        val chain = workManager.getWorkInfosForUniqueWork(WidgetRefresh.refreshWorkName).get()
        assertEquals("one request covers every surviving source", 1, chain.size)
        assertEquals(androidx.work.NetworkType.CONNECTED, chain.single().constraints.requiredNetworkType)
        assertNull(store.readInstance(99))
        assertEquals(listOf(WidgetAddress.Saved("407"), WidgetAddress.CurrentLocation), store.usedAddresses())

        // A second reconcile appends behind the first rather than replacing it.
        WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Boot)
        assertEquals(periodicId, workManager.getWorkInfosForUniqueWork(WidgetRefresh.periodicWorkName).get().single().id)
        val after = workManager.getWorkInfosForUniqueWork(WidgetRefresh.refreshWorkName).get()
        assertEquals(WorkInfo.State.ENQUEUED, after.single { it.id == chain.single().id }.state)
        assertEquals(2, after.size)
    }

    @Test
    fun `reconcile read failure preserves scheduled recovery and durable choices`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        WidgetRefresh.schedulePeriodic(context)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update, address)
        WidgetRefresh.scheduleLocalRerender(context, 60_000)
        val workManager = WorkManager.getInstance(context)
        val periodicId = workManager.getWorkInfosForUniqueWork(WidgetRefresh.periodicWorkName).get().single().id
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL("ALTER TABLE widget_instances RENAME TO unavailable_instances")
            try {
                repeat(3) { WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Restored, keepIds = setOf(11)) }
                assertEquals(
                    periodicId,
                    workManager.getWorkInfosForUniqueWork(WidgetRefresh.periodicWorkName).get().single().id,
                )
                for (name in listOf(
                    WidgetRefresh.periodicWorkName,
                    WidgetRefresh.refreshWorkName,
                    WidgetRefresh.localRerenderWorkName,
                )) assertTrue("$name must survive failed authority reads", states(name).contains(WorkInfo.State.ENQUEUED))
                assertEquals("a failed read asks for nothing", 1, states(WidgetRefresh.refreshWorkName).size)
            } finally {
                database.execSQL("ALTER TABLE unavailable_instances RENAME TO widget_instances")
            }
        }
        assertEquals(address, store.readInstance(11)?.address)
        WidgetRefresh.reconcile(context, WidgetRefresh.Reason.Restored, keepIds = setOf(11))
        assertTrue(states(WidgetRefresh.refreshWorkName).contains(WorkInfo.State.ENQUEUED))
    }

    @Test
    fun `the refresh tap records feedback for its exact queued work and source`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)
        provider.onReceive(context, Intent(WidgetRenderer.ACTION_REFRESH).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 11)
        })
        assertEquals(WidgetRefreshFeedback.Queued, store.readRefreshFeedback(address, System.currentTimeMillis())?.state)
        assertNull(store.readRefreshFeedback(WidgetAddress.Saved("100"), System.currentTimeMillis()))
        val work = WorkManager.getInstance(context)
            .getWorkInfosForUniqueWork(WidgetRefresh.refreshWorkName).get().single()
        assertTrue(store.writeRefreshFeedback(address, work.id.toString(), WidgetRefreshFeedback.Running, System.currentTimeMillis()))
    }

    @Test
    fun `a restore moves each choice and leaves no ghost`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)

        provider.onRestored(context, intArrayOf(11, 12), intArrayOf(21, 22))

        assertNull("the old row must be gone", store.readInstance(11))
        assertNull(store.readInstance(12))
        assertEquals(WidgetAddress.Saved("407"), store.readInstance(21)!!.address)
        assertEquals(WidgetAddress.Saved("100"), store.readInstance(22)!!.address)
        assertEquals(2, store.usedAddresses().size)
    }

    @Test
    fun `a restore that hands back fewer ids drops the rest`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)

        // The launcher restored only the first widget.
        provider.onRestored(context, intArrayOf(11, 12), intArrayOf(21))

        assertEquals(WidgetAddress.Saved("407"), store.readInstance(21)!!.address)
        assertNull(store.readInstance(12))
        // The dropped widget's source is no longer in use.
        assertEquals(listOf(WidgetAddress.Saved("407")), store.usedAddresses())
    }

    @Test
    fun `a restore drops rows the launcher does not report at all`() {
        // An id that is neither live nor handed back: a ghost from a force-stop.
        store.writeInstance(99, WidgetAddress.Saved("100"), "100", 1L)

        provider.onRestored(context, intArrayOf(), intArrayOf())

        assertNull(store.readInstance(99))
    }

    @Test
    fun `deleting the last instance cancels every kind of work`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        WidgetRefresh.schedulePeriodic(context)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update, WidgetAddress.Saved("407"))
        WidgetRefresh.scheduleLocalRerender(context, 60_000)

        provider.onDeleted(context, intArrayOf(11))

        assertNull(store.readInstance(11))
        for (name in listOf(
            WidgetRefresh.periodicWorkName,
            WidgetRefresh.localRerenderWorkName,
            WidgetRefresh.refreshWorkName,
        )) assertTrue("$name should be cancelled: ${states(name)}", pending(name).isEmpty())
    }

    @Test
    fun `deleting one of two instances leaves the other's work running`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)
        WidgetRefresh.schedulePeriodic(context)
        WidgetRefresh.request(context, WidgetRefresh.Reason.Update)

        provider.onDeleted(context, intArrayOf(11))

        assertNotNull(store.readInstance(12))
        assertTrue(states(WidgetRefresh.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
        assertTrue(states(WidgetRefresh.refreshWorkName).contains(WorkInfo.State.ENQUEUED))
    }

    @Test
    fun `an update with no instances schedules nothing`() {
        provider.onUpdate(context, manager(), intArrayOf())

        assertEquals(0, states(WidgetRefresh.periodicWorkName).size)
        assertEquals(0, states(WidgetRefresh.refreshWorkName).size)
    }

    @Test
    fun `an update with an instance renders it and asks for a refresh`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        provider.onUpdate(context, manager(), intArrayOf(11))

        assertTrue(states(WidgetRefresh.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
        assertTrue(states(WidgetRefresh.refreshWorkName).contains(WorkInfo.State.ENQUEUED))
    }

    @Test
    fun `the update-now tap asks only for its own instance's source`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)

        provider.onReceive(
            context,
            Intent(context, WeatherWidgetProvider::class.java).apply {
                action = WidgetRenderer.ACTION_REFRESH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 11)
            },
        )

        assertEquals(listOf(WorkInfo.State.ENQUEUED), states(WidgetRefresh.refreshWorkName))
        assertNotNull(store.readRefreshFeedback(WidgetAddress.Saved("407"), System.currentTimeMillis()))
        assertNull(store.readRefreshFeedback(WidgetAddress.Saved("100"), System.currentTimeMillis()))
    }

    @Test
    fun `the update-now tap for an unknown instance does nothing`() {
        provider.onReceive(
            context,
            Intent(context, WeatherWidgetProvider::class.java).apply {
                action = WidgetRenderer.ACTION_REFRESH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 99)
            },
        )

        assertEquals(0, states(WidgetRefresh.refreshWorkName).size)
    }

    @Test
    fun `enabling schedules the periodic refresh and disabling cancels it`() {
        provider.onEnabled(context)
        assertTrue(states(WidgetRefresh.periodicWorkName).contains(WorkInfo.State.ENQUEUED))

        provider.onDisabled(context)
        assertTrue(pending(WidgetRefresh.periodicWorkName).isEmpty())
    }

    @Test
    fun `a deleted town asks for a reconfigure but an unreadable catalog does not`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        // The catalog read fine and this town is not in it: the user deleted the
        // saved location, and reconfiguring is the only thing that fixes it.
        store.writeCatalog(
            listOf(WidgetCatalogLocation.create("100", "中正區", "臺北市", 25.032, 121.518)!!),
            2L,
        )
        val deleted = WidgetUpdater.presentation(context, 11, 218, 202)
        assertEquals(WidgetDisplayState.Reconfigure, deleted.state)
        assertFalse(deleted.canRefresh)

        // The catalog did not read at all, which says nothing about the town. The
        // old code could not tell the two apart, so a transient SQLite error told
        // the user to reconfigure a widget that was fine — and took away the
        // refresh button that would have recovered it on the next tick.
        store.writeCatalog(
            listOf(WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!),
            3L,
        )
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path,
            null,
            SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL("ALTER TABLE widget_catalog RENAME TO unavailable_catalog")
            try {
                val unreadable = WidgetUpdater.presentation(context, 11, 218, 202)
                assertNotEquals(
                    "a failed catalog read must not demand a reconfigure",
                    WidgetDisplayState.Reconfigure,
                    unreadable.state,
                )
                assertTrue(
                    "and must keep the refresh that recovers it",
                    unreadable.canRefresh,
                )
            } finally {
                database.execSQL("ALTER TABLE unavailable_catalog RENAME TO widget_catalog")
            }
        }
    }
}
