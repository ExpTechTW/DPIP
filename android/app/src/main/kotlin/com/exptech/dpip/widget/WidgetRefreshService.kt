package com.exptech.dpip.widget

import android.content.Context

/** The outcome of one refresh, mirroring `CurrentWeatherWidgetRefreshResult`. */
enum class WidgetRefreshResult {
    Refreshed,
    Superseded,
    NoObservation,
    Unavailable,
    Failed,
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
 * One refresh of one address: acquire, calibrate, resolve, fetch, commit.
 *
 * The shape is iOS's `CurrentWeatherWidgetRefreshPipeline` plus the resolution
 * in front of it, with three rules that are the difference between a correct
 * widget and a subtly wrong one:
 *
 * * **The acquisition number is taken first**, ahead of the clock exchange, the
 *   location fix and the fetch. It is the refresh's place in line against a
 *   snapshot the app publishes meanwhile (see `WidgetStore`); taken after the
 *   fix, a position from before a move could outrank the township the app has
 *   since published.
 * * **The clock does not wait for the position.** A device that grants only
 *   foreground location still has a fresh observation published by the app,
 *   and the screen can only judge it fresh if the process holds a calibrated
 *   anchor. Calibrating after the position meant a degraded fix returned first
 *   and every screen then said "outdated" for ever.
 * * **The forecast is decided after the position resolves.** A cached forecast
 *   can look usable — matching township, inside its deadline — and still belong
 *   to the township the device has just left; only the resolved township can
 *   answer whether it is the right one.
 *
 * Dependencies are injected so the ordering is testable with a controllable
 * fetcher. Blocking by design: it runs on a WorkManager worker thread, never on
 * the main thread.
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
    fun refresh(address: WidgetAddress): WidgetRefreshResult {
        val acquisition = store.beginAcquisition(address)
        if (acquisition == null) {
            WidgetLog.error(context, "refresh rejected source=${address.sourceIdentifier} reason=no-acquisition")
            return WidgetRefreshResult.Failed
        }

        // ── Calibration, before the position ──
        //
        // A failure is not a reason to stop: an anchor from an earlier sync —
        // this process's or the one restored from disk — still answers, and
        // with none at all the observation is still fetched and committed
        // (below) rather than thrown away.
        val calibrated = synchronizeClock()
        if (!calibrated) WidgetLog.warning(context, "clock unavailable source=${address.sourceIdentifier}")

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
                // Recorded now, so the reason is on screen even though nothing
                // is committed; the cached observation stays.
                store.writeLocationState(address, resolution.degradation, nowMilliseconds())
                WidgetLog.warning(
                    context,
                    "position degraded source=${address.sourceIdentifier} " +
                        "reason=${resolution.degradation.wire}",
                )
                return WidgetRefreshResult.Unavailable
            }

            LocationResolution.Unavailable -> {
                WidgetLog.warning(context, "position unavailable source=${address.sourceIdentifier}")
                return WidgetRefreshResult.Unavailable
            }
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

        // With no anchor at all the observation's own server instant stands in
        // for "now": it decides only the day/night glyph, and the screen still
        // calls the reading unverified until a clock is anchored.
        val time = snapshotTime() ?: WidgetSnapshotTime(observation.time * 1_000, 0)
        val committed = store.commitCurrentWeather(
            snapshot = snapshot(observation, location, time),
            writtenAt = nowMilliseconds(),
            acquisition = acquisition,
            // Only a commit that lands may declare the position trustworthy:
            // clearing it as soon as a fix was obtained left a widget claiming a
            // current position whose observation had never been stored.
            locationStateAfterCommit = if (address is WidgetAddress.CurrentLocation) {
                LocationStateWrite.Set(null)
            } else {
                LocationStateWrite.Keep
            },
        )
        if (committed != WidgetWriteResult.Written) {
            WidgetLog.info(
                context,
                "write not committed source=${address.sourceIdentifier} result=${committed.name.lowercase()}",
            )
            return if (committed == WidgetWriteResult.Failed) WidgetRefreshResult.Failed else WidgetRefreshResult.Superseded
        }

        refreshForecast(location)
        // Committed, but with no anchor the screen cannot call it fresh: a
        // bounded retry is the quickest way to an anchor.
        return if (calibrated) WidgetRefreshResult.Refreshed else WidgetRefreshResult.Failed
    }

    /**
     * The forecast for the township this round resolved to.
     *
     * Fetched for every address, whatever size its instances are: a forecast
     * lives for at most an hour, and having it already is what lets a resize to
     * a wider cell draw it at once. A forecast failure never downgrades the
     * current-weather result — the observation is already committed, and the
     * layout hides a forecast it cannot trust while continuing to show it.
     */
    private fun refreshForecast(location: ResolvedWeatherLocation) {
        val cached = store.readForecast(location.address)
        val calibratedNow = calibratedNowMilliseconds()
        if (cached != null && cached.forecast.regionCode == location.regionCode &&
            calibratedNow != null && calibratedNow < cached.expiresAtMilliseconds
        ) {
            WidgetLog.debug(context, "forecast kept region=${location.regionCode}")
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

        val receivedAt = nowMilliseconds()
        // Read *after* the response, not before the request: the receipt is when
        // the answer arrived, and a fetch that crosses a Taipei hour would
        // otherwise be dated to a moment that has already expired.
        val receivedCalibrated = calibratedNowMilliseconds() ?: return
        // The deadline is fixed in calibrated time now. A later refresh's offset
        // must never be applied to this historical receipt: doing so is what let
        // an expired forecast come back after the device clock moved.
        store.commitForecast(
            forecast = ForecastSnapshot(
                schemaVersion = WidgetSnapshotDecoder.forecastSchemaVersion,
                sourceIdentifier = location.address.sourceIdentifier,
                regionCode = location.regionCode,
                updateTime = remote.updateTime,
                receivedAt = receivedAt,
                points = remote.points,
            ),
            receivedCalibratedMilliseconds = receivedCalibrated,
            expiresAtMilliseconds = WidgetDeadlines.forecastExpiry(
                updateTimeMilliseconds = remote.updateTime,
                receivedCalibratedMilliseconds = receivedCalibrated,
            ),
            writtenAt = receivedAt,
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
            WidgetClock.attach(applicationContext)
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
