package com.exptech.dpip.widget

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import androidx.core.database.sqlite.transaction

/** A reserved ordering ticket for one logical refresh of one address. */
data class WidgetWriteToken(
    val sourceIdentifier: String,
    val generation: Long,
    val kind: WidgetSnapshotKind,
)

/**
 * What became of a commit.
 *
 * `Superseded` and `Failed` are separate on purpose. A superseded write lost an
 * ordering race — a clear, a reconfigure, or a newer observation landed first —
 * and is normal, not an error the app can act on. A failure means the write
 * never happened, and the Flutter side must hear about it: collapsing the two
 * into one `Rejected` made a broken database indistinguishable from a healthy
 * one that lost a race, and the channel reported success for both.
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

/** A stored current-weather snapshot together with the generation that wrote it. */
data class StoredCurrentWeather(
    val snapshot: CurrentWeatherSnapshot,
    val writeGeneration: Long,
    val locationGeneration: Long,
)

/**
 * The Widget's own SQLite database.
 *
 * This is a native-owned store, not a window onto Flutter's `dpip.db`. The plan
 * chose SQLite over a second JSON-plus-sidecar scheme because the ordering here
 * is a compare-and-set, and a database gives it one atomic transaction instead
 * of iOS's three-step fingerprint commit, which needs a recovery path for every
 * point it can be interrupted at. The tables are one-per-concern and only this
 * class opens them:
 *
 * * `widget_instances` — per-`appWidgetId` choice. **Durable.** Never cleared by
 *   a snapshot clear; a Widget keeps its town until its user changes it.
 * * `widget_catalog` — the saved locations Dart published. **Durable.**
 * * `widget_snapshots` / `widget_forecasts` — the cache. Re-fetchable.
 * * `widget_ordering` — one row per (kind, address): the reserved generation,
 *   the fence, and the committed snapshot's ordering metadata. Per-address
 *   because two Widgets for two towns must not share a generation, and one
 *   shared counter would let one town's refresh invalidate the other's.
 * * `widget_source_state` — whether an address currently needs the app for a
 *   position. Derived, but small and worth keeping across a schema change.
 *
 * Ordering, not clocks. `beginWrite` reserves a generation from the persisted
 * counter, so two processes (the app writing what Dart sent, the worker writing
 * what it fetched) have one comparable order even across a clock change. Every
 * commit re-checks its token inside the transaction that writes, which is what
 * makes a late response — after a clear, a reconfigure, or a move out of the
 * township — unable to resurrect a snapshot that was already superseded.
 *
 * The store never opens Flutter's database and Flutter never opens this one;
 * both directions are by value through the channel.
 */
