package com.exptech.dpip

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File

/**
 * The device's own movement history, written where the fixes arrive.
 *
 * The counterpart of iOS's `LocationTrackStore.swift`, and deliberately the
 * same file format: one delta-encoded table, anchors every 64 rows, native
 * writes, Dart reads. The two platforms disagree about almost everything in
 * background location — how they wake, how often, what they are allowed to do
 * — so the one thing that should not also differ is what ends up on disk.
 *
 * ## Why its own file
 *
 * Not a table in `dpip.db`. That belongs to Dart's `sqlite_async`, which keeps
 * a WAL connection pool across isolates and migrates its own schema; a second
 * writer here would be a cross-process multi-writer against a schema this file
 * cannot see.
 *
 * ## The encoding
 *
 * Rows hold **deltas**, not absolutes. SQLite stores a small integer in one or
 * two bytes and a large one in four or six, so writing the difference from the
 * previous fix is compression the record format performs for free — no private
 * blob to encode, and nothing for the reader to decode but addition.
 *
 * Every 64th row is an **anchor** holding absolute values, recognised by
 * `rowid % 64 == 0` so no column is spent marking it. Eviction drops whole
 * anchor groups: a delta row is meaningless without the anchor it counts from,
 * and removing one from the middle would displace every position after it with
 * nothing to signal that it had happened.
 */
object LocationTrackStore {
    /** Degrees as ten-thousandths — about 11 m. */
    private const val SCALE = 10_000.0

    /** Rows between absolute anchors. */
    private const val ANCHOR_EVERY = 64L

    private const val BUDGET_BYTES = 50L * 1024 * 1024

    /** Rows between size checks; the file cannot grow meaningfully in fewer. */
    private const val CHECK_EVERY = 512L

    private const val FILE = "location_track.db"

    @Volatile private var db: SQLiteDatabase? = null

    /**
     * Records one fix.
     *
     * Never throws into the caller: this runs inside a JobService or an alarm
     * receiver whose real work is reporting the position, and a storage failure
     * must not take that down with it.
     */
    @Synchronized
    fun record(context: Context, lat: Double, lng: Double, atMillis: Long = System.currentTimeMillis()) {
        val handle = open(context) ?: return
        try {
            val t = atMillis / 1000
            val latE4 = Math.round(lat * SCALE)
            val lngE4 = Math.round(lng * SCALE)

            var rowid = lastRowId(handle) + 1
            val previous = if (rowid % ANCHOR_EVERY == 0L) null else lastAbsolute(handle)

            // A row that cannot be a delta has to be an anchor, and an anchor is
            // recognised by its rowid alone — so move the row to the next
            // boundary rather than write an absolute where a reader expects a
            // delta. Happens on the first fix, and on the first after eviction
            // removed the tail.
            if (previous == null && rowid % ANCHOR_EVERY != 0L) {
                rowid += ANCHOR_EVERY - rowid % ANCHOR_EVERY
            }

            handle.execSQL(
                "INSERT INTO fix (id, t, lat, lng) VALUES (?, ?, ?, ?)",
                arrayOf<Any>(
                    rowid,
                    previous?.let { t - it.t } ?: t,
                    previous?.let { latE4 - it.lat } ?: latE4,
                    previous?.let { lngE4 - it.lng } ?: lngE4,
                ),
            )
            evictIfNeeded(handle, rowid)
        } catch (_: Throwable) {
            // Deliberately swallowed, and deliberately not logged: this path can
            // run hundreds of times a day in the background, and a log line per
            // failure would be the only trace of a disk that is simply full.
            // The size is visible through the app's storage screen instead.
        }
    }

