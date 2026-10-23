package com.exptech.dpip.widget

import android.content.Context

/** The outcome of one refresh, mirroring `CurrentWeatherWidgetRefreshResult`. */
enum class WidgetRefreshResult {
    Refreshed,
    Superseded,
    NoObservation,
    Unavailable,
    Failed,

    /**
     * The run was stopped before it could land anything.
     *
     * Its own result, not `Superseded`: nothing was attempted, so there is no
     * ordering to report — and the worker must not treat it as a transient
     * failure worth retrying, because the replacement run is the retry.
     */
    Cancelled,
}

/** Where an address's query point comes from, or why it has none. */
sealed interface LocationResolution {
    data class Resolved(val location: ResolvedWeatherLocation) : LocationResolution

    /** The position cannot be trusted now; keep the snapshot and say why. */
    data class Degraded(val degradation: WidgetLocationDegradation) : LocationResolution

    /** Nothing to say about the position — a missing catalog entry, say. */
    data object Unavailable : LocationResolution
}

/**
 * One refresh of one address: reserve, calibrate, resolve, fetch, order, commit.
 *
 * The shape is iOS's `CurrentWeatherWidgetRefreshPipeline` plus the resolution
 * in front of it, with three rules that are the difference between a correct
 * widget and a subtly wrong one:
 *
 * * **The write token is reserved first, before any other work.** `beginWrite`
 *   is the first statement, ahead of the clock's UDP exchange, the location fix
 *   and the HTTP fetch. Reserving later — as the first version did, after the
 *   clock — left a window in which a `clear`, a reconfigure or a *newer*
 *   refresh for the same address could complete, and this refresh would then
 *   hold a *higher* generation and be accepted on arrival, resurrecting data
 *   that had been cleared or overwriting a township the device had moved to.
 *   The token is the refresh's identity; it has to exist before the refresh can
 *   be overtaken.
 * * **The forecast refresh is bound to the same identity.** Its token is
 *   reserved in the same breath, so a clear that lands during the current-
 *   weather fetch fences both, and a forecast for a township the user has left
 *   cannot be committed after the current weather has refused to move. Whether
 *   the ticket is spent is decided *after* the position resolves, because only
 *   then is the township known.
 * * **The clock does not wait for the position.** A device that grants only
 *   foreground location still has a fresh observation published by the app, and
 *   the screen can only judge it fresh if the process holds a calibrated anchor.
 *   Calibrating after the position meant a degraded fix returned first and every
 *   screen then said "outdated" for ever.
 * * **A stopped run lands nothing.** The optional `isCancelled` signal is
 *   checked before each expensive step and again inside the commit's own
 *   transaction, so a run whose replacement `REPLACE` already queued cannot
 *   fetch, commit, clear the new demand or re-arm the schedule.
 *
 * Dependencies are injected so the ordering is testable with a controllable
 * fetcher: `WidgetRefreshServiceTest` holds one refresh inside its fetch, clears
 * the cache underneath it, and asserts the commit is refused.
 *
 * Blocking by design: it runs on a WorkManager worker thread (or the channel's
 * IO thread), never on the main thread.
 */
