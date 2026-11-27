package com.exptech.dpip.widget

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import androidx.core.database.sqlite.transaction

/**
 * What became of a commit.
 *
 * `Superseded` and `Failed` are separate on purpose. A superseded write lost an
 * ordering race — a newer observation or a later acquisition landed first, or
 * its town left the catalog — and is normal, not an error the app can act on. A
 * failure means the write never happened, and the Flutter side must hear about
 * it: a broken database must not look like a healthy one that lost a race.
 */
enum class WidgetWriteResult { Written, Superseded, Failed }

/** An authority read must not turn an unavailable database into an empty store. */
sealed interface WidgetInstanceReadResult {
    data class Read(val instances: List<WidgetInstance>, val dropped: List<WidgetAddress> = emptyList()) : WidgetInstanceReadResult
    data object Failed : WidgetInstanceReadResult
}

/**
 * The outcome of looking one region code up in the published catalog.
 *
 * `Absent` and `Failed` are kept apart because only one of them is a statement
 * about the user's saved locations; see [WidgetStore.lookupCatalogLocation].
 */
sealed interface WidgetCatalogLookup {
    data class Found(val location: WidgetCatalogLocation) : WidgetCatalogLookup
    data object Absent : WidgetCatalogLookup
    data object Failed : WidgetCatalogLookup
}

/** One desktop Widget instance's persisted choice of location. */
data class WidgetInstance(
    val appWidgetId: Int,
    val address: WidgetAddress,
    val regionCode: String?,
    val updatedAt: Long,
)

/** The published location catalog, with the instant it was published. */
data class CatalogSnapshot(val locations: List<WidgetCatalogLocation>, val writtenAt: Long)

/** A stored current-weather snapshot together with the acquisitions that wrote it. */
data class StoredCurrentWeather(
    val snapshot: CurrentWeatherSnapshot,
    val writeGeneration: Long,
    val locationGeneration: Long,
)

/**
 * The Widget's own SQLite database.
 *
 * A native-owned store, not a window onto Flutter's `dpip.db`; only this class
 * opens it, and Flutter reaches it only by value through the channel.
 *
 * * `widget_instances` — per-`appWidgetId` choice. **Durable**: a Widget keeps
 *   its town until its user changes it.
 * * `widget_catalog` / `widget_meta` — the saved locations Dart published.
 *   **Durable.**
 * * `widget_snapshots`, `widget_forecasts` + `widget_forecast_points` — the
 *   cache. Re-fetchable.
 * * `widget_source_state` — per address: the position degradation, the
 *   acquisition counter, the last successful refresh and the manual-refresh
 *   feedback. Re-derivable.
 *
 * ## Ordering
 *
 * Every refresh runs in one WorkManager chain (see [WidgetRefresh]), so two
 * background refreshes never race each other. What can still race is the app:
 * it publishes the snapshot it just loaded while a background refresh is in
 * flight. A snapshot therefore carries an **acquisition** number from the
 * per-address counter, taken *before* the work that can be overtaken (the
 * location fix, the fetch), and [SnapshotOrdering] decides with it: a newer
 * observation wins within a township, and a later acquisition wins across
 * townships, so a fix taken before the device moved cannot overwrite the
 * township the app has since published.
 */