    /**
     * Deletes every recorded fix and hands the pages back to the filesystem.
     *
     * Through the open handle, never by deleting the file: this object caches
     * the handle, and one whose file was removed underneath it goes on writing
     * into an unlinked inode — the rows reappear on the next read, the space is
     * never returned, and nothing reports a problem.
     */
    @Synchronized
    fun clear(context: Context): Boolean {
        val handle = open(context) ?: return false
        return try {
            handle.execSQL("DELETE FROM fix")
            // Only returns bytes because `auto_vacuum=INCREMENTAL` was set
            // before the table existed — see [open].
            handle.execSQL("PRAGMA incremental_vacuum")
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun open(context: Context): SQLiteDatabase? {
        db?.let { if (it.isOpen) return it }
        return try {
            // filesDir, not noBackupFilesDir: the manifest already sets
            // android:allowBackup="false", and this is the directory Dart's
            // getApplicationSupportDirectory() resolves to — the reader should
            // not have to guess where the writer put it.
            val file = File(context.filesDir, FILE)
            val handle = SQLiteDatabase.openOrCreateDatabase(file, null)
            // Before the table exists: set afterwards it is a no-op until a full
            // VACUUM, and without it deleted rows free pages inside the file and
            // never give the bytes back to the budget.
            handle.execSQL("PRAGMA auto_vacuum=INCREMENTAL")
            handle.execSQL("PRAGMA journal_mode=WAL")
            // A fix lost to a power cut is one point on a track; a blocked fsync
            // inside a background wake can cost the report as well.
            handle.execSQL("PRAGMA synchronous=NORMAL")
            handle.execSQL(
                """
                CREATE TABLE IF NOT EXISTS fix (
                  id  INTEGER PRIMARY KEY,
                  t   INTEGER NOT NULL,
                  lat INTEGER NOT NULL,
                  lng INTEGER NOT NULL
                )
                """.trimIndent(),
            )
            db = handle
            handle
        } catch (_: Throwable) {
            null
        }
    }

    private data class Fix(val t: Long, val lat: Long, val lng: Long)

    private fun scalar(handle: SQLiteDatabase, sql: String): Long =
        handle.rawQuery(sql, null).use { if (it.moveToFirst()) it.getLong(0) else 0L }

    private fun lastRowId(handle: SQLiteDatabase): Long =
        scalar(handle, "SELECT IFNULL(MAX(id), 0) FROM fix")

    /**
     * The absolute position of the last row, rebuilt from its anchor forward.
     *
     * Bounded by [ANCHOR_EVERY], so at most 64 rows of addition — cheaper than a
     * cached copy that a crash or a second process could leave stale.
     */
    private fun lastAbsolute(handle: SQLiteDatabase): Fix? {
        val last = lastRowId(handle)
        if (last == 0L) return null
        val anchor = last - last % ANCHOR_EVERY
        var current: Fix? = null
        handle.rawQuery(
            "SELECT id, t, lat, lng FROM fix WHERE id >= ? ORDER BY id",
            arrayOf(anchor.toString()),
        ).use { cursor ->
            while (cursor.moveToNext()) {
                val id = cursor.getLong(0)
                val t = cursor.getLong(1)
                val lat = cursor.getLong(2)
                val lng = cursor.getLong(3)
                current = if (id % ANCHOR_EVERY == 0L || current == null) {
                    Fix(t, lat, lng)
                } else {
                    current!!.let { Fix(it.t + t, it.lat + lat, it.lng + lng) }
                }
            }
        }
        return current
    }

    /** Drops the oldest anchor groups until the file is back inside its budget. */
    private fun evictIfNeeded(handle: SQLiteDatabase, rowid: Long) {
        if (rowid % CHECK_EVERY != 0L) return
        val pageSize = scalar(handle, "PRAGMA page_size")
        var bytes = pageSize * scalar(handle, "PRAGMA page_count")
        if (bytes <= BUDGET_BYTES) return

        // Free about a tenth at a time. Trimming to exactly the limit would put
        // the next fix straight back over it, and the vacuum is the expensive
        // part of this path.
        val target = BUDGET_BYTES - BUDGET_BYTES / 10
        var oldest = scalar(handle, "SELECT IFNULL(MIN(id), 0) FROM fix")
        while (bytes > target && oldest > 0) {
            val boundary = oldest + ANCHOR_EVERY - oldest % ANCHOR_EVERY
            handle.execSQL("DELETE FROM fix WHERE id < $boundary")
            handle.execSQL("PRAGMA incremental_vacuum")
            bytes = pageSize * scalar(handle, "PRAGMA page_count")
            val next = scalar(handle, "SELECT IFNULL(MIN(id), 0) FROM fix")
            if (next <= oldest) break
            oldest = next
        }
    }
}