class WidgetRefreshService(
    private val context: Context,
    private val store: WidgetStore,
    private val resolveAddress: (WidgetAddress) -> LocationResolution,
    private val synchronizeClock: () -> Boolean,
    private val snapshotTime: () -> WidgetSnapshotTime?,
    private val fetchWeather: (Double, Double) -> RemoteCurrentWeather?,
    private val fetchForecast: (String) -> RemoteForecast,
    private val nowMilliseconds: () -> Long,
    /** The trusted clock, read at commit time so a receipt is dated when it arrives. */
    private val calibratedNowMilliseconds: () -> Long? = { WidgetClock.calibratedNowMilliseconds() },
) {
    fun refresh(
        address: WidgetAddress,
        includeForecast: Boolean,
        /**
         * The forecast-demand version observed before this run started, if any.
         *
         * Passed through to the commit, which clears the demand only while the
         * version still matches: a resize that raised a newer demand while this
         * fetch was in flight must not be answered by it.
         */
        answeredDemandVersion: Long? = null,
        /**
         * Whether the run that owns this refresh has already been stopped.
         *
         * Cancelling a `WorkInfo` — which is what `ExistingWorkPolicy.REPLACE`
         * does to the run it replaces — does not interrupt a blocking worker, so
         * a run can be stopped while it is parked inside its own fetch. Without
         * this signal that run would still commit, clear the *replacement's*
         * forecast demand and re-arm the schedule. Checked before every
         * expensive step and again inside the commit's own transaction, so a
         * stopped run leaves nothing behind for the run that replaced it.
         */
        isCancelled: () -> Boolean = { false },
    ): WidgetRefreshResult {
        if (isCancelled()) return WidgetRefreshResult.Cancelled

        // ── The refresh's identity, reserved before anything can overtake it ──
        //
        // Both tickets in one transaction: two reservations would leave a window
        // in which a `clearForecast` fences the first token but not the second,
        // and this refresh would then hold a fresh forecast ticket for a response
        // it had already begun fetching.
        val tokens = store.beginRefreshWrites(address, includeForecast)
        if (tokens == null) {
            WidgetLog.error(context, "refresh rejected source=${address.sourceIdentifier} reason=no-token")
            return WidgetRefreshResult.Failed
        }
        val currentToken = tokens.currentWeather
        val forecastToken = tokens.forecast

        // ── Calibration, before the position ──
        //
        // The clock must not depend on a background fix. A device that grants
        // only foreground location still has a fresh observation published by
        // the app, and the screen can only say whether it is fresh if the clock
        // is anchored. Calibrating *after* the position meant a degraded fix
        // returned before the exchange had run, so the process held no anchor
        // and every screen it drew called the observation outdated for ever.
        if (!synchronizeClock()) {
            WidgetLog.warning(context, "clock unavailable source=${address.sourceIdentifier}")
            return WidgetRefreshResult.Unavailable
        }
        val time = snapshotTime()
            ?: return WidgetRefreshResult.Unavailable

        if (isCancelled()) {
            WidgetLog.info(
                context,
                "refresh stopped source=${address.sourceIdentifier} before its position",
            )
            return WidgetRefreshResult.Cancelled
        }

        // ── The query point ──
        val location = when (val resolution = resolveAddress(address)) {
            is LocationResolution.Resolved -> {
                WidgetLog.info(
                    context,
                    "position resolved source=${address.sourceIdentifier} " +
                        "region=${resolution.location.regionCode}",
                )
                resolution.location
            }

            is LocationResolution.Degraded -> {
                // Recorded immediately as well as at commit time, so a refresh
                // that dies before its commit still leaves the reason on screen.
                // Carries this acquisition's generation, so an older refresh
                // finishing later cannot put the warning back after a newer one
                // succeeded — nor clear a newer revocation (see the store).
                store.writeLocationState(
                    address = address,
                    degradation = resolution.degradation,
                    generation = currentToken.generation,
                    updatedAt = nowMilliseconds(),
                )
                WidgetLog.warning(
                    context,
                    "position degraded source=${address.sourceIdentifier} " +
                        "reason=${resolution.degradation.wire}",
                )
                return WidgetRefreshResult.Unavailable
            }

            LocationResolution.Unavailable -> {
                WidgetLog.warning(
                    context,
                    "position unavailable source=${address.sourceIdentifier}",
                )
                return WidgetRefreshResult.Unavailable
            }
        }

        if (isCancelled()) {
            WidgetLog.info(
                context,
                "refresh stopped source=${address.sourceIdentifier} before its weather fetch",
            )
            return WidgetRefreshResult.Cancelled
        }

        // ── The observation ──
        val observation = try {
            fetchWeather(location.latitude, location.longitude)
        } catch (error: Exception) {
            // A failed fetch leaves the previous snapshot alone (stale-but-shown
            // beats blank) and is not an error the user can act on.
            WidgetLog.warning(
                context,
                "weather failed source=${address.sourceIdentifier} error=${error.logName()}",
            )
            return WidgetRefreshResult.Failed
        } ?: return WidgetRefreshResult.NoObservation

        // The stop can land while the fetch is in flight, and a blocking fetch is
        // not interrupted by it: check again before doing anything with the answer.
        if (isCancelled()) {
            WidgetLog.info(
                context,
                "refresh stopped source=${address.sourceIdentifier} after its fetch",
            )
            return WidgetRefreshResult.Cancelled
        }

        val snapshot = snapshot(observation, location, time)
        val committed = store.commitCurrentWeather(
            token = currentToken,
            snapshot = snapshot,
            writtenAt = nowMilliseconds(),
            // Only a commit that lands may declare the position trustworthy:
            // clearing it as soon as a fix was obtained left a widget claiming a
            // current position whose observation had never been stored.
            locationStateAfterCommit = if (address is WidgetAddress.CurrentLocation) {
                LocationStateWrite.Set(null)
            } else {
                LocationStateWrite.Keep
            },
            // Re-checked *inside* the transaction, not merely before entering it:
            // a stop that lands after the check but before the write must still
            // not produce a snapshot the replacement run is about to supersede.
            isStillValid = { !isCancelled() },
        )

        if (committed != WidgetWriteResult.Written) {
            WidgetLog.info(
                context,
                "write not committed source=${address.sourceIdentifier} " +
                    "result=${committed.name.lowercase()}",
            )
            return when (committed) {
                WidgetWriteResult.Failed -> WidgetRefreshResult.Failed
                WidgetWriteResult.Superseded -> WidgetRefreshResult.Superseded
                WidgetWriteResult.Written -> WidgetRefreshResult.Refreshed
            }
        }

        if (forecastToken != null) {
            refreshForecast(location, forecastToken, answeredDemandVersion, isCancelled)
        }
        return WidgetRefreshResult.Refreshed
    }

    /**
     * The forecast for a township, committed under the token reserved at the
     * start of the same refresh.
     *
     * A forecast failure never downgrades the current-weather result: the
     * observation is already committed, and the layout hides a forecast it
     * cannot trust while continuing to show the observation.
     *
     * The decision to fetch at all is made **here**, after the position
     * resolved, and not before the tickets were reserved. A cached forecast can
     * look perfectly usable — matching township, inside its deadline — and still
     * belong to the township the device has just left. The cache only knew the
     * township of the *previous* observation, so asking it whether "the"
     * forecast is usable answers a question about A while this refresh is about
     * B, and B is then left with no forecast until the next period. The ticket
     * is reserved before the position so that a `clear` cannot slip between the
     * two; whether it is spent is decided once the township is known.
     */
    private fun refreshForecast(
        location: ResolvedWeatherLocation,
        token: WidgetWriteToken,
        answeredDemandVersion: Long?,
        isCancelled: () -> Boolean,
    ) {
        // A forecast for the township this round resolved to, still inside its
        // recorded deadline, is already what the widget needs.
        val cached = store.readForecast(location.address)
        if (cached != null && cached.forecast.regionCode == location.regionCode) {
            val calibratedNow = calibratedNowMilliseconds()
            if (calibratedNow != null && calibratedNow < cached.expiresAtMilliseconds) {
                WidgetLog.debug(
                    context,
                    "forecast kept region=${location.regionCode}",
                )
                // The cache *is* the answer to the demand this run was dispatched
                // for, so retire it here. `commitForecast` is the only other place
                // that clears it and this return never reaches it; left raised, the
                // flag survives every later options change and keeps reserving a
                // ticket for a forecast that is already stored.
                //
                // Not guarded by `isCancelled`, unlike the commit: what answers
                // the demand here is the stored forecast, which this run neither
                // produced nor can lose. A stopped run leaves it just as answered.
                if (answeredDemandVersion != null) {
                    store.clearAnsweredForecastDemand(
                        address = location.address,
                        answeredDemandVersion = answeredDemandVersion,
                        updatedAt = nowMilliseconds(),
                    )
                }
                return
            }
        }

        if (isCancelled()) {
            WidgetLog.info(
                context,
                "refresh stopped source=${token.sourceIdentifier} before its forecast",
            )
            return
        }

        val remote = try {
            fetchForecast(location.regionCode)
        } catch (error: Exception) {
            WidgetLog.warning(
                context,
                "forecast failed region=${location.regionCode} error=${error.logName()}",
            )
            return
        }
        if (remote.points.isEmpty()) return

        // The stop can land while this fetch is in flight too.
        if (isCancelled()) {
            WidgetLog.info(
                context,
                "refresh stopped source=${token.sourceIdentifier} after its forecast fetch",
            )
            return
        }

        val receivedAt = nowMilliseconds()
        // Read *after* the response, not before the request: the receipt is when
        // the answer arrived, and a fetch that crosses a Taipei hour would
        // otherwise be dated to a moment that has already expired.
        val receivedCalibrated = calibratedNowMilliseconds()
            ?: return
        val snapshot = ForecastSnapshot(
            schemaVersion = WidgetSnapshotDecoder.forecastSchemaVersion,
            sourceIdentifier = token.sourceIdentifier,
            regionCode = location.regionCode,
            updateTime = remote.updateTime,
            receivedAt = receivedAt,
            points = remote.points,
        )
        // The receipt is fixed in *calibrated* time now, and so is the deadline
        // derived from it. A later refresh's offset must never be applied to this
        // historical receipt: doing so is what let an expired forecast come back
        // after the device clock moved.
        val expiresAt = WidgetDeadlines.forecastExpiry(
            updateTimeMilliseconds = remote.updateTime,
            receivedCalibratedMilliseconds = receivedCalibrated,
        )
        // The demand is cleared by the commit itself, in the same transaction
        // and only if its version still matches — see `WidgetStore.commitForecast`.
        // `isStillValid` is what stops a *stopped* run clearing the demand the
        // run that replaced it is about to answer.
        store.commitForecast(
            token = token,
            forecast = snapshot,
            receivedCalibratedMilliseconds = receivedCalibrated,
            expiresAtMilliseconds = expiresAt,
            writtenAt = receivedAt,
            answeredDemandVersion = answeredDemandVersion,
            isStillValid = { !isCancelled() },
        )
    }

    /** Builds the schema-v7 snapshot, identically to the iOS factory. */
    fun snapshot(
        observation: RemoteCurrentWeather,
        location: ResolvedWeatherLocation,
        time: WidgetSnapshotTime,
    ): CurrentWeatherSnapshot {
        val isNight = WidgetSolarTime.isNightAt(
            unixMilliseconds = time.calibratedNowUnixMilliseconds,
            latitude = location.latitude,
            longitude = location.longitude,
        )
        // Seconds, which is the unit `nextDayNightTransitionTime` is stored in
        // on both platforms.
        val nextTransition = WidgetSolarTime.nextDayNightTransitionSecondsAt(
            unixMilliseconds = time.calibratedNowUnixMilliseconds,
            latitude = location.latitude,
            longitude = location.longitude,
        )

        return CurrentWeatherSnapshot(
            schemaVersion = WidgetSnapshotDecoder.currentWeatherSchemaVersion,
            sourceIdentifier = location.address.sourceIdentifier,
            regionCode = location.regionCode,
            regionName = location.regionName,
            observationTime = observation.time,
            stationName = observation.stationName,
            weather = observation.weather,
            weatherCode = observation.weatherCode,
            condition = observation.condition,
            isNight = isNight,
            nextDayNightTransitionTime = nextTransition,
            calibratedTimeOffsetMilliseconds = time.calibratedTimeOffsetMilliseconds,
            temperature = observation.temperature,
            humidity = observation.humidity,
            rain = observation.rain,
            windDirection = observation.windDirection,
            windSpeed = observation.windSpeed,
            apparentTemperature = currentApparentTemperature(
                temperature = observation.temperature,
                humidity = observation.humidity,
                windSpeed = observation.windSpeed,
            ),
        )
    }

    companion object {
        /**
         * The production wiring: real store, real location, real clock, real
         * HTTP. Every collaborator is behind a lambda so a test can replace the
         * one it needs without a device or a network.
         */
        fun create(context: Context): WidgetRefreshService {
            val applicationContext = context.applicationContext
            val store = WidgetStore.open(applicationContext)
            return WidgetRefreshService(
                context = applicationContext,
                store = store,
                resolveAddress = { address -> resolve(applicationContext, store, address) },
                synchronizeClock = { WidgetClock.synchronize() },
                snapshotTime = { WidgetClock.snapshotTime() },
                fetchWeather = { latitude, longitude ->
                    WidgetHttp.fetchCurrentWeather(latitude, longitude)
                },
                fetchForecast = { regionCode -> WidgetHttp.fetchForecast(regionCode) },
                nowMilliseconds = { System.currentTimeMillis() },
            )
        }

        /**
         * The address's query point.
         *
         * A saved town comes from the published catalog and needs no permission.
         * A Current Location is a fix whose age and accuracy were validated, then
         * a township resolved from the whole uncertainty circle; every failure
         * mode becomes a named degradation rather than a substitute location.
         */
        private fun resolve(
            context: Context,
            store: WidgetStore,
            address: WidgetAddress,
        ): LocationResolution {
            return when (address) {
                is WidgetAddress.Saved -> {
                    val catalog = store.findCatalogLocation(address.regionCode)
                    if (catalog == null) {
                        WidgetLog.warning(context, "saved location missing region=${address.regionCode}")
                        LocationResolution.Unavailable
                    } else {
                        ResolvedWeatherLocation.create(
                            address = address,
                            regionCode = catalog.regionCode,
                            regionName = catalog.displayName,
                            latitude = catalog.latitude,
                            longitude = catalog.longitude,
                        )?.let { LocationResolution.Resolved(it) }
                            ?: LocationResolution.Unavailable
                    }
                }

                WidgetAddress.CurrentLocation -> when (val fix = WidgetLocationFix.acquire(context)) {
                    is WidgetLocationFixResult.Acquired -> {
                        val resolver = WidgetTownshipResolver.load(context)
                        val resolved = resolver?.resolve(fix.fix)
                        if (resolved == null) {
                            // In no township, or the uncertainty crosses a
                            // boundary: no township can be claimed for it.
                            WidgetLog.warning(
                                context,
                                "township unresolved accuracy=${fix.fix.accuracyMeters.toInt()}m",
                            )
                            LocationResolution.Degraded(
                                WidgetLocationDegradation.UnresolvedTownship,
                            )
                        } else {
                            WidgetLog.info(
                                context,
                                "position fix accepted region=${resolved.regionCode} " +
                                    "accuracy=${fix.fix.accuracyMeters.toInt()}m " +
                                    "age=${fix.fix.ageMilliseconds / 1_000}s",
                            )
                            LocationResolution.Resolved(resolved)
                        }
                    }

                    else -> LocationResolution.Degraded(fix.degradation!!)
                }
            }
        }
    }
}