class WidgetStore private constructor(
    context: Context,
    databaseName: String = DATABASE_NAME,
) {
    /**
     * The application context only.
     *
     * A static field holding a `Context` is a leak lint is right to flag — and
     * the fix is not a suppression: the singleton has no business reaching an
     * Activity, so it takes the application context and cannot hold anything
     * else.
     */
    private val context: Context = context.applicationContext

    private val helper = Helper(this.context, databaseName)

    // ── Location catalog ────────────────────────────────────────────────────

    /**
     * Replaces the catalog in one transaction.
     *
     * Any code the catalog no longer contains is fenced at the same time: a
     * fetch already in flight for a town the user just removed must not be able
     * to commit afterwards, and doing the fence in the same transaction as the
     * removal is the only way that cannot interleave.
     */
    @Synchronized
    fun writeCatalog(locations: List<WidgetCatalogLocation>, writtenAt: Long): Boolean {
        return attempt("catalog.write", null) {
            inTransaction { database ->
                val previous = readCatalogCodes(database)
                val next = locations.mapTo(HashSet()) { it.regionCode }

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

                for (removed in previous - next) {
                    fence(database, WidgetSnapshotKind.CurrentWeather, "region:$removed")
                    fence(database, WidgetSnapshotKind.WeatherForecast, "region:$removed")
                }
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
                    val location = WidgetCatalogLocation.create(
                        regionCode = cursor.getString(0),
                        displayName = cursor.getString(1),
                        administrativeAreaName = cursor.getString(2),
                        latitude = cursor.getDouble(3),
                        longitude = cursor.getDouble(4),
                    ) ?: return@quietly null
                    locations.add(location)
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
     * The three are not interchangeable to a caller that renders. "No such row"
     * means the user deleted that saved location and the Widget must say
     * *reconfigure*; a failed read means nothing about the row, and answering
     * *reconfigure* there tells the user to fix something that is not broken and
     * takes away the refresh button that would have recovered it. This is the
     * same distinction [WidgetInstanceReadResult.Failed] exists for, applied to
     * the catalog reads.
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
                val location = WidgetCatalogLocation.create(
                    regionCode = cursor.getString(0),
                    displayName = cursor.getString(1),
                    administrativeAreaName = cursor.getString(2),
                    latitude = cursor.getDouble(3),
                    longitude = cursor.getDouble(4),
                )
                // A row `create` rejects is treated as absent, as it was before
                // this distinction existed: it is a row no renderer can use, and
                // reconfiguring is what replaces it.
                if (location == null) WidgetCatalogLookup.Absent else WidgetCatalogLookup.Found(location)
            }
        } ?: WidgetCatalogLookup.Failed

    // Manual feedback survives process death. A request id fences an old,
    // cancelled worker's result; short expiry prevents orphaned "updating".
    @Synchronized
    internal fun beginRefreshFeedback(address: WidgetAddress, requestId: String, now: Long): Boolean =
        attempt("feedback.begin", address.sourceIdentifier) {
            helper.writableDatabase.insertWithOnConflict(
                TABLE_REFRESH_FEEDBACK, null,
                contentValuesOf(
                    "source_identifier" to address.sourceIdentifier,
                    "request_id" to requestId,
                    "state" to WidgetRefreshFeedback.Queued.wire,
                    "updated_at" to now,
                    "expires_at" to now + WidgetRefreshFeedback.Queued.durationMilliseconds,
                ), SQLiteDatabase.CONFLICT_REPLACE,
            ) != -1L
        } ?: false

    @Synchronized
    internal fun writeRefreshFeedback(
        address: WidgetAddress, requestId: String, state: WidgetRefreshFeedback, now: Long,
    ): Boolean = attempt("feedback.write", address.sourceIdentifier) {
        helper.writableDatabase.update(
            TABLE_REFRESH_FEEDBACK,
            contentValuesOf(
                "state" to state.wire,
                "updated_at" to now,
                "expires_at" to now + state.durationMilliseconds,
            ),
            "source_identifier = ? AND request_id = ?",
            arrayOf(address.sourceIdentifier, requestId),
        ) > 0
    } ?: false

    @Synchronized
    internal fun readRefreshFeedback(address: WidgetAddress, now: Long): StoredWidgetRefreshFeedback? =
        quietly("feedback.read") {
            helper.readableDatabase.rawQuery(
                "SELECT state, updated_at, expires_at FROM $TABLE_REFRESH_FEEDBACK WHERE source_identifier = ?",
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

    /**
     * Records an instance's choice, fencing the address it moved away from.
     *
     * The fence is skipped while another instance still uses that address: two
     * Widgets on one town share a source, and moving one of them must not
     * invalidate the other's refresh in flight. Mirrors [deleteInstance].
     */
    @Synchronized
    fun writeInstance(
        appWidgetId: Int,
        address: WidgetAddress,
        regionCode: String?,
        updatedAt: Long,
    ): Boolean {
        return attempt("instance.write", address.sourceIdentifier) {
            inTransaction { database ->
                val previous = readInstance(database, appWidgetId)?.address
                database.insertWithOnConflict(
                    TABLE_INSTANCES,
                    null,
                    contentValuesOf(
                        "app_widget_id" to appWidgetId,
                        "source_identifier" to address.sourceIdentifier,
                        "region_code" to regionCode,
                        "updated_at" to updatedAt,
                    ),
                    SQLiteDatabase.CONFLICT_REPLACE,
                )
                if (previous != null &&
                    previous.sourceIdentifier != address.sourceIdentifier &&
                    !anyInstanceUses(database, previous)
                ) {
                    fence(database, WidgetSnapshotKind.CurrentWeather, previous.sourceIdentifier)
                    fence(database, WidgetSnapshotKind.WeatherForecast, previous.sourceIdentifier)
                }
                true
            }
        } ?: false
    }

    @Synchronized
    fun deleteInstance(appWidgetId: Int): Boolean {
        return attempt("instance.delete", null) {
            inTransaction { database ->
                val removed = readInstance(database, appWidgetId)
                database.delete(TABLE_INSTANCES, "app_widget_id = ?", arrayOf(appWidgetId.toString()))
                if (removed != null && !anyInstanceUses(database, removed.address)) {
                    fence(database, WidgetSnapshotKind.CurrentWeather, removed.address.sourceIdentifier)
                    fence(database, WidgetSnapshotKind.WeatherForecast, removed.address.sourceIdentifier)
                }
                true
            }
        } ?: false
    }

    /**
     * Moves a restored instance's choice from its old id to its new one.
     *
     * A launcher restore hands back fresh ids and the framework pairs them by
     * position. Copying without deleting would leave the old row behind as a
     * ghost that keeps a source alive — so its address is never fenced, and
     * `usedAddresses` keeps fetching for an instance that no longer exists.
     */
    @Synchronized
    fun remapInstance(oldAppWidgetId: Int, newAppWidgetId: Int): Boolean {
        if (oldAppWidgetId == newAppWidgetId) return true
        return attempt("instance.remap", null) {
            inTransaction { database ->
                val previous = readInstance(database, oldAppWidgetId)
                if (previous == null) return@inTransaction false
                database.delete(
                    TABLE_INSTANCES,
                    "app_widget_id = ?",
                    arrayOf(oldAppWidgetId.toString()),
                )
                database.insertWithOnConflict(
                    TABLE_INSTANCES,
                    null,
                    contentValuesOf(
                        "app_widget_id" to newAppWidgetId,
                        "source_identifier" to previous.address.sourceIdentifier,
                        "region_code" to previous.regionCode,
                        "updated_at" to System.currentTimeMillis(),
                    ),
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
     * force-stopped or mis-restored state from leaving a row that keeps a
     * source fetching forever. Returns the surviving rows from the same
     * transaction; a failed read or delete is not authority to cancel work.
     */
    @Synchronized
    fun reconcileInstances(liveAppWidgetIds: Set<Int>): WidgetInstanceReadResult {
        return attempt("instance.reconcile", null) {
            inTransaction { database ->
                val removed = ArrayList<WidgetAddress>()
                val instances = readInstances(database)
                for (instance in instances) {
                    if (instance.appWidgetId in liveAppWidgetIds) continue
                    database.delete(
                        TABLE_INSTANCES,
                        "app_widget_id = ?",
                        arrayOf(instance.appWidgetId.toString()),
                    )
                    removed.add(instance.address)
                }
                for (address in removed) {
                    if (anyInstanceUses(database, address)) continue
                    fence(database, WidgetSnapshotKind.CurrentWeather, address.sourceIdentifier)
                    fence(database, WidgetSnapshotKind.WeatherForecast, address.sourceIdentifier)
                }
                WidgetInstanceReadResult.Read(
                    instances.filter { it.appWidgetId in liveAppWidgetIds },
                    removed,
                )
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

    /** Every address some instance still needs, de-duplicated in insertion order. */
    @Synchronized
    fun usedAddresses(): List<WidgetAddress> = quietly("instance.addresses") {
        val addresses = LinkedHashMap<String, WidgetAddress>()
        helper.readableDatabase.rawQuery(
            "SELECT DISTINCT source_identifier FROM $TABLE_INSTANCES",
            null,
        ).use { cursor ->
            while (cursor.moveToNext()) {
                WidgetAddress.fromSourceIdentifier(cursor.getString(0))
                    ?.let { addresses[it.sourceIdentifier] = it }
            }
        }
        addresses.values.toList()
    } ?: emptyList()

    /** True while any instance is addressed at [address]. */
    @Synchronized
    fun hasInstanceFor(address: WidgetAddress): Boolean = quietly("instance.has") {
        helper.readableDatabase.rawQuery(
            "SELECT 1 FROM $TABLE_INSTANCES WHERE source_identifier = ? LIMIT 1",
            arrayOf(address.sourceIdentifier),
        ).use { it.moveToFirst() }
    } ?: false

    // ── Current weather ─────────────────────────────────────────────────────

    @Synchronized
    fun beginCurrentWeatherWrite(address: WidgetAddress): WidgetWriteToken? =
        beginWrite(WidgetSnapshotKind.CurrentWeather, address.sourceIdentifier)

    /**
     * Commits a snapshot, and optionally the address's location degradation, in
     * one transaction.
     *
     * `locationStateAfterCommit` is how the degradation is *cleared*: only a
     * commit that actually landed may declare a position trustworthy again.
     * Clearing it earlier — as soon as a fix was obtained — told the layout the
     * position was good while the observation it belongs to had not been stored
     * yet, so a failed fetch left a widget claiming a current position it did
     * not have.
     */
    @Synchronized
    fun commitCurrentWeather(
        token: WidgetWriteToken,
        snapshot: CurrentWeatherSnapshot,
        writtenAt: Long,
        locationStateAfterCommit: LocationStateWrite = LocationStateWrite.Keep,
        /**
         * Re-checked inside the transaction, so a run that was stopped while its
         * fetch was in flight cannot land a snapshot the run that replaced it is
         * about to supersede. See [WeatherWidgetRefreshWorker].
         */
        isStillValid: () -> Boolean = { true },
    ): WidgetWriteResult {
        return commit("currentWeather", token, isStillValid) { database ->
            val guard = catalogGuard(database, token.sourceIdentifier)
            val existing = readOrdering(
                database,
                WidgetSnapshotKind.CurrentWeather,
                token.sourceIdentifier,
            )
            val candidate = SnapshotOrderingMetadata(
                snapshotGeneration = token.generation,
                locationGeneration = token.generation,
                valueTime = snapshot.observationTime,
                regionCode = snapshot.regionCode,
            )

            // A town that left the catalog must not accept a late observation.
            // Keep its durable instance choice; the layout independently checks
            // catalog membership and asks the user to reconfigure.
            if (guard == null) return@commit WidgetWriteResult.Superseded

            if (existing != null && !SnapshotOrdering.shouldReplace(
                    address = guard.address,
                    existing = existing,
                    candidate = candidate,
                )
            ) {
                // A newer same-township acquisition still advances the Current
                // Location fence even when its older observation cannot replace
                // the canonical snapshot. Mirrors
                // `CurrentWeatherSnapshotStorage.replace`.
                if (guard.address is WidgetAddress.CurrentLocation &&
                    candidate.regionCode == existing.regionCode &&
                    token.generation > existing.locationGeneration
                ) {
                    writeOrdering(
                        database,
                        WidgetSnapshotKind.CurrentWeather,
                        token.sourceIdentifier,
                        existing.copy(locationGeneration = token.generation),
                    )
                }
                return@commit WidgetWriteResult.Superseded
            }

            val locationGeneration = SnapshotOrdering.locationGeneration(
                address = guard.address,
                existing = existing,
                candidate = candidate,
            )
            database.insertWithOnConflict(
                TABLE_SNAPSHOTS,
                null,
                snapshotValues(token.sourceIdentifier, snapshot, token.generation, locationGeneration, writtenAt),
                SQLiteDatabase.CONFLICT_REPLACE,
            )
            writeOrdering(
                database,
                WidgetSnapshotKind.CurrentWeather,
                token.sourceIdentifier,
                candidate.copy(locationGeneration = locationGeneration),
            )
            when (val state = locationStateAfterCommit) {
                LocationStateWrite.Keep -> Unit
                // The commit's own generation: a later acquisition's state is
                // never overwritten by this one, and this one is never cleared
                // by an earlier success.
                is LocationStateWrite.Set -> applyLocationState(
                    database = database,
                    sourceIdentifier = token.sourceIdentifier,
                    degradation = state.degradation,
                    generation = token.generation,
                    updatedAt = writtenAt,
                )
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

                val snapshot = CurrentWeatherSnapshot(
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
                )
                StoredCurrentWeather(
                    snapshot = snapshot,
                    writeGeneration = cursor.getLong(17),
                    locationGeneration = cursor.getLong(18),
                )
            }
        }

    /**
     * Empties the current-weather cache and fences every token already issued.
     *
     * Only the snapshot is removed. Instances and the catalog are not the
     * snapshot's to delete — a clear that took the user's chosen town with it
     * would be indistinguishable from a reconfigure.
     */
    @Synchronized
    fun clearCurrentWeather(): Boolean = clear(WidgetSnapshotKind.CurrentWeather)

    /**
     * Empties one source's current-weather cache and fences its tokens.
     *
     * The app owns one source — whichever its Home selection resolves to — and
     * this is what a selection change uses. A blanket clear would take every
     * other Widget's town with it, which on a home screen showing two towns is
     * data loss the user never asked for.
     */
    @Synchronized
    fun clearCurrentWeatherSource(address: WidgetAddress): Boolean {
        return attempt("currentWeather.clearSource", address.sourceIdentifier) {
            inTransaction { database ->
                database.delete(
                    TABLE_SNAPSHOTS,
                    "source_identifier = ?",
                    arrayOf(address.sourceIdentifier),
                )
                fence(
                    database,
                    WidgetSnapshotKind.CurrentWeather,
                    address.sourceIdentifier,
                )
                true
            }
        } ?: false
    }

    // ── Forecast ────────────────────────────────────────────────────────────

    @Synchronized
    fun beginForecastWrite(address: WidgetAddress): WidgetWriteToken? =
        beginWrite(WidgetSnapshotKind.WeatherForecast, address.sourceIdentifier)

    /**
     * Commits a forecast together with the instants that make it expirable.
     *
     * `receivedCalibrated` and `expiresAt` are passed in rather than derived here
     * because the caller is the one holding the clock anchor at the moment the
     * response arrived — see [StoredForecast] for why they must be fixed then.
     */
    @Synchronized
    fun commitForecast(
        token: WidgetWriteToken,
        forecast: ForecastSnapshot,
        receivedCalibratedMilliseconds: Long,
        expiresAtMilliseconds: Long,
        writtenAt: Long,
        answeredDemandVersion: Long? = null,
        /** See [commitCurrentWeather] — a stopped run must not clear the demand. */
        isStillValid: () -> Boolean = { true },
    ): WidgetWriteResult {
        return commit("forecast", token, isStillValid) { database ->
            if (catalogGuard(database, token.sourceIdentifier) == null) {
                return@commit WidgetWriteResult.Superseded
            }

            // A forecast for one township must never be filed against another:
            // a late response from a township Current Location has left is
            // rejected here even before the read-time region check.
            val current = database.rawQuery(
                "SELECT region_code FROM $TABLE_SNAPSHOTS WHERE source_identifier = ?",
                arrayOf(token.sourceIdentifier),
            ).use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
            if (current != null && current != forecast.regionCode) {
                return@commit WidgetWriteResult.Superseded
            }

            val existing = readOrdering(
                database,
                WidgetSnapshotKind.WeatherForecast,
                token.sourceIdentifier,
            )
            val candidate = SnapshotOrderingMetadata(
                snapshotGeneration = token.generation,
                locationGeneration = token.generation,
                valueTime = forecast.updateTime,
                regionCode = forecast.regionCode,
            )
            if (!SnapshotOrdering.shouldReplace(
                    orderingAddress(token.sourceIdentifier),
                    existing,
                    candidate,
                )
            ) {
                return@commit WidgetWriteResult.Superseded
            }

            database.insertWithOnConflict(
                TABLE_FORECASTS,
                null,
                contentValuesOf(
                    "source_identifier" to token.sourceIdentifier,
                    "schema_version" to forecast.schemaVersion,
                    "region_code" to forecast.regionCode,
                    "update_time" to forecast.updateTime,
                    "received_at" to forecast.receivedAt,
                    "received_calibrated" to receivedCalibratedMilliseconds,
                    "expires_at" to expiresAtMilliseconds,
                    "write_generation" to token.generation,
                    "written_at" to writtenAt,
                ),
                SQLiteDatabase.CONFLICT_REPLACE,
            )
            database.delete(
                TABLE_FORECAST_POINTS,
                "source_identifier = ?",
                arrayOf(token.sourceIdentifier),
            )
            forecast.points.forEachIndexed { index, point ->
                database.insertOrThrow(TABLE_FORECAST_POINTS, null, contentValuesOf(
                    "source_identifier" to token.sourceIdentifier,
                    "position" to index,
                    "time_label" to point.time,
                    "temperature" to point.temperature,
                    "weather" to point.weather,
                    "weather_code" to point.weatherCode,
                    "pop" to point.pop,
                ))
            }
            writeOrdering(
                database,
                WidgetSnapshotKind.WeatherForecast,
                token.sourceIdentifier,
                candidate,
            )
            // The demand this fetch was answering, cleared **in the same
            // transaction** as the data that answers it, and only while the
            // version still matches. A resize that raised a newer demand during
            // the fetch leaves it raised, so the next run still fetches — an
            // unconditional `false` here is what made a mid-fetch resize
            // silently never get its forecast.
            if (answeredDemandVersion != null) {
                val state = readSourceState(database, token.sourceIdentifier)
                if (state == null || state.forecastDemandVersion == answeredDemandVersion) {
                    raiseForecastDemand(
                        database = database,
                        sourceIdentifier = token.sourceIdentifier,
                        demand = false,
                        updatedAt = writtenAt,
                    )
                }
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
            ForecastHeader(
                schemaVersion = cursor.getInt(0),
                regionCode = cursor.getString(1),
                updateTime = cursor.getLong(2),
                receivedAt = cursor.getLong(3),
                receivedCalibrated = cursor.getLong(4),
                expiresAt = cursor.getLong(5),
            )
        }
        if (header.schemaVersion != WidgetSnapshotDecoder.forecastSchemaVersion) return@quietly null

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
                        pop = if (cursor.isNull(4)) null else cursor.getInt(4),
                    ),
                )
            }
        }
        if (points.isEmpty()) return@quietly null

        StoredForecast(
            forecast = ForecastSnapshot(
                schemaVersion = header.schemaVersion,
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

    @Synchronized
    fun clearForecast(): Boolean = clear(WidgetSnapshotKind.WeatherForecast)

    // ── Per-address live state ──────────────────────────────────────────────

    /**
     * Records the position state for [address] **only if it is not older than
     * what is already there**.
     *
     * `generation` is the acquisition's write ticket — the same one its snapshot
     * commit uses. Without it the status is unordered, and both directions of the
     * race are wrong: a refresh that timed out can land after a newer one
     * succeeded and put the warning back, and an old success can clear a
     * revocation the user just caused. Comparing generations inside the
     * transaction is what makes the newer acquisition's answer the one that
     * survives, whichever reaches the database last.
     *
     * The row is kept even when the state is "fine" (`degradation` null) so the
     * generation is remembered: deleting it would let an older write look like
     * the first one.
     */
    @Synchronized
    fun writeLocationState(
        address: WidgetAddress,
        degradation: WidgetLocationDegradation?,
        generation: Long,
        updatedAt: Long,
    ): Boolean {
        return attempt("locationState.write", address.sourceIdentifier) {
            inTransaction { database ->
                applyLocationState(database, address.sourceIdentifier, degradation, generation, updatedAt)
                true
            }
        } ?: false
    }

    /** The recorded degradation, or null when the position is (or may be) fine. */
    @Synchronized
    fun readLocationState(address: WidgetAddress): WidgetLocationDegradation? =
        quietly("locationState.read") {
            readSourceState(helper.readableDatabase, address.sourceIdentifier)
                ?.degradation
        }

    /** The generation the recorded state belongs to; 0 when nothing is stored. */
    @Synchronized
    fun readLocationStateGeneration(address: WidgetAddress): Long = quietly("locationState.generation") {
        readSourceState(helper.readableDatabase, address.sourceIdentifier)?.generation
    } ?: 0L

    /**
     * Remembers that [address] wants a forecast it does not have.
     *
     * A resize from compact to medium raises the demand *after* a refresh for the
     * same source may already be running, and the request that would have brought
     * the forecast is de-duplicated against it. A flag that outlives the request
     * is what makes the demand self-healing: the running refresh, or the next
     * one, sees it and fetches, and it is cleared only once a forecast lands.
     */
    @Synchronized
    fun setForecastDemand(address: WidgetAddress, demand: Boolean, updatedAt: Long): Boolean {
        return attempt("forecastDemand.write", address.sourceIdentifier) {
            inTransaction { database ->
                raiseForecastDemand(database, address.sourceIdentifier, demand, updatedAt)
                true
            }
        } ?: false
    }

    @Synchronized
    fun hasForecastDemand(address: WidgetAddress): Boolean = quietly("forecastDemand.read") {
        readSourceState(helper.readableDatabase, address.sourceIdentifier)?.forecastDemand
    } ?: false

    /**
     * Retires the demand a forecast *already in the cache* answers.
     *
     * [commitForecast] clears the demand in the same transaction as the data, so
     * every fetch retires its own. A refresh that finds the cache already holding
     * this township's forecast, inside its deadline, never reaches that commit —
     * and the demand it was dispatched to answer would outlive the thing that
     * satisfied it. Left raised it is permanent: `wantsForecast` reads it on every
     * later options change, so each one reserves a forecast ticket and re-fetches
     * a forecast nothing draws, including after a resize back down to a size that
     * has no forecast to draw.
     *
     * Version-matched for the same reason the commit is: a resize that raised a
     * newer demand while this run was deciding must stay raised.
     */
    @Synchronized
    fun clearAnsweredForecastDemand(
        address: WidgetAddress,
        answeredDemandVersion: Long,
        updatedAt: Long,
    ): Boolean {
        return attempt("forecastDemand.answered", address.sourceIdentifier) {
            inTransaction { database ->
                val state = readSourceState(database, address.sourceIdentifier)
                if (state != null && state.forecastDemandVersion != answeredDemandVersion) {
                    return@inTransaction false
                }
                raiseForecastDemand(
                    database = database,
                    sourceIdentifier = address.sourceIdentifier,
                    demand = false,
                    updatedAt = updatedAt,
                )
                true
            }
        } ?: false
    }

    /** The version a fetch should name when it clears the demand it answered. */
    @Synchronized
    fun readForecastDemandVersion(address: WidgetAddress): Long =
        quietly("forecastDemand.version") {
            readSourceState(helper.readableDatabase, address.sourceIdentifier)
                ?.forecastDemandVersion
        } ?: 0L

    /**
     * Raises or clears the demand, keeping the version honest.
     *
     * Raising always bumps the version, so a fetch that started earlier can
     * recognise that its answer is no longer wanted. Clearing leaves it alone: a
     * clear is identified by the version it observed, and a later raise has to
     * be able to be greater than it.
     */
    private fun raiseForecastDemand(
        database: SQLiteDatabase,
        sourceIdentifier: String,
        demand: Boolean,
        updatedAt: Long,
    ) {
        val existing = readSourceState(database, sourceIdentifier)
        writeSourceState(
            database = database,
            sourceIdentifier = sourceIdentifier,
            degradation = existing?.degradation,
            generation = existing?.generation ?: 0L,
            forecastDemand = demand,
            forecastDemandVersion = if (demand) {
                (existing?.forecastDemandVersion ?: 0L) + 1
            } else {
                existing?.forecastDemandVersion ?: 0L
            },
            updatedAt = updatedAt,
        )
    }

    // ── Reservation ─────────────────────────────────────────────────────────

    /**
     * Reserves both of one refresh's write tickets in **one** transaction.
     *
     * Two separate reservations left a window between them: a `clearForecast`
     * landing there fenced the first token but not the second, and the refresh
     * then held a *fresh* forecast ticket for a response it had already started
     * fetching — which would commit a forecast the clear had just removed.
     * Reserving both at once removes the window rather than trying to detect it.
     */
    @Synchronized
    fun beginRefreshWrites(
        address: WidgetAddress,
        includeForecast: Boolean,
    ): RefreshWriteTokens? {
        return attempt("refresh.begin", address.sourceIdentifier) {
            inTransaction { database ->
                val current = reserveToken(
                    database,
                    WidgetSnapshotKind.CurrentWeather,
                    address.sourceIdentifier,
                ) ?: return@inTransaction null
                // Consecutive generations from two independent counters, but
                // issued inside one transaction: no clear can be interleaved.
                val forecast = if (includeForecast) {
                    reserveToken(
                        database,
                        WidgetSnapshotKind.WeatherForecast,
                        address.sourceIdentifier,
                    )
                } else {
                    null
                }
                RefreshWriteTokens(current, forecast)
            }
        }
    }

    // ── Shared machinery ────────────────────────────────────────────────────

    private data class ForecastHeader(
        val schemaVersion: Int,
        val regionCode: String,
        val updateTime: Long,
        val receivedAt: Long,
        val receivedCalibrated: Long,
        val expiresAt: Long,
    )

    private data class CatalogGuard(val address: WidgetAddress, val regionCode: String?)

    /**
     * Runs [body] and reports a failure rather than swallowing it.
     *
     * The distinction the previous version lost: an exception from SQLite (a
     * corrupt file, a full disk, a schema mismatch) came back as `null` and was
     * indistinguishable from "the ordering refused this", so the platform
     * channel reported success for a write that never happened.
     */
    private fun commit(
        operation: String,
        token: WidgetWriteToken,
        isStillValid: () -> Boolean = { true },
        body: (SQLiteDatabase) -> WidgetWriteResult,
    ): WidgetWriteResult {
        return try {
            inTransaction { database ->
                // Inside the transaction, not merely before it: the caller's
                // "still valid" answer — for a worker, "has this run been
                // stopped?" — is re-read here so a stop that lands after the
                // caller's own check still finds nothing written.
                if (!isStillValid()) return@inTransaction WidgetWriteResult.Superseded
                val state = readOrderingCursor(database, token.kind, token.sourceIdentifier)
                    ?: return@inTransaction WidgetWriteResult.Superseded
                if (token.generation <= state.rejectedThrough ||
                    token.generation > state.lastIssued
                ) {
                    return@inTransaction WidgetWriteResult.Superseded
                }
                body(database)
            }
        } catch (error: Exception) {
            WidgetLog.error(
                context,
                "write failed operation=$operation source=${token.sourceIdentifier} " +
                    "error=${error.logName()}",
            )
            WidgetWriteResult.Failed
        }
    }

    private fun catalogGuard(
        database: SQLiteDatabase,
        sourceIdentifier: String,
    ): CatalogGuard? {
        val address = WidgetAddress.fromSourceIdentifier(sourceIdentifier) ?: return null
        if (address is WidgetAddress.Saved) {
            val present = database.rawQuery(
                "SELECT 1 FROM $TABLE_CATALOG WHERE region_code = ? LIMIT 1",
                arrayOf(address.regionCode),
            ).use { it.moveToFirst() }
            if (!present) return null
            return CatalogGuard(address, address.regionCode)
        }
        return CatalogGuard(address, null)
    }

    private fun orderingAddress(sourceIdentifier: String): WidgetAddress =
        WidgetAddress.fromSourceIdentifier(sourceIdentifier) ?: WidgetAddress.CurrentLocation

    private fun beginWrite(
        kind: WidgetSnapshotKind,
        sourceIdentifier: String,
    ): WidgetWriteToken? {
        if (WidgetAddress.fromSourceIdentifier(sourceIdentifier) == null) return null
        return attempt("${kind.wire}.begin", sourceIdentifier) {
            inTransaction { database -> reserveToken(database, kind, sourceIdentifier) }
        }
    }

    /**
     * Issues one generation. Assumes a transaction is already open.
     *
     * Reserve only. The committed metadata is carried across untouched:
     * reserving a ticket is not evidence that anything was written, and a
     * reserve that moved `snapshot_generation` would make the next comparison
     * think this generation had already landed.
     */
    private fun reserveToken(
        database: SQLiteDatabase,
        kind: WidgetSnapshotKind,
        sourceIdentifier: String,
    ): WidgetWriteToken? {
        if (WidgetAddress.fromSourceIdentifier(sourceIdentifier) == null) return null
        val state = readOrderingCursor(database, kind, sourceIdentifier)
        val lastIssued = state?.lastIssued ?: 0L
        if (lastIssued >= Long.MAX_VALUE - 2) return null
        val generation = lastIssued + 1
        writeOrderingState(
            database = database,
            kind = kind,
            sourceIdentifier = sourceIdentifier,
            lastIssued = generation,
            rejectedThrough = state?.rejectedThrough ?: 0L,
            committed = state?.committed,
        )
        return WidgetWriteToken(sourceIdentifier, generation, kind)
    }

    private fun clear(kind: WidgetSnapshotKind): Boolean {
        return attempt("${kind.wire}.clear", null) {
            inTransaction { database ->
                when (kind) {
                    WidgetSnapshotKind.CurrentWeather ->
                        database.delete(TABLE_SNAPSHOTS, null, null)
                    WidgetSnapshotKind.WeatherForecast -> {
                        database.delete(TABLE_FORECASTS, null, null)
                        database.delete(TABLE_FORECAST_POINTS, null, null)
                    }
                    WidgetSnapshotKind.LocationCatalog -> Unit
                }
                database.execSQL(
                    "UPDATE $TABLE_ORDERING SET rejected_through = last_issued WHERE kind = ?",
                    arrayOf(kind.wire),
                )
                true
            }
        } ?: false
    }

    private fun fence(
        database: SQLiteDatabase,
        kind: WidgetSnapshotKind,
        sourceIdentifier: String,
    ) {
        database.execSQL(
            "UPDATE $TABLE_ORDERING SET rejected_through = last_issued" +
                " WHERE kind = ? AND source_identifier = ?",
            arrayOf(kind.wire, sourceIdentifier),
        )
    }

    private fun anyInstanceUses(database: SQLiteDatabase, address: WidgetAddress): Boolean =
        database.rawQuery(
            "SELECT 1 FROM $TABLE_INSTANCES WHERE source_identifier = ? LIMIT 1",
            arrayOf(address.sourceIdentifier),
        ).use { it.moveToFirst() }

    private class OrderingState(
        val lastIssued: Long,
        val rejectedThrough: Long,
        val committed: SnapshotOrderingMetadata?,
    )

    private fun readOrdering(
        database: SQLiteDatabase,
        kind: WidgetSnapshotKind,
        sourceIdentifier: String,
    ): SnapshotOrderingMetadata? =
        readOrderingCursor(database, kind, sourceIdentifier)?.committed

    private fun readOrderingCursor(
        database: SQLiteDatabase,
        kind: WidgetSnapshotKind,
        sourceIdentifier: String,
    ): OrderingState? {
        return database.rawQuery(
            "SELECT last_issued, rejected_through, snapshot_generation, location_generation," +
                " value_time, region_code FROM $TABLE_ORDERING" +
                " WHERE kind = ? AND source_identifier = ?",
            arrayOf(kind.wire, sourceIdentifier),
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            if (cursor.isNull(2)) {
                return OrderingState(cursor.getLong(0), cursor.getLong(1), null)
            }
            OrderingState(
                lastIssued = cursor.getLong(0),
                rejectedThrough = cursor.getLong(1),
                committed = SnapshotOrderingMetadata(
                    snapshotGeneration = cursor.getLong(2),
                    locationGeneration = cursor.getLong(3),
                    valueTime = cursor.getLong(4),
                    regionCode = cursor.getString(5),
                ),
            )
        }
    }

    private fun writeOrdering(
        database: SQLiteDatabase,
        kind: WidgetSnapshotKind,
        sourceIdentifier: String,
        committed: SnapshotOrderingMetadata,
    ) {
        val state = readOrderingCursor(database, kind, sourceIdentifier)
        writeOrderingState(
            database = database,
            kind = kind,
            sourceIdentifier = sourceIdentifier,
            lastIssued = state?.lastIssued ?: committed.snapshotGeneration,
            rejectedThrough = state?.rejectedThrough ?: 0L,
            committed = committed,
        )
    }

    private fun writeOrderingState(
        database: SQLiteDatabase,
        kind: WidgetSnapshotKind,
        sourceIdentifier: String,
        lastIssued: Long,
        rejectedThrough: Long,
        committed: SnapshotOrderingMetadata?,
    ) {
        database.insertWithOnConflict(
            TABLE_ORDERING,
            null,
            contentValuesOf(
                "kind" to kind.wire,
                "source_identifier" to sourceIdentifier,
                "last_issued" to lastIssued,
                "rejected_through" to rejectedThrough,
                "snapshot_generation" to committed?.snapshotGeneration,
                "location_generation" to committed?.locationGeneration,
                "value_time" to committed?.valueTime,
                "region_code" to committed?.regionCode,
            ),
            SQLiteDatabase.CONFLICT_REPLACE,
        )
    }

    /** One address's live state, as stored. */
    private data class SourceState(
        val degradation: WidgetLocationDegradation?,
        val generation: Long,
        val forecastDemand: Boolean,
        val forecastDemandVersion: Long,
    )

    private fun readSourceState(
        database: SQLiteDatabase,
        sourceIdentifier: String,
    ): SourceState? {
        return database.rawQuery(
            "SELECT degradation, generation, forecast_demand, forecast_demand_version" +
                " FROM $TABLE_SOURCE_STATE WHERE source_identifier = ?",
            arrayOf(sourceIdentifier),
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            SourceState(
                degradation = WidgetLocationDegradation.fromWire(cursor.getString(0)),
                generation = cursor.getLong(1),
                forecastDemand = cursor.getInt(2) != 0,
                forecastDemandVersion = cursor.getLong(3),
            )
        }
    }

    /**
     * Writes a state, ignoring one that is older than what is stored.
     *
     * The comparison is inside the caller's transaction, so two writers cannot
     * interleave between the read and the write — which is the whole point: the
     * outcome must be the same whichever reached the database last.
     */
    private fun applyLocationState(
        database: SQLiteDatabase,
        sourceIdentifier: String,
        degradation: WidgetLocationDegradation?,
        generation: Long,
        updatedAt: Long,
    ) {
        val existing = readSourceState(database, sourceIdentifier)
        if (existing != null && existing.generation > generation) return
        writeSourceState(
            database = database,
            sourceIdentifier = sourceIdentifier,
            degradation = degradation,
            generation = generation,
            forecastDemand = existing?.forecastDemand ?: false,
            forecastDemandVersion = existing?.forecastDemandVersion ?: 0L,
            updatedAt = updatedAt,
        )
    }

    private fun writeSourceState(
        database: SQLiteDatabase,
        sourceIdentifier: String,
        degradation: WidgetLocationDegradation?,
        generation: Long,
        forecastDemand: Boolean,
        forecastDemandVersion: Long,
        updatedAt: Long,
    ) {
        database.insertWithOnConflict(
            TABLE_SOURCE_STATE,
            null,
            contentValuesOf(
                "source_identifier" to sourceIdentifier,
                "degradation" to degradation?.wire,
                "generation" to generation,
                "forecast_demand" to if (forecastDemand) 1 else 0,
                "forecast_demand_version" to forecastDemandVersion,
                "updated_at" to updatedAt,
            ),
            SQLiteDatabase.CONFLICT_REPLACE,
        )
    }

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
        val regionCode = if (cursor.isNull(2)) null else cursor.getString(2)
        return WidgetInstance(cursor.getInt(0), address, regionCode, cursor.getLong(3))
    }

    private fun readCatalogCodes(database: SQLiteDatabase): Set<String> {
        val codes = HashSet<String>()
        database.rawQuery("SELECT region_code FROM $TABLE_CATALOG", null).use { cursor ->
            while (cursor.moveToNext()) codes.add(cursor.getString(0))
        }
        return codes
    }

    /**
     * One transaction, via the `androidx.core` extension.
     *
     * The extension is the same three calls — begin, mark successful, end — with
     * the end in a `finally`, so an exception rolls back. It is used rather than
     * written out because `tool/dev/lint_android.sh` flags the hand-rolled form
     * and a suppression for something this mechanical would be noise.
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

    /** Runs a transaction that answers with a value, `null` only on failure. */
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
         * refetched — and, where a durable table gained a column, migrates it
         * rather than replacing it.
         *
         * The first version of this dropped every table. `widget_snapshots` is
         * re-fetchable, but `widget_instances` is not: which location each Widget
         * on the home screen was configured with exists nowhere else, and Dart
         * cannot republish it — the catalog is the list of saved places, not the
         * list of Widgets. Dropping it silently turned every instance into an
         * unconfigured one after an app update.
         *
         * Version 3 is the interesting one: the *columns* changed, not just the
         * contents. `widget_source_state` grew a degradation and a demand version
         * where it used to hold a `needs_app` boolean, and `widget_forecasts`
         * grew the calibrated receipt and deadline. Bumping the version without
         * a migration would have left a device that updated from the previous
         * build with missing columns — every read failing, which looks exactly
         * like a corrupt database. So the durable rows are migrated (the old
         * boolean becomes the degradation it meant) and the cache is rebuilt.
         */
        override fun onUpgrade(database: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            if (oldVersion == 3 && newVersion == 4) {
                // Feedback is additive: preserve all observations and choices.
                createRefreshFeedbackTable(database)
                return
            }
            // Read the legacy values *before* the rebuild: `widget_source_state`
            // is part of the cache and the rebuild drops it, so migrating it in
            // place afterwards would write into a table that no longer exists.
            val legacyState = if (oldVersion < 3) readLegacyNeedsApp(database) else emptyMap()
            rebuildCache(database)
            if (legacyState.isNotEmpty()) restoreLegacyState(database, legacyState)
        }

        override fun onDowngrade(database: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            // A newer schema's cache cannot be read by this build, so it is
            // rebuilt; the durable tables are left as they are, because this
            // build's columns are a subset of the newer shape.
            rebuildCache(database)
        }

        /**
         * The v2 `needs_app` flags, keyed by source.
         *
         * v2's `widget_source_state` was `(source_identifier, needs_app,
         * updated_at)`: a boolean meaning "the position needs the app". v3 states
         * the same fact as a named degradation, so a raised flag becomes
         * [WidgetLocationDegradation.Permission] — the reason the flag existed.
         */
        private fun readLegacyNeedsApp(database: SQLiteDatabase): Map<String, Boolean> {
            val columns = columnNames(database, TABLE_SOURCE_STATE)
            if ("needs_app" !in columns || "degradation" in columns) return emptyMap()
            val legacy = LinkedHashMap<String, Boolean>()
            database.rawQuery(
                "SELECT source_identifier, needs_app FROM $TABLE_SOURCE_STATE",
                null,
            ).use { cursor ->
                while (cursor.moveToNext()) {
                    legacy[cursor.getString(0)] = cursor.getInt(1) != 0
                }
            }
            return legacy
        }

        private fun restoreLegacyState(
            database: SQLiteDatabase,
            legacy: Map<String, Boolean>,
        ) {
            for ((source, needsApp) in legacy) {
                database.execSQL(
                    "INSERT INTO $TABLE_SOURCE_STATE" +
                        " (source_identifier, degradation, generation," +
                        " forecast_demand, forecast_demand_version, updated_at)" +
                        " VALUES (?, ?, 0, 0, 0, 0)",
                    arrayOf(
                        source,
                        if (needsApp) WidgetLocationDegradation.Permission.wire else null,
                    ),
                )
            }
        }

        private fun columnNames(database: SQLiteDatabase, table: String): Set<String> {
            val names = LinkedHashSet<String>()
            database.rawQuery("PRAGMA table_info($table)", null).use { cursor ->
                while (cursor.moveToNext()) names.add(cursor.getString(1))
            }
            return names
        }

        private fun rebuildCache(database: SQLiteDatabase) {
            for (table in CACHE_TABLES) {
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

        private fun createSourceStateTable(database: SQLiteDatabase) {
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_SOURCE_STATE (" +
                    "source_identifier TEXT PRIMARY KEY," +
                    // NULL means "no degradation"; the row is kept so the
                    // generation survives a clear. See [writeLocationState].
                    "degradation TEXT," +
                    "generation INTEGER NOT NULL," +
                    "forecast_demand INTEGER NOT NULL," +
                    // Bumped every time a demand is raised. A clear names the
                    // version it observed and is ignored if a newer demand has
                    // appeared since — which is how a fetch that started before
                    // a resize cannot answer for it. See [commitForecast].
                    "forecast_demand_version INTEGER NOT NULL," +
                    "updated_at INTEGER NOT NULL)",
            )
        }

        private fun createCacheTables(database: SQLiteDatabase) {
            createRefreshFeedbackTable(database)
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
                    "write_generation INTEGER NOT NULL," +
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
            createSourceStateTable(database)
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_ORDERING (" +
                    "kind TEXT NOT NULL," +
                    "source_identifier TEXT NOT NULL," +
                    "last_issued INTEGER NOT NULL," +
                    "rejected_through INTEGER NOT NULL," +
                    "snapshot_generation INTEGER," +
                    "location_generation INTEGER," +
                    "value_time INTEGER," +
                    "region_code TEXT," +
                    "PRIMARY KEY (kind, source_identifier))",
            )
        }

        private fun createRefreshFeedbackTable(database: SQLiteDatabase) {
            database.execSQL(
                "CREATE TABLE IF NOT EXISTS $TABLE_REFRESH_FEEDBACK (" +
                    "source_identifier TEXT PRIMARY KEY," +
                    "request_id TEXT NOT NULL," +
                    "state TEXT NOT NULL," +
                    "updated_at INTEGER NOT NULL," +
                    "expires_at INTEGER NOT NULL)",
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
         * * 3 — `widget_source_state` gained the degradation, generation, demand
         *   and demand-version columns, and `widget_forecasts` gained the
         *   calibrated receipt and the absolute deadline. A device that updated
         *   across this needs the migration above; without it every read of the
         *   new columns fails.
         * * 4 — additive, short-lived manual refresh feedback; v3 caches survive.
         */
        const val DATABASE_VERSION = 4
        private const val META_CATALOG = 1

        private const val TABLE_INSTANCES = "widget_instances"
        private const val TABLE_CATALOG = "widget_catalog"
        private const val TABLE_META = "widget_meta"
        private const val TABLE_SOURCE_STATE = "widget_source_state"
        private const val TABLE_SNAPSHOTS = "widget_snapshots"
        private const val TABLE_FORECASTS = "widget_forecasts"
        private const val TABLE_FORECAST_POINTS = "widget_forecast_points"
        private const val TABLE_ORDERING = "widget_ordering"
        private const val TABLE_REFRESH_FEEDBACK = "widget_refresh_feedback"

        /**
         * Everything re-derivable: a snapshot can be re-fetched, an ordering
         * counter restarts, and a location degradation is rewritten by the next
         * refresh. The durable tables — the instance choices and the catalog —
         * are deliberately absent, because nothing else in the app knows them.
         */
        private val CACHE_TABLES = listOf(
            TABLE_SNAPSHOTS,
            TABLE_FORECASTS,
            TABLE_FORECAST_POINTS,
            TABLE_ORDERING,
            TABLE_SOURCE_STATE,
            TABLE_REFRESH_FEEDBACK,
        )

        /**
         * The process-wide store.
         *
         * `@Suppress("StaticFieldLeak")`: the field holds a store, and the store
         * holds the **application** context (`WidgetStore.context`), which is
         * process-scoped by definition. Lint cannot see through the field to that
         * guarantee, and the alternative — no singleton — would open a second
         * connection to the same file for every caller.
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
         * The singleton is right for production — one connection, one lock — but
         * it would carry state between tests, and a migration test has to open
         * the same file twice with different versions.
         *
         * [databaseName] exists for the instrumented suite: it runs on a real,
         * daily-use device, and a device test that deleted `dpip_widget.db` would
         * take the user's Widgets and their chosen towns with it. Those tests open
         * their own file instead and never name the production one.
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

/**
 * One snapshot row, field by field.
 *
 * The snapshot is stored as columns rather than as the source JSON. Nothing
 * downstream needs the original bytes — the channel decodes them once on the
 * way in — and a columnar row cannot be re-read as a payload some future schema
 * disagrees with. It also means the native fetch path writes the same row shape
 * as the Flutter path without an encoder.
 */
private fun snapshotValues(
    sourceIdentifier: String,
    snapshot: CurrentWeatherSnapshot,
    writeGeneration: Long,
    locationGeneration: Long,
    writtenAt: Long,
): ContentValues = contentValuesOf(
    "source_identifier" to sourceIdentifier,
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

private fun Cursor.getNullableString(column: Int): String? =
    if (isNull(column)) null else getString(column)
