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

    @Test
    fun `successful empty reconciliation cancels widget work but not another feature`() {
        val workManager = WorkManager.getInstance(context)
        val other = androidx.work.OneTimeWorkRequestBuilder<WeatherWidgetRefreshWorker>()
            .setInitialDelay(1, java.util.concurrent.TimeUnit.DAYS).build()
        workManager.enqueueUniqueWork("other-feature", androidx.work.ExistingWorkPolicy.KEEP, other)
        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.scheduleOneTime(context, WidgetAddress.Saved("407"))
        WidgetRefreshScheduler.scheduleLocalRerender(context, 60_000)

        WidgetUpdater.reconcile(context)

        for (name in listOf(
            WidgetRefreshScheduler.periodicWorkName,
            WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")),
            WidgetRefreshScheduler.localRerenderWorkName,
        )) assertTrue("$name must be cancelled", states(name).none { it == WorkInfo.State.ENQUEUED })
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
                WidgetUpdater.reconcile(context)
                assertEquals(setOf(11, 12), store.readInstances().map { it.appWidgetId }.toSet())
                assertTrue(states(WidgetRefreshScheduler.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
                assertTrue(states(WidgetRefreshScheduler.sourceWorkName(address)).isEmpty())
            } finally {
                database.execSQL("DROP TRIGGER refuse_delete")
            }
        }
        WidgetUpdater.reconcile(context)
        assertTrue(store.readInstances().isEmpty())
        assertTrue(states(WidgetRefreshScheduler.periodicWorkName).none { it == WorkInfo.State.ENQUEUED })
    }

    @Test
    fun `failed delete authority reads do not cancel work for surviving widgets`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.scheduleOneTime(context, address)
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL("ALTER TABLE widget_instances RENAME TO unavailable_instances")
            try {
                provider.onDeleted(context, intArrayOf(11))
                assertTrue(states(WidgetRefreshScheduler.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
                assertTrue(states(WidgetRefreshScheduler.sourceWorkName(address)).contains(WorkInfo.State.ENQUEUED))
            } finally {
                database.execSQL("ALTER TABLE unavailable_instances RENAME TO widget_instances")
            }
        }
        assertEquals(address, store.readInstance(11)?.address)
    }

    @Test
    fun `cold reconcile requests each surviving source once without replacing pending recovery`() {
        val saved = WidgetAddress.Saved("407")
        val current = WidgetAddress.CurrentLocation
        val removed = WidgetAddress.Saved("100")
        store.writeInstance(11, saved, "407", 1L)
        store.writeInstance(12, saved, "407", 1L)
        store.writeInstance(13, current, null, 1L)
        store.writeInstance(99, removed, "100", 1L)
        for (id in listOf(11, 12, 13)) {
            org.robolectric.Shadows.shadowOf(manager()).addBoundWidget(
                id,
                android.appwidget.AppWidgetProviderInfo().apply {
                    provider = android.content.ComponentName(context, WeatherWidgetProvider::class.java)
                },
            )
        }
        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.scheduleOneTime(context, removed)
        val workManager = WorkManager.getInstance(context)
        val periodicId = workManager.getWorkInfosForUniqueWork(WidgetRefreshScheduler.periodicWorkName).get().single().id
        // Simulate the native store being reopened in a cold process. The
        // periodic request already exists and UPDATE must not restart its clock.
        WidgetStore.resetForTest()
        store = WidgetStore.open(context)

        WidgetUpdater.reconcile(context)

        val firstIds = listOf(saved, current).map { address ->
            val work = workManager.getWorkInfosForUniqueWork(WidgetRefreshScheduler.sourceWorkName(address)).get()
            assertEquals("one request per surviving source", 1, work.size)
            assertEquals(WorkInfo.State.ENQUEUED, work.single().state)
            assertEquals(androidx.work.NetworkType.CONNECTED, work.single().constraints.requiredNetworkType)
            work.single().id
        }
        assertTrue(states(WidgetRefreshScheduler.sourceWorkName(removed)).none { it == WorkInfo.State.ENQUEUED })
        assertNull(store.readInstance(99))
        WidgetUpdater.reconcile(context)
        assertEquals(periodicId, workManager.getWorkInfosForUniqueWork(WidgetRefreshScheduler.periodicWorkName).get().single().id)
        assertEquals(firstIds, listOf(saved, current).map { address ->
            workManager.getWorkInfosForUniqueWork(WidgetRefreshScheduler.sourceWorkName(address)).get().single().id
        })
        assertTrue(states(WidgetRefreshScheduler.allSourcesWorkName).isEmpty())
    }

    @Test
    fun `reconcile read failure preserves scheduled recovery and durable choices`() {
        val address = WidgetAddress.Saved("407")
        store.writeInstance(11, address, "407", 1L)
        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.scheduleOneTime(context, address)
        WidgetRefreshScheduler.scheduleLocalRerender(context, 60_000)
        val workManager = WorkManager.getInstance(context)
        val periodicId = workManager.getWorkInfosForUniqueWork(WidgetRefreshScheduler.periodicWorkName).get().single().id
        SQLiteDatabase.openDatabase(
            context.getDatabasePath(WidgetStore.DATABASE_NAME).path, null, SQLiteDatabase.OPEN_READWRITE,
        ).use { database ->
            database.execSQL("ALTER TABLE widget_instances RENAME TO unavailable_instances")
            try {
                repeat(3) { WidgetUpdater.reconcile(context, keepIds = setOf(11)) }
                assertEquals(
                    periodicId,
                    workManager.getWorkInfosForUniqueWork(WidgetRefreshScheduler.periodicWorkName).get().single().id,
                )
                for (name in listOf(
                    WidgetRefreshScheduler.periodicWorkName,
                    WidgetRefreshScheduler.sourceWorkName(address),
                    WidgetRefreshScheduler.localRerenderWorkName,
                )) assertTrue("$name must survive failed authority reads", states(name).contains(WorkInfo.State.ENQUEUED))
            } finally {
                database.execSQL("ALTER TABLE unavailable_instances RENAME TO widget_instances")
            }
        }
        assertEquals(address, store.readInstance(11)?.address)
        WidgetUpdater.reconcile(context, keepIds = setOf(11))
        assertTrue(states(WidgetRefreshScheduler.sourceWorkName(address)).contains(WorkInfo.State.ENQUEUED))
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
            .getWorkInfosForUniqueWork(WidgetRefreshScheduler.sourceWorkName(address)).get().single()
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
        WidgetRefreshScheduler.schedulePeriodic(context)
        WidgetRefreshScheduler.scheduleOneTime(context, WidgetAddress.Saved("407"))
        WidgetRefreshScheduler.scheduleLocalRerender(context, 60_000)

        provider.onDeleted(context, intArrayOf(11))

        assertNull(store.readInstance(11))
        assertTrue(
            "the periodic work should be cancelled: ${states(WidgetRefreshScheduler.periodicWorkName)}",
            states(WidgetRefreshScheduler.periodicWorkName).none { it == WorkInfo.State.ENQUEUED },
        )
        assertTrue(
            "the local redraw should be cancelled: " +
                "${states(WidgetRefreshScheduler.localRerenderWorkName)}",
            states(WidgetRefreshScheduler.localRerenderWorkName)
                .none { it == WorkInfo.State.ENQUEUED },
        )
        assertTrue(
            "the one-time work should be cancelled: " +
                "${states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))}",
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
                .none { it == WorkInfo.State.ENQUEUED },
        )
    }

    @Test
    fun `deleting one of two instances leaves the other's work running`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)
        WidgetRefreshScheduler.schedulePeriodic(context)

        provider.onDeleted(context, intArrayOf(11))

        assertNotNull(store.readInstance(12))
        assertTrue(states(WidgetRefreshScheduler.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
    }

    @Test
    fun `deleting the last instance of one source cancels only that source`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)
        store.writeInstance(12, WidgetAddress.Saved("100"), "100", 1L)
        WidgetRefreshScheduler.scheduleOneTime(context, WidgetAddress.Saved("407"))
        WidgetRefreshScheduler.scheduleOneTime(context, WidgetAddress.Saved("100"))

        provider.onDeleted(context, intArrayOf(11))

        assertTrue(
            "the removed source's request must be cancelled: " +
                "${states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))}",
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
                .none { it == WorkInfo.State.ENQUEUED },
        )
        assertTrue(
            "the surviving source must keep its request",
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("100")))
                .contains(WorkInfo.State.ENQUEUED),
        )
    }

    @Test
    fun `an update with no instances schedules nothing`() {
        provider.onUpdate(context, manager(), intArrayOf())

        assertEquals(0, states(WidgetRefreshScheduler.periodicWorkName).size)
    }

    @Test
    fun `an update with an instance renders it and asks for its source`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        provider.onUpdate(context, manager(), intArrayOf(11))

        assertTrue(states(WidgetRefreshScheduler.periodicWorkName).contains(WorkInfo.State.ENQUEUED))
        assertTrue(
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
                .contains(WorkInfo.State.ENQUEUED),
        )
    }

    @Test
    fun `the update-now tap enqueues only its own instance's source`() {
        store.writeInstance(11, WidgetAddress.Saved("407"), "407", 1L)

        provider.onReceive(
            context,
            Intent(context, WeatherWidgetProvider::class.java).apply {
                action = WidgetRenderer.ACTION_REFRESH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 11)
            },
        )

        assertTrue(
            states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("407")))
                .contains(WorkInfo.State.ENQUEUED),
        )
        assertEquals(0, states(WidgetRefreshScheduler.sourceWorkName(WidgetAddress.Saved("100"))).size)
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

        assertEquals(0, states(WidgetRefreshScheduler.allSourcesWorkName).size)
    }

    @Test
    fun `enabling schedules the periodic refresh and disabling cancels it`() {
        provider.onEnabled(context)
        assertTrue(states(WidgetRefreshScheduler.periodicWorkName).contains(WorkInfo.State.ENQUEUED))

        provider.onDisabled(context)
        assertTrue(
            states(WidgetRefreshScheduler.periodicWorkName).none { it == WorkInfo.State.ENQUEUED },
        )
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