class WidgetStore private constructor(
    context: Context,
    databaseName: String = DATABASE_NAME,
) {
    /**
     * The application context only: the store is a process singleton and has
     * no business reaching an Activity.
     */
    private val context: Context = context.applicationContext

    private val helper = Helper(this.context, databaseName)

    // ── Location catalog ────────────────────────────────────────────────────

    /**
     * Replaces the catalog in one transaction.
     *
     * A town that left it cannot take a late write afterwards: every commit
     * re-checks catalog membership inside its own transaction.
     */
    @Synchronized
    fun writeCatalog(locations: List<WidgetCatalogLocation>, writtenAt: Long): Boolean {
        return attempt("catalog.write", null) {
            inTransaction { database ->
                database.delete(TABLE_CATALOG, null, null)
                for (location in locations) {
                    database.insertOrThrow(TABLE_CATALOG, null, contentValuesOf(
                        "region_code" to location.regionCode,
                        "display_name" to location.displayName,
                        "administrative_area" to location.administrativeAreaName,
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                    ))
                }
                database.insertWithOnConflict(
                    TABLE_META,
                    null,
                    contentValuesOf(
                        "id" to META_CATALOG,
                        "schema_version" to WidgetSnapshotDecoder.locationCatalogSchemaVersion,
                        "written_at" to writtenAt,
                    ),
                    SQLiteDatabase.CONFLICT_REPLACE,
                )
                true
            }
        } ?: false
    }

    @Synchronized
    fun readCatalog(): CatalogSnapshot? {
        return quietly("catalog.read") {
            val database = helper.readableDatabase
            val writtenAt = database.rawQuery(
                "SELECT written_at FROM $TABLE_META WHERE id = ?",
                arrayOf(META_CATALOG.toString()),
            ).use { cursor -> if (cursor.moveToFirst()) cursor.getLong(0) else -1L }
            if (writtenAt < 0) return@quietly null

            val locations = ArrayList<WidgetCatalogLocation>()
            database.rawQuery(
                "SELECT region_code, display_name, administrative_area, latitude, longitude" +
                    " FROM $TABLE_CATALOG ORDER BY rowid",
                null,
            ).use { cursor ->
                while (cursor.moveToNext()) {
                    locations.add(readCatalogRow(cursor) ?: return@quietly null)
                }
            }
            CatalogSnapshot(locations, writtenAt)
        }
    }

    fun findCatalogLocation(regionCode: String): WidgetCatalogLocation? =
        (lookupCatalogLocation(regionCode) as? WidgetCatalogLookup.Found)?.location

    /**
     * A catalog row, its absence, or the fact that the read did not happen.
     *
     * "No such row" means the user deleted that saved location and the Widget
     * must say *reconfigure*; a failed read means nothing about the row, and
     * answering *reconfigure* there would take away the refresh button that
     * recovers it.
     */
    @Synchronized
    fun lookupCatalogLocation(regionCode: String): WidgetCatalogLookup =
        quietly("catalog.find") {
            helper.readableDatabase.rawQuery(
                "SELECT region_code, display_name, administrative_area, latitude, longitude" +
                    " FROM $TABLE_CATALOG WHERE region_code = ?",
                arrayOf(regionCode),
            ).use { cursor ->
                if (!cursor.moveToFirst()) return@quietly WidgetCatalogLookup.Absent
                // A row `create` rejects is one no renderer can use, and
                // reconfiguring is what replaces it.
                readCatalogRow(cursor)?.let { WidgetCatalogLookup.Found(it) } ?: WidgetCatalogLookup.Absent
            }
        } ?: WidgetCatalogLookup.Failed

    // ── Manual refresh feedback ─────────────────────────────────────────────

    /**
     * Feedback survives process death. The request id makes it belong to one
     * tap: an older run can never overwrite the feedback of a newer one, and a
     * short expiry keeps an orphaned "updating" from staying on screen.
     */
    @Synchronized
    internal fun beginRefreshFeedback(address: WidgetAddress, requestId: String, now: Long): Boolean =
        attempt("feedback.begin", address.sourceIdentifier) {
            inTransaction { database ->
                ensureSourceState(database, address.sourceIdentifier, now)
                database.update(
                    TABLE_SOURCE_STATE,
                    feedbackValues(requestId, WidgetRefreshFeedback.Queued, now),
                    "source_identifier = ?",
                    arrayOf(address.sourceIdentifier),
                ) > 0
            }
        } ?: false

    @Synchronized
    internal fun writeRefreshFeedback(
        address: WidgetAddress,
        requestId: String,
        state: WidgetRefreshFeedback,
        now: Long,
    ): Boolean = attempt("feedback.write", address.sourceIdentifier) {
        helper.writableDatabase.update(
            TABLE_SOURCE_STATE,
            feedbackValues(requestId, state, now),
            "source_identifier = ? AND feedback_request = ?",
            arrayOf(address.sourceIdentifier, requestId),
        ) > 0
    } ?: false

    @Synchronized
    internal fun readRefreshFeedback(address: WidgetAddress, now: Long): StoredWidgetRefreshFeedback? =
        quietly("feedback.read") {
            helper.readableDatabase.rawQuery(
                "SELECT feedback_state, feedback_updated_at, feedback_expires_at" +
                    " FROM $TABLE_SOURCE_STATE WHERE source_identifier = ? AND feedback_state IS NOT NULL",
                arrayOf(address.sourceIdentifier),
            ).use { cursor ->
                if (!cursor.moveToFirst()) return@quietly null
                // A device clock change must not keep feedback alive indefinitely.
                if (now < cursor.getLong(1) || now >= cursor.getLong(2)) return@quietly null
                val state = WidgetRefreshFeedback.entries.firstOrNull { it.wire == cursor.getString(0) }
                    ?: return@quietly null
                StoredWidgetRefreshFeedback(state, cursor.getLong(2))
            }
        }

    // ── Instances ───────────────────────────────────────────────────────────

    @Synchronized
    fun writeInstance(
        appWidgetId: Int,
        address: WidgetAddress,
        regionCode: String?,
        updatedAt: Long,
    ): Boolean {
        return attempt("instance.write", address.sourceIdentifier) {
            helper.writableDatabase.insertWithOnConflict(
                TABLE_INSTANCES,
                null,
                instanceValues(appWidgetId, address, regionCode, updatedAt),
                SQLiteDatabase.CONFLICT_REPLACE,
            ) != -1L
        } ?: false
    }

    @Synchronized
    fun deleteInstance(appWidgetId: Int): Boolean {
        return attempt("instance.delete", null) {
            helper.writableDatabase.delete(TABLE_INSTANCES, "app_widget_id = ?", arrayOf(appWidgetId.toString()))
            true
        } ?: false
    }

    /**
     * Moves a restored instance's choice from its old id to its new one.
     *
     * A launcher restore hands back fresh ids and the framework pairs them by
     * position. Copying without deleting would leave the old row behind as a
     * ghost that keeps its source fetching for an instance that no longer
     * exists.
     */
    @Synchronized
    fun remapInstance(oldAppWidgetId: Int, newAppWidgetId: Int): Boolean {
        if (oldAppWidgetId == newAppWidgetId) return true
        return attempt("instance.remap", null) {
            inTransaction { database ->
                val previous = readInstance(database, oldAppWidgetId) ?: return@inTransaction false
                database.delete(TABLE_INSTANCES, "app_widget_id = ?", arrayOf(oldAppWidgetId.toString()))
                database.insertWithOnConflict(
                    TABLE_INSTANCES,
                    null,
                    instanceValues(newAppWidgetId, previous.address, previous.regionCode, System.currentTimeMillis()),
                    SQLiteDatabase.CONFLICT_REPLACE,
                )
                true
            }
        } ?: false
    }

    /**
     * Drops rows for instances the launcher no longer has.
     *
     * Reconciling against `AppWidgetManager`'s live ids is what keeps a
     * force-stopped or mis-restored state from leaving a row that keeps a source
     * fetching forever. Returns the surviving rows from the same transaction; a
     * failed read or delete is not authority to cancel work.
     */
    @Synchronized
    fun reconcileInstances(liveAppWidgetIds: Set<Int>): WidgetInstanceReadResult {
        return attempt("instance.reconcile", null) {
            inTransaction { database ->
                val instances = readInstances(database)
                val (live, gone) = instances.partition { it.appWidgetId in liveAppWidgetIds }
                for (instance in gone) {
                    database.delete(TABLE_INSTANCES, "app_widget_id = ?", arrayOf(instance.appWidgetId.toString()))
                }
                WidgetInstanceReadResult.Read(live, gone.map { it.address })
            }
        } ?: WidgetInstanceReadResult.Failed
    }

    @Synchronized
    fun readInstance(appWidgetId: Int): WidgetInstance? = quietly("instance.read") {
        readInstance(helper.readableDatabase, appWidgetId)
    }

    @Synchronized
    fun readInstancesResult(): WidgetInstanceReadResult = quietly("instance.list") {
        WidgetInstanceReadResult.Read(readInstances(helper.readableDatabase))
    } ?: WidgetInstanceReadResult.Failed

    /** Cache-only callers can render no data; cancellation callers use the typed read. */
    @Synchronized
    fun readInstances(): List<WidgetInstance> =
        (readInstancesResult() as? WidgetInstanceReadResult.Read)?.instances ?: emptyList()

    /** Every address some instance still needs, de-duplicated in id order. */
    @Synchronized
    fun usedAddresses(): List<WidgetAddress> =
        readInstances().map { it.address }.distinctBy { it.sourceIdentifier }

    /** True while any instance is addressed at [address]. */
    @Synchronized
    fun hasInstanceFor(address: WidgetAddress): Boolean = quietly("instance.has") {
        helper.readableDatabase.rawQuery(
            "SELECT 1 FROM $TABLE_INSTANCES WHERE source_identifier = ? LIMIT 1",
            arrayOf(address.sourceIdentifier),
        ).use { it.moveToFirst() }
    } ?: false

    // ── Current weather ─────────────────────────────────────────────────────

    /**
     * Takes the next acquisition number for [address].
     *
     * A refresh takes it before its location fix and fetch, which is what lets
     * a snapshot the app published in the meantime outrank it across a township
     * change; see the class comment.
     */
    @Synchronized
    fun beginAcquisition(address: WidgetAddress): Long? =
        attempt("acquisition.begin", address.sourceIdentifier) {
            inTransaction { database -> nextAcquisition(database, address.sourceIdentifier) }
        }

    /**
     * Commits a snapshot, and optionally the address's location degradation, in
     * one transaction.
     *
     * [acquisition] is the number the refresh took before its fix; the app's
     * own publish takes the next one at commit time. `locationStateAfterCommit`
     * is how a degradation is *cleared*: only a commit that actually landed may
     * declare the position trustworthy again.
     */
    @Synchronized
    fun commitCurrentWeather(
        snapshot: CurrentWeatherSnapshot,
        writtenAt: Long,
        acquisition: Long? = null,
        locationStateAfterCommit: LocationStateWrite = LocationStateWrite.Keep,
    ): WidgetWriteResult {
        val source = snapshot.sourceIdentifier
        return commit("currentWeather", source) { database ->
            val address = snapshot.address ?: return@commit WidgetWriteResult.Superseded
            // A town that left the catalog must not accept a late observation.
            // The instance keeps its choice; the layout asks for a reconfigure.
            if (!inCatalog(database, address)) return@commit WidgetWriteResult.Superseded

            val generation = acquisition ?: nextAcquisition(database, source)
            val existing = readOrdering(database, source)
            val candidate = SnapshotOrderingMetadata(
                snapshotGeneration = generation,
                locationGeneration = generation,
                valueTime = snapshot.observationTime,
                regionCode = snapshot.regionCode,
            )
            if (!SnapshotOrdering.shouldReplace(address, existing, candidate)) {
                // A newer same-township acquisition still advances the Current
                // Location fence even when its older observation cannot replace
                // the canonical snapshot. Mirrors iOS's
                // `CurrentWeatherSnapshotStorage.replace`.
                if (existing != null && address is WidgetAddress.CurrentLocation &&
                    candidate.regionCode == existing.regionCode &&
                    generation > existing.locationGeneration
                ) {
                    database.execSQL(
                        "UPDATE $TABLE_SNAPSHOTS SET location_generation = ? WHERE source_identifier = ?",
                        arrayOf<Any>(generation, source),
                    )
                }
                return@commit WidgetWriteResult.Superseded
            }

            database.insertWithOnConflict(
                TABLE_SNAPSHOTS,
                null,
                snapshotValues(
                    snapshot,
                    generation,
                    SnapshotOrdering.locationGeneration(address, existing, candidate),
                    writtenAt,
                ),
                SQLiteDatabase.CONFLICT_REPLACE,
            )
            val state = locationStateAfterCommit
            if (state is LocationStateWrite.Set) {
                applyLocationState(database, source, state.degradation, writtenAt)
            }
            WidgetWriteResult.Written
        }
    }

    @Synchronized
    fun readCurrentWeather(address: WidgetAddress): StoredCurrentWeather? =
        quietly("currentWeather.read") {
            helper.readableDatabase.rawQuery(
                "SELECT schema_version, region_code, region_name, observation_time, station_name," +
                    " weather, weather_code, condition, is_night, next_transition," +
                    " calibrated_offset, temperature, humidity, rain, wind_direction," +
                    " wind_speed, apparent_temperature, write_generation, location_generation" +
                    " FROM $TABLE_SNAPSHOTS WHERE source_identifier = ?",
                arrayOf(address.sourceIdentifier),
            ).use { cursor ->
                if (!cursor.moveToFirst()) return@quietly null
                StoredCurrentWeather(
                    snapshot = CurrentWeatherSnapshot(
                        schemaVersion = cursor.getInt(0),
                        sourceIdentifier = address.sourceIdentifier,
                        regionCode = cursor.getString(1),
                        regionName = cursor.getString(2),
                        observationTime = cursor.getLong(3),
                        stationName = cursor.getString(4),
                        weather = cursor.getString(5),
                        weatherCode = cursor.getInt(6),
                        condition = WeatherCondition.fromWire(cursor.getString(7)) ?: WeatherCondition.Unknown,
                        isNight = cursor.getInt(8) != 0,
                        nextDayNightTransitionTime = cursor.getLong(9),
                        calibratedTimeOffsetMilliseconds = cursor.getLong(10),
                        temperature = cursor.getNullableDouble(11),
                        humidity = cursor.getNullableInt(12),
                        rain = cursor.getNullableDouble(13),
                        windDirection = cursor.getNullableString(14),
                        windSpeed = cursor.getNullableDouble(15),
                        apparentTemperature = cursor.getNullableDouble(16),
                    ),
                    writeGeneration = cursor.getLong(17),
                    locationGeneration = cursor.getLong(18),
                )
            }
        }

    // ── Forecast ────────────────────────────────────────────────────────────

    /**
     * Commits a forecast together with the instants that make it expirable.
     *
     * `receivedCalibrated` and `expiresAt` are passed in rather than derived here
     * because the caller is the one holding the clock anchor at the moment the
     * response arrived — see [StoredForecast] for why they must be fixed then.
     * A forecast for one township is never filed against another: a late
     * response from a township Current Location has left is refused here.
     */
    @Synchronized
    fun commitForecast(
        forecast: ForecastSnapshot,
        receivedCalibratedMilliseconds: Long,
        expiresAtMilliseconds: Long,
        writtenAt: Long,
    ): WidgetWriteResult {
        val source = forecast.sourceIdentifier
        return commit("forecast", source) { database ->
            val address = forecast.address ?: return@commit WidgetWriteResult.Superseded
            if (!inCatalog(database, address)) return@commit WidgetWriteResult.Superseded
            val current = database.rawQuery(
                "SELECT region_code FROM $TABLE_SNAPSHOTS WHERE source_identifier = ?",
                arrayOf(source),
            ).use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
            if (current != null && current != forecast.regionCode) {
                return@commit WidgetWriteResult.Superseded
            }

            database.insertWithOnConflict(
                TABLE_FORECASTS,
                null,
                contentValuesOf(
                    "source_identifier" to source,
                    "schema_version" to forecast.schemaVersion,
                    "region_code" to forecast.regionCode,
                    "update_time" to forecast.updateTime,
                    "received_at" to forecast.receivedAt,
                    "received_calibrated" to receivedCalibratedMilliseconds,
                    "expires_at" to expiresAtMilliseconds,
                    "written_at" to writtenAt,
                ),
                SQLiteDatabase.CONFLICT_REPLACE,
            )
            database.delete(TABLE_FORECAST_POINTS, "source_identifier = ?", arrayOf(source))
            forecast.points.forEachIndexed { index, point ->
                database.insertOrThrow(TABLE_FORECAST_POINTS, null, contentValuesOf(
                    "source_identifier" to source,
                    "position" to index,
                    "time_label" to point.time,
                    "temperature" to point.temperature,
                    "weather" to point.weather,
                    "weather_code" to point.weatherCode,
                    "pop" to point.pop,
                ))
            }
            WidgetWriteResult.Written
        }
    }

    @Synchronized
    fun readForecast(address: WidgetAddress): StoredForecast? = quietly("forecast.read") {
        val database = helper.readableDatabase
        val header = database.rawQuery(
            "SELECT schema_version, region_code, update_time, received_at," +
                " received_calibrated, expires_at" +
                " FROM $TABLE_FORECASTS WHERE source_identifier = ?",
            arrayOf(address.sourceIdentifier),
        ).use { cursor ->
            if (!cursor.moveToFirst()) return@quietly null
            if (cursor.getInt(0) != WidgetSnapshotDecoder.forecastSchemaVersion) return@quietly null
            ForecastHeader(
                regionCode = cursor.getString(1),
                updateTime = cursor.getLong(2),
                receivedAt = cursor.getLong(3),
                receivedCalibrated = cursor.getLong(4),
                expiresAt = cursor.getLong(5),
            )
        }

        val points = ArrayList<ForecastPoint>()
        database.rawQuery(
            "SELECT time_label, temperature, weather, weather_code, pop" +
                " FROM $TABLE_FORECAST_POINTS WHERE source_identifier = ? ORDER BY position",
            arrayOf(address.sourceIdentifier),
        ).use { cursor ->
            while (cursor.moveToNext()) {
                points.add(
                    ForecastPoint(
                        time = cursor.getString(0),
                        temperature = cursor.getDouble(1),
                        weather = cursor.getString(2),
                        weatherCode = cursor.getInt(3),
                        pop = cursor.getNullableInt(4),
                    ),
                )
            }
        }
        if (points.isEmpty()) return@quietly null

        StoredForecast(
            forecast = ForecastSnapshot(
                schemaVersion = WidgetSnapshotDecoder.forecastSchemaVersion,
                sourceIdentifier = address.sourceIdentifier,
                regionCode = header.regionCode,
                updateTime = header.updateTime,
                receivedAt = header.receivedAt,
                points = points,
            ),
            receivedCalibratedMilliseconds = header.receivedCalibrated,
            expiresAtMilliseconds = header.expiresAt,
        )
    }

    // ── Per-address live state ──────────────────────────────────────────────

    /**
     * Records why the position for [address] cannot be trusted, or clears it.
     *
     * Only the refresh chain writes it, one run at a time, so the newest run's
     * answer is simply the last one written.
     */
    @Synchronized
    fun writeLocationState(
        address: WidgetAddress,
        degradation: WidgetLocationDegradation?,
        updatedAt: Long,
    ): Boolean {
        return attempt("locationState.write", address.sourceIdentifier) {
            inTransaction { database ->
                applyLocationState(database, address.sourceIdentifier, degradation, updatedAt)
                true
            }
        } ?: false
    }

    /** The recorded degradation, or null when the position is (or may be) fine. */
    @Synchronized
    fun readLocationState(address: WidgetAddress): WidgetLocationDegradation? =
        quietly("locationState.read") {
            helper.readableDatabase.rawQuery(
                "SELECT degradation FROM $TABLE_SOURCE_STATE WHERE source_identifier = ?",
                arrayOf(address.sourceIdentifier),
            ).use { cursor ->
                if (cursor.moveToFirst()) WidgetLocationDegradation.fromWire(cursor.getNullableString(0)) else null
            }
        }

    /**
     * Records the device time of a refresh that brought data in.
     *
     * Only for de-duplicating a burst of requests (`WeatherWidgetRefreshWorker`);
     * it never decides what the screen calls fresh.
     */
    @Synchronized
    fun markRefreshed(address: WidgetAddress, at: Long): Boolean =
        attempt("refreshed.write", address.sourceIdentifier) {
            inTransaction { database ->
                ensureSourceState(database, address.sourceIdentifier, at)
                database.update(
                    TABLE_SOURCE_STATE,
                    contentValuesOf("refreshed_at" to at, "updated_at" to at),
                    "source_identifier = ?",
                    arrayOf(address.sourceIdentifier),
                ) > 0
            }
        } ?: false

    @Synchronized
    fun readRefreshedAt(address: WidgetAddress): Long? = quietly("refreshed.read") {
        helper.readableDatabase.rawQuery(
            "SELECT refreshed_at FROM $TABLE_SOURCE_STATE WHERE source_identifier = ?",
            arrayOf(address.sourceIdentifier),
        ).use { cursor -> if (cursor.moveToFirst()) cursor.getNullableLong(0) else null }
    }

    // ── Shared machinery ────────────────────────────────────────────────────

    private class ForecastHeader(
        val regionCode: String,
        val updateTime: Long,
        val receivedAt: Long,
        val receivedCalibrated: Long,
        val expiresAt: Long,
    )

    /**
     * Runs one commit transaction and reports a failure rather than swallowing
     * it: an exception from SQLite must reach the channel as `write_failed`,
     * not as a lost race.
     */
    private fun commit(
        operation: String,
        source: String,
        body: (SQLiteDatabase) -> WidgetWriteResult,
    ): WidgetWriteResult {
        return try {
            inTransaction(body)
        } catch (error: Exception) {
            WidgetLog.error(
                context,
                "write failed operation=$operation source=$source error=${error.logName()}",
            )
            WidgetWriteResult.Failed
        }
    }

    private fun inCatalog(database: SQLiteDatabase, address: WidgetAddress): Boolean {
        if (address !is WidgetAddress.Saved) return true
        return database.rawQuery(
            "SELECT 1 FROM $TABLE_CATALOG WHERE region_code = ? LIMIT 1",
            arrayOf(address.regionCode),
        ).use { it.moveToFirst() }
    }

    private fun readOrdering(database: SQLiteDatabase, source: String): SnapshotOrderingMetadata? =
        database.rawQuery(
            "SELECT write_generation, location_generation, observation_time, region_code" +
                " FROM $TABLE_SNAPSHOTS WHERE source_identifier = ?",
            arrayOf(source),
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            SnapshotOrderingMetadata(
                snapshotGeneration = cursor.getLong(0),
                locationGeneration = cursor.getLong(1),
                valueTime = cursor.getLong(2),
                regionCode = cursor.getString(3),
            )
        }

    /** The source-state row every per-address column hangs off. */
    private fun ensureSourceState(database: SQLiteDatabase, source: String, now: Long) {
        database.insertWithOnConflict(
            TABLE_SOURCE_STATE,
            null,
            contentValuesOf("source_identifier" to source, "acquisition" to 0L, "updated_at" to now),
            SQLiteDatabase.CONFLICT_IGNORE,
        )
    }

    private fun nextAcquisition(database: SQLiteDatabase, source: String): Long {
        ensureSourceState(database, source, 0L)
        database.execSQL(
            "UPDATE $TABLE_SOURCE_STATE SET acquisition = acquisition + 1 WHERE source_identifier = ?",
            arrayOf(source),
        )
        return database.rawQuery(
            "SELECT acquisition FROM $TABLE_SOURCE_STATE WHERE source_identifier = ?",
            arrayOf(source),
        ).use { cursor -> cursor.moveToFirst(); cursor.getLong(0) }
    }

    private fun applyLocationState(
        database: SQLiteDatabase,
        source: String,
        degradation: WidgetLocationDegradation?,
        updatedAt: Long,
    ) {
        ensureSourceState(database, source, updatedAt)
        database.update(
            TABLE_SOURCE_STATE,
            contentValuesOf("degradation" to degradation?.wire, "updated_at" to updatedAt),
            "source_identifier = ?",
            arrayOf(source),
        )
    }

    private fun feedbackValues(requestId: String, state: WidgetRefreshFeedback, now: Long) = contentValuesOf(
        "feedback_request" to requestId,
        "feedback_state" to state.wire,
        "feedback_updated_at" to now,
        "feedback_expires_at" to now + state.durationMilliseconds,
    )

    private fun readInstance(database: SQLiteDatabase, appWidgetId: Int): WidgetInstance? {
        return database.rawQuery(
            "SELECT app_widget_id, source_identifier, region_code, updated_at" +
                " FROM $TABLE_INSTANCES WHERE app_widget_id = ?",
            arrayOf(appWidgetId.toString()),
        ).use { cursor -> if (cursor.moveToFirst()) readInstanceRow(cursor) else null }
    }

    private fun readInstances(database: SQLiteDatabase): List<WidgetInstance> {
        val instances = ArrayList<WidgetInstance>()
        database.rawQuery(
            "SELECT app_widget_id, source_identifier, region_code, updated_at" +
                " FROM $TABLE_INSTANCES ORDER BY app_widget_id",
            null,
        ).use { cursor ->
            while (cursor.moveToNext()) {
                readInstanceRow(cursor)?.let { instances.add(it) }
            }
        }
        return instances
    }

    private fun readInstanceRow(cursor: Cursor): WidgetInstance? {
        val address = WidgetAddress.fromSourceIdentifier(cursor.getString(1)) ?: return null
        return WidgetInstance(cursor.getInt(0), address, cursor.getNullableString(2), cursor.getLong(3))
    }

    private fun readCatalogRow(cursor: Cursor): WidgetCatalogLocation? = WidgetCatalogLocation.create(
        regionCode = cursor.getString(0),
        displayName = cursor.getString(1),
        administrativeAreaName = cursor.getString(2),
        latitude = cursor.getDouble(3),
        longitude = cursor.getDouble(4),
    )

    /**
     * One transaction, via the `androidx.core` extension: begin, mark
     * successful, end in a `finally`, so an exception rolls back.
     */
    private fun <T> inTransaction(body: (SQLiteDatabase) -> T): T =
        helper.writableDatabase.transaction { body(this) }

    /** Runs a read, reporting why it failed instead of returning a bare null. */
    private fun <T> quietly(operation: String, body: () -> T?): T? {
        return try {
            body()
        } catch (error: Exception) {
            WidgetLog.error(context, "read failed operation=$operation error=${error.logName()}")
            null
        }
    }

    /** Runs a write that answers with a value, `null` only on failure. */
    private fun <T> attempt(operation: String, source: String?, body: () -> T?): T? {
        return try {
            body()
        } catch (error: Exception) {
            WidgetLog.error(
                context,
                "write failed operation=$operation source=${source ?: "none"} " +
                    "error=${error.logName()}",
            )
            null
        }
    }

    private class Helper(context: Context, databaseName: String) : SQLiteOpenHelper(
        context,
        databaseName,
        null,
        DATABASE_VERSION,
    ) {
        override fun onCreate(database: SQLiteDatabase) {
            createDurableTables(database)
            createCacheTables(database)
        }

        /**
         * A schema change keeps what the user chose and rebuilds what can be
         * refetched.
         *
         * `widget_instances` is not re-fetchable: which location each Widget on
         * the home screen was configured with exists nowhere else, so the
         * durable tables are never dropped. Of the cache, the snapshot table has
         * kept its shape since v3, so its rows survive — with their acquisition
         * numbers reset, because the counter that issued them is rebuilt — and
         * an update does not blank every Widget until its first refresh. The
         * position degradation survives too; v2 stored it as a `needs_app`
         * boolean, which becomes the degradation it meant.
         */
        override fun onUpgrade(database: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            val degradations = readDegradations(database)
            val keepSnapshots = oldVersion >= 3
            rebuildCache(database, keepSnapshots)
            if (keepSnapshots) {
                database.execSQL("UPDATE $TABLE_SNAPSHOTS SET write_generation = 0, location_generation = 0")
            }
            for ((source, degradation) in degradations) {
                database.execSQL(
                    "INSERT INTO $TABLE_SOURCE_STATE (source_identifier, degradation, acquisition, updated_at)" +
                        " VALUES (?, ?, 0, 0)",
                    arrayOf(source, degradation.wire),
                )
            }
        }

        override fun onDowngrade(database: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            // A newer schema's cache cannot be read by this build, so it is
            // rebuilt; the durable tables are a subset of the newer shape.
            rebuildCache(database, keepSnapshots = false)
        }

        /** The stored degradations, from either the v2 flag or the v3+ column. */
        private fun readDegradations(database: SQLiteDatabase): Map<String, WidgetLocationDegradation> {
            val columns = columnNames(database, TABLE_SOURCE_STATE)
            val column = when {
                "degradation" in columns -> "degradation"
                "needs_app" in columns -> "needs_app"
                else -> return emptyMap()
            }
            val stored = LinkedHashMap<String, WidgetLocationDegradation>()
            database.rawQuery("SELECT source_identifier, $column FROM $TABLE_SOURCE_STATE", null).use { cursor ->
                while (cursor.moveToNext()) {
                    val degradation = if (column == "needs_app") {
                        WidgetLocationDegradation.Permission.takeIf { cursor.getInt(1) != 0 }
                    } else {
                        WidgetLocationDegradation.fromWire(cursor.getNullableString(1))
                    }
                    if (degradation != null) stored[cursor.getString(0)] = degradation
                }
            }
            return stored
        }

        private fun columnNames(database: SQLiteDatabase, table: String): Set<String> {
            val names = LinkedHashSet<String>()
            database.rawQuery("PRAGMA table_info($table)", null).use { cursor ->
                while (cursor.moveToNext()) names.add(cursor.getString(1))
            }
            return names
        }

        private fun rebuildCache(database: SQLiteDatabase, keepSnapshots: Boolean) {
            for (table in CACHE_TABLES + RETIRED_TABLES) {
                if (keepSnapshots && table == TABLE_SNAPSHOTS) continue
                database.execSQL("DROP TABLE IF EXISTS $table")
            }
            createCacheTables(database)
        }

        private fun createDurableTables(database: SQLiteDatabase) {
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_INSTANCES (" +
                    "app_widget_id INTEGER PRIMARY KEY," +
                    "source_identifier TEXT NOT NULL," +
                    "region_code TEXT," +
                    "updated_at INTEGER NOT NULL)",
            )
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_CATALOG (" +
                    "region_code TEXT PRIMARY KEY," +
                    "display_name TEXT NOT NULL," +
                    "administrative_area TEXT NOT NULL," +
                    "latitude REAL NOT NULL," +
                    "longitude REAL NOT NULL)",
            )
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_META (" +
                    "id INTEGER PRIMARY KEY," +
                    "schema_version INTEGER NOT NULL," +
                    "written_at INTEGER NOT NULL)",
            )
        }

        private fun createCacheTables(database: SQLiteDatabase) {
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_SNAPSHOTS (" +
                    "source_identifier TEXT PRIMARY KEY," +
                    "schema_version INTEGER NOT NULL," +
                    "region_code TEXT NOT NULL," +
                    "region_name TEXT NOT NULL," +
                    "observation_time INTEGER NOT NULL," +
                    "station_name TEXT NOT NULL," +
                    "weather TEXT NOT NULL," +
                    "weather_code INTEGER NOT NULL," +
                    "condition TEXT NOT NULL," +
                    "is_night INTEGER NOT NULL," +
                    "next_transition INTEGER NOT NULL," +
                    "calibrated_offset INTEGER NOT NULL," +
                    "temperature REAL," +
                    "humidity INTEGER," +
                    "rain REAL," +
                    "wind_direction TEXT," +
                    "wind_speed REAL," +
                    "apparent_temperature REAL," +
                    // The acquisition that wrote the row and the newest one in
                    // its township; see [SnapshotOrdering].
                    "write_generation INTEGER NOT NULL," +
                    "location_generation INTEGER NOT NULL," +
                    "written_at INTEGER NOT NULL)",
            )
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_FORECASTS (" +
                    "source_identifier TEXT PRIMARY KEY," +
                    "schema_version INTEGER NOT NULL," +
                    "region_code TEXT NOT NULL," +
                    "update_time INTEGER NOT NULL," +
                    "received_at INTEGER NOT NULL," +
                    // Calibrated receipt and the absolute expiry derived from it
                    // at commit time. Never recomputed: see [StoredForecast].
                    "received_calibrated INTEGER NOT NULL," +
                    "expires_at INTEGER NOT NULL," +
                    "written_at INTEGER NOT NULL)",
            )
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_FORECAST_POINTS (" +
                    "source_identifier TEXT NOT NULL," +
                    "position INTEGER NOT NULL," +
                    "time_label TEXT NOT NULL," +
                    "temperature REAL NOT NULL," +
                    "weather TEXT NOT NULL," +
                    "weather_code INTEGER NOT NULL," +
                    "pop INTEGER," +
                    "PRIMARY KEY (source_identifier, position))",
            )
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_SOURCE_STATE (" +
                    "source_identifier TEXT PRIMARY KEY," +
                    // NULL means "no degradation".
                    "degradation TEXT," +
                    "acquisition INTEGER NOT NULL," +
                    "refreshed_at INTEGER," +
                    "feedback_request TEXT," +
                    "feedback_state TEXT," +
                    "feedback_updated_at INTEGER," +
                    "feedback_expires_at INTEGER," +
                    "updated_at INTEGER NOT NULL)",
            )
        }
    }

    companion object {
        /** The file an upgrade test opens twice. */
        internal const val DATABASE_NAME = "dpip_widget.db"

        /**
         * Bumped when the tables change.
         *
         * * 2 — instance choices and the catalog moved out of the rebuild path.
         * * 3 — the position degradation replaced v2's `needs_app` flag, and
         *   forecasts gained the calibrated receipt and the absolute deadline.
         * * 4 — additive manual refresh feedback.
         * * 5 — one refresh chain: the reservation/fence table, the forecast
         *   demand and the separate feedback table are gone; acquisition,
         *   refresh time and feedback live on the source state.
         */
        const val DATABASE_VERSION = 5
        private const val META_CATALOG = 1

        private const val TABLE_INSTANCES = "widget_instances"
        private const val TABLE_CATALOG = "widget_catalog"
        private const val TABLE_META = "widget_meta"
        private const val TABLE_SOURCE_STATE = "widget_source_state"
        private const val TABLE_SNAPSHOTS = "widget_snapshots"
        private const val TABLE_FORECASTS = "widget_forecasts"
        private const val TABLE_FORECAST_POINTS = "widget_forecast_points"

        /** Everything re-derivable. The durable tables are deliberately absent. */
        private val CACHE_TABLES = listOf(
            TABLE_SNAPSHOTS,
            TABLE_FORECASTS,
            TABLE_FORECAST_POINTS,
            TABLE_SOURCE_STATE,
        )

        /** Tables earlier schemas had and v5 no longer creates. */
        private val RETIRED_TABLES = listOf("widget_ordering", "widget_refresh_feedback")

        /**
         * The process-wide store.
         *
         * It holds the **application** context only, which is process-scoped by
         * definition; a second instance would open a second connection.
         */
        @Suppress("StaticFieldLeak")
        @Volatile
        private var instance: WidgetStore? = null

        fun open(context: Context): WidgetStore =
            instance ?: synchronized(this) {
                instance ?: WidgetStore(context).also { instance = it }
            }

        /**
         * A store over its own helper, bypassing the process singleton.
         *
         * [databaseName] exists for the instrumented suite: it runs on a real,
         * daily-use device and must never open the production file.
         */
        internal fun openUncached(
            context: Context,
            databaseName: String = DATABASE_NAME,
        ): WidgetStore = WidgetStore(context, databaseName)

        /** Drops the process singleton, so a test starts from a clean file. */
        internal fun resetForTest() {
            synchronized(this) { instance = null }
        }

        /** The tables an upgrade must preserve, for tests and documentation. */
        val durableTables: List<String> = listOf(
            TABLE_INSTANCES,
            TABLE_CATALOG,
            TABLE_META,
        )
    }
}

private fun contentValuesOf(vararg pairs: Pair<String, Any?>): ContentValues {
    val values = ContentValues(pairs.size)
    for ((key, value) in pairs) {
        when (value) {
            null -> values.putNull(key)
            is Long -> values.put(key, value)
            is Int -> values.put(key, value)
            is Double -> values.put(key, value)
            is Float -> values.put(key, value)
            is String -> values.put(key, value)
            is Boolean -> values.put(key, value)
            else -> values.put(key, value.toString())
        }
    }
    return values
}

private fun instanceValues(appWidgetId: Int, address: WidgetAddress, regionCode: String?, updatedAt: Long) =
    contentValuesOf(
        "app_widget_id" to appWidgetId,
        "source_identifier" to address.sourceIdentifier,
        "region_code" to regionCode,
        "updated_at" to updatedAt,
    )

/**
 * One snapshot row, field by field.
 *
 * Stored as columns rather than as the source JSON: the channel decodes the
 * payload once on the way in, and the native fetch writes the same row shape as
 * the Flutter path without an encoder.
 */
private fun snapshotValues(
    snapshot: CurrentWeatherSnapshot,
    writeGeneration: Long,
    locationGeneration: Long,
    writtenAt: Long,
): ContentValues = contentValuesOf(
    "source_identifier" to snapshot.sourceIdentifier,
    "schema_version" to snapshot.schemaVersion,
    "region_code" to snapshot.regionCode,
    "region_name" to snapshot.regionName,
    "observation_time" to snapshot.observationTime,
    "station_name" to snapshot.stationName,
    "weather" to snapshot.weather,
    "weather_code" to snapshot.weatherCode,
    "condition" to snapshot.condition.wire,
    "is_night" to if (snapshot.isNight) 1 else 0,
    "next_transition" to snapshot.nextDayNightTransitionTime,
    "calibrated_offset" to snapshot.calibratedTimeOffsetMilliseconds,
    "temperature" to snapshot.temperature,
    "humidity" to snapshot.humidity,
    "rain" to snapshot.rain,
    "wind_direction" to snapshot.windDirection,
    "wind_speed" to snapshot.windSpeed,
    "apparent_temperature" to snapshot.apparentTemperature,
    "write_generation" to writeGeneration,
    "location_generation" to locationGeneration,
    "written_at" to writtenAt,
)

private fun Cursor.getNullableDouble(column: Int): Double? =
    if (isNull(column)) null else getDouble(column)

private fun Cursor.getNullableInt(column: Int): Int? =
    if (isNull(column)) null else getInt(column)

private fun Cursor.getNullableLong(column: Int): Long? =
    if (isNull(column)) null else getLong(column)

private fun Cursor.getNullableString(column: Int): String? =
    if (isNull(column)) null else getString(column)
