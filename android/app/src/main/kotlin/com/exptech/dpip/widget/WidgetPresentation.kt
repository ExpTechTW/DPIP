package com.exptech.dpip.widget

import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Which of the three layouts an instance's measured size selects. */
enum class WidgetSizeClass { Small, Medium, Large }

/** The state the layout has to express, in one value. */
enum class WidgetDisplayState {
    /** No snapshot has ever been published for this address. */
    NoData,

    /** The instance's saved town is no longer in the catalog. */
    Reconfigure,

    /** Location permission or services need user attention before a new fix. */
    NeedsApp,

    /** A position could not be established, but another refresh can retry it. */
    LocationUnavailable,

    /** A cached observation is on screen. */
    Ready,
}

/** One hourly forecast column, already formatted. */
data class ForecastPresentation(
    val time: String,
    val temperatureText: String,
    /**
     * The probability of precipitation as a percentage, or `—` when the point
     * carries none. Never null: iOS draws a dash rather than dropping the line,
     * and the medium layout's whole purpose is the four-line forecast.
     */
    val popText: String,
    val condition: WeatherCondition,
    val isNight: Boolean,
)

/**
 * Everything the layouts draw, already decided.
 *
 * Kept apart from the `RemoteViews` mapping so the decisions that matter — is
 * this observation stale, is this glyph a moon, is this forecast still inside
 * its expiry — are exercised by plain JVM tests with no launcher, no locale and
 * no resource table involved.
 *
 * The shape of the value is the shape of the iOS layout
 * (`ios/DPIPWidgets/DPIPWidgets.swift`): one temperature, one apparent
 * temperature, one condition glyph and name, and the humidity / rainfall / wind
 * / station / sun readings as separate fragments rather than one joined string,
 * so the large layout can place each in its own grid cell the way iOS does.
 */
data class WidgetPresentation(
    val sizeClass: WidgetSizeClass,
    /**
     * Whether [WidgetSizeClass.Small] must use the 110 dp compact layout.
     *
     * The normal square layout is the iOS one, budgeted for a ~120x172 dp
     * launcher cell; the compact layout is the metadata's own 110x110 minimum,
     * which cannot hold it. Only meaningful for `Small`.
     */
    val compactLayout: Boolean,
    val state: WidgetDisplayState,
    /** Whether an observation is on screen, as opposed to the empty face. */
    val hasObservation: Boolean,
    val locationName: String?,
    /** A Current Location widget shows `location.fill` beside its town. */
    val isCurrentLocation: Boolean,
    val isStale: Boolean,
    val badgeText: String?,
    val hintText: String?,
    val observationTimeMillis: Long?,
    /** A configured source that can be retried without opening the app. */
    val canRefresh: Boolean,
    val temperatureText: String?,
    val apparentText: String?,
    val weatherText: String?,
    val condition: WeatherCondition?,
    val isNight: Boolean,
    /** The small layout's metric row and the large grid's first cell. */
    val humidityText: String?,
    /** The small layout's metric row and the large grid's second cell. */
    val rainText: String?,
    val windText: String?,
    val stationText: String?,
    /** `Sunrise` or `Sunset`, depending on the phase the snapshot names. */
    val sunLabel: String?,
    val sunValue: String?,
    val forecast: List<ForecastPresentation>,
    /**
     * The box the launcher reported, in dp, and the system font scale.
     *
     * Carried so the size class and compact fallback are decided from the
     * measured box rather than the cell count, which is launcher-defined.
     */
    val availableWidthDp: Int,
    val availableHeightDp: Int,
    val fontScale: Float,
    /** Manual refresh feedback, separate from data staleness and location hints. */
    val refreshFeedback: WidgetRefreshFeedback? = null,
) {
    /** The height the layout budgets are written against. */
    val effectiveHeightDp: Int get() = (availableHeightDp / fontScale).toInt()

    /** The width the layout budgets are written against. */
    val effectiveWidthDp: Int get() = (availableWidthDp / fontScale).toInt()

    /** Keep active feedback visible even if a location now needs app attention. */
    val showRefresh: Boolean
        get() = when (refreshFeedback) {
            WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running -> true
            else -> canRefresh &&
                (refreshFeedback == WidgetRefreshFeedback.Failed ||
                    !hasObservation || isStale || state == WidgetDisplayState.LocationUnavailable ||
                    (sizeClass != WidgetSizeClass.Small && forecast.isEmpty()))
        }
}

/** The localized labels the presentation composes, injected so tests are hermetic. */
data class WidgetStrings(
    val stale: String,
    val noData: String,
    val openApp: String,
    val needsApp: String,
    val reconfigure: String,
    val humidity: String,
    val rain: String,
    val wind: String,
    val station: String,
    val sunrise: String,
    val sunset: String,
    val apparent: String,
    val currentLocation: String,
    val locationDisabled: String,
    val locationUnavailable: String,
    val locationOutside: String,
)

/**
 * Turns stored data into the screen, applying the rules iOS applies.
 *
 * Four of these rules are the difference between a widget that is merely
 * plausible and one that is correct:
 *
 * 1. **Freshness is decided against an injected calibrated instant.** The
 *    presenter never reads a clock. It is handed the instant the caller trusts —
 *    from `WidgetClock`, which derives it from a monotonic anchor — so a device
 *    whose date was just changed cannot make an old observation look fresh, and
 *    a test can place "now" anywhere without touching a system clock.
 * 2. **No trusted instant means no claim of freshness.** A null calibrated now
 *    (a process that has not synchronized) marks the observation outdated and
 *    hides the forecast, because neither can be shown to be current. That is
 *    the explicit degradation, not a device-time guess.
 * 3. **The forecast is expired, not just present.** An entry past
 *    `published + 30 min` or the next Taipei hour is hidden and the current
 *    observation stays, exactly as iOS does.
 * 4. **A forecast is only shown for the township its current snapshot names.**
 *    A late response from a township Current Location has left cannot be
 *    paired with the new township's observation.
 *
 * The observation instant is drawn as the server stamped it. It is *already* a
 * server time, so applying the device→calibrated offset to it would shift a
 * correct reading by exactly the amount the device clock is wrong.
 */
object WidgetPresenter {
    private const val minutesPerDay = 24 * 60
    private const val maximumFutureMinutes = 12 * 60
    private val taipei = ZoneOffset.ofHours(8)
    private val hourMinute = DateTimeFormatter.ofPattern("HH:mm", Locale.ROOT)
    private val observationDateTime = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm", Locale.ROOT)

    /** The default budget when a caller does not report a measured box. */
    const val defaultAvailableHeightDp = 110

    /**
     * Which layout a measured size can actually hold.
     *
     * Height decides, not the cell count, and the thresholds are the layouts'
     * own budgets rather than round numbers:
     *
     * * Below [minimumWidthDp] the two-row layout's current-weather row and its
     *   five forecast columns cannot be read, so the square layout is used.
     * * A two-row layout needs [mediumMinimumHeightDp] for its header, current
     *   row, notice and the four-line hourly columns; anything shorter is the
     *   square layout, which fits.
     * * The large layout adds the detail grid below the columns, hence
     *   [largeMinimumHeightDp].
     *
     * A larger system font needs proportionally more height for the same rows,
     * so the budgets are compared against the size the box *would* have at the
     * default font scale. Without this the only way to respect a large font
     * would be to render clipped text.
     */
    fun sizeClass(
        widthDp: Int,
        heightDp: Int,
        fontScale: Float = 1f,
    ): WidgetSizeClass {
        val effectiveWidth = (widthDp / fontScale.coerceAtLeast(0.5f)).toInt()
        val effectiveHeight = (heightDp / fontScale.coerceAtLeast(0.5f)).toInt()
        return when {
            effectiveWidth < minimumWidthDp -> WidgetSizeClass.Small
            effectiveHeight < mediumMinimumHeightDp -> WidgetSizeClass.Small
            effectiveHeight < largeMinimumHeightDp -> WidgetSizeClass.Medium
            else -> WidgetSizeClass.Large
        }
    }

    /** Below this width the two-row current-weather row cannot be read. */
    const val minimumWidthDp = 200

    /** The shortest height the two-row layout's budget has been measured to fit. */
    const val mediumMinimumHeightDp = 170

    /** Where the large layout's detail grid stops being clipped. */
    const val largeMinimumHeightDp = 320

    /**
     * The height at which the large layout gets iOS's own section spacing back.
     *
     * A ~320 dp large cell cannot carry `spacing: 12` / `spacing: 14` alongside
     * the Android-only notice row without clipping the forecast's probability
     * line; below this the tightened [layout] is used instead. A real 4x4 cell
     * reports about 344 dp, which gets the iOS spacing.
     */
    const val largeRoomyMinimumHeightDp = 336

    /**
     * Whether the square layout must fall back to its 110 dp compact form.
     *
     * The normal square layout is budgeted for a ~120x172 dp cell; below these
     * floors (the metadata's own 110x110 minimum, or a wide-but-short box a
     * 4x1 cell produces) it cannot hold its header, 42 pt temperature and
     * metric row together, and a launcher would clip the last of them. Both are
     * compared at the default font scale, so a large system font selects the
     * compact form rather than clipped text.
     */
    fun compactLayout(widthDp: Int, heightDp: Int, fontScale: Float = 1f): Boolean {
        val effectiveWidth = (widthDp / fontScale.coerceAtLeast(0.5f)).toInt()
        val effectiveHeight = (heightDp / fontScale.coerceAtLeast(0.5f)).toInt()
        return effectiveWidth < compactWidthDp || effectiveHeight < compactHeightDp
    }

    /** The narrowest box the normal square layout reads in. */
    const val compactWidthDp = 118

    /**
     * ... and the shortest.
     *
     * Measured, not guessed: the normal square layout's header (town, location
     * mark, glyph and condition name), date, optional notice, 42 sp temperature
     * and bounded metric row need 168 dp at the default font scale, including
     * Traditional Chinese / Thai fallback-font extents. The previous
     * 152 dp floor only measured child boxes, not the ancestor-clipped text:
     * with a notice the footer lost up to 28 px at 420 dpi. Visibility tests now
     * cover both sides of this floor and all three observation states. Pixel's
     * 120x172 dp cell stays normal; 118x152 explicitly selects compact.
     */
    const val compactHeightDp = 168

    fun present(
        sizeClass: WidgetSizeClass,
        strings: WidgetStrings,
        address: WidgetAddress?,
        locationName: String?,
        stored: StoredCurrentWeather?,
        forecast: StoredForecast?,
        locationDegradation: WidgetLocationDegradation?,
        isCatalogMember: Boolean,
        calibratedNowMilliseconds: Long?,
        latitude: Double?,
        longitude: Double?,
        availableWidthDp: Int = minimumWidthDp,
        availableHeightDp: Int = defaultAvailableHeightDp,
        fontScale: Float = 1f,
    ): WidgetPresentation {
        val compactLayout = sizeClass == WidgetSizeClass.Small &&
            compactLayout(availableWidthDp, availableHeightDp, fontScale)
        val supportsForecast = sizeClass != WidgetSizeClass.Small
        val snapshot = stored?.snapshot
        val isCurrentLocation = address is WidgetAddress.CurrentLocation
        val canRefresh = canRefresh(address, locationDegradation, isCatalogMember)
        val degraded = isCurrentLocation && locationDegradation != null
        val locationState = if (canRefresh) WidgetDisplayState.LocationUnavailable else WidgetDisplayState.NeedsApp

        // A saved address whose town has left the catalog is a reconfigure, not
        // a blank: the user's choice is gone and only they can remake it.
        if (address is WidgetAddress.Saved && !isCatalogMember) {
            return empty(
                sizeClass = sizeClass,
                compactLayout = compactLayout,
                state = WidgetDisplayState.Reconfigure,
                isCurrentLocation = isCurrentLocation,
                locationName = null,
                badgeText = strings.reconfigure,
                hintText = strings.openApp,
                availableWidthDp = availableWidthDp,
                availableHeightDp = availableHeightDp,
                fontScale = fontScale,
                canRefresh = false,
            )
        }

        if (snapshot == null) {
            return empty(
                sizeClass = sizeClass,
                compactLayout = compactLayout,
                state = if (degraded) locationState else WidgetDisplayState.NoData,
                isCurrentLocation = isCurrentLocation,
                locationName = locationName,
                badgeText = if (degraded) {
                    degradationText(strings, locationDegradation)
                } else {
                    strings.noData
                },
                hintText = if (degraded && canRefresh) null else strings.openApp,
                availableWidthDp = availableWidthDp,
                availableHeightDp = availableHeightDp,
                fontScale = fontScale,
                canRefresh = canRefresh,
            )
        }

        // Without a trusted instant, neither freshness nor expiry can be
        // established. Claiming freshness would be a guess; claiming staleness
        // is the safe direction and is what the badge says.
        val calibratedNow = calibratedNowMilliseconds
        val isStale = calibratedNow == null ||
            calibratedNow >= WidgetDeadlines.staleness(snapshot)
        val transition = WidgetDeadlines.dayNight(snapshot)?.takeIf { it > 0 }
        val transitionPassed = calibratedNow != null && transition != null && calibratedNow >= transition
        // The cached crossing describes one event, not a recurring clock time.
        // Once it passes, recompute both the phase and the next event from the
        // same instant and coordinates. Flipping just the label would turn a
        // cached sunset into "sunrise 18:00", and a single flip also fails when
        // an offline snapshot survives more than one day/night cycle.
        val isNight: Boolean
        val nextTransition: Long
        if (transitionPassed && calibratedNow != null && latitude != null && longitude != null) {
            isNight = WidgetSolarTime.isNightAt(calibratedNow, latitude, longitude)
            nextTransition = WidgetSolarTime.nextDayNightTransitionSecondsAt(calibratedNow, latitude, longitude)
        } else {
            isNight = if (calibratedNow == null) snapshot.isNight else isNight(snapshot, calibratedNow)
            // No coordinates means the next event is unknown, not the old one
            // relabeled. An untrusted clock still keeps the snapshot's event.
            nextTransition = if (transitionPassed) 0L else snapshot.nextDayNightTransitionTime
        }

        val forecastPoints = if (supportsForecast && calibratedNow != null) {
            usableForecast(forecast, snapshot, calibratedNow)
                ?.let { upcoming(it.points, calibratedNow, limit = 5) }
                .orEmpty()
        } else {
            emptyList()
        }

        val displayState = if (degraded) locationState else WidgetDisplayState.Ready

        val badge = when {
            // An aged observation outranks the position notice: it is the fact
            // that matters most about what is on screen.
            isStale -> strings.stale
            degraded -> degradationText(strings, locationDegradation)
            else -> null
        }

        val windSpeed = snapshot.windSpeed
        val windDirection = snapshot.windDirection?.takeIf { it.isNotBlank() }

        return WidgetPresentation(
            sizeClass = sizeClass,
            compactLayout = compactLayout,
            state = displayState,
            hasObservation = true,
            locationName = locationName ?: strings.currentLocation,
            isCurrentLocation = isCurrentLocation,
            isStale = isStale,
            badgeText = badge,
            hintText = null,
            // Already a server instant: no device→calibrated correction applies.
            observationTimeMillis = snapshot.observationTime * 1_000,
            canRefresh = canRefresh,
            temperatureText = snapshot.temperature?.let(::temperatureText)
                ?: if (sizeClass == WidgetSizeClass.Small) "--°" else "—°",
            apparentText = snapshot.apparentTemperature?.let {
                "${strings.apparent} ${temperatureText(it)}"
            },
            weatherText = snapshot.weather,
            condition = snapshot.condition,
            isNight = isNight,
            // A null reading is drawn as its placeholder, not dropped: iOS shows
            // `--%` and `-- mm`, and the large grid keeps its labels either way.
            humidityText = snapshot.humidity?.let { "$it%" } ?: "--%",
            rainText = snapshot.rain?.let(::rainMeasurement) ?: "-- mm",
            windText = when {
                windSpeed != null ->
                    (windDirection?.let { "$it " } ?: "") + speedText(windSpeed)
                windDirection != null -> windDirection
                else -> "--"
            },
            stationText = snapshot.stationName.ifBlank { "--" },
            sunLabel = if (isNight) strings.sunrise else strings.sunset,
            sunValue = sunValue(nextTransition),
            forecast = forecastPoints.map { point ->
                ForecastPresentation(
                    time = point.time,
                    temperatureText = temperatureText(point.temperature),
                    popText = point.pop?.let { "$it%" } ?: "—",
                    condition = point.condition,
                    isNight = isNightAtHour(
                        point,
                        calibratedNow ?: snapshot.observationTime * 1_000,
                        latitude,
                        longitude,
                    ),
                )
            },
            availableWidthDp = availableWidthDp,
            availableHeightDp = availableHeightDp,
            fontScale = fontScale,
        )
    }

    /** A failed fix can recover; permissions and disabled services need user action. */
    private fun canRefresh(
        address: WidgetAddress?,
        degradation: WidgetLocationDegradation?,
        isCatalogMember: Boolean,
    ): Boolean = when (address) {
        null -> false
        is WidgetAddress.Saved -> isCatalogMember
        WidgetAddress.CurrentLocation -> when (degradation) {
            WidgetLocationDegradation.Permission, WidgetLocationDegradation.Disabled -> false
            null, WidgetLocationDegradation.Unavailable, WidgetLocationDegradation.UnusableFix,
            WidgetLocationDegradation.UnresolvedTownship -> true
        }
    }

    /**
     * What to say about a position the app could not establish.
     *
     * Four distinct reasons rather than one: "we have no permission" and "this
     * position is outside the covered area" are different problems with
     * different fixes, and a single "no data" would tell the user neither.
     */
    private fun degradationText(
        strings: WidgetStrings,
        degradation: WidgetLocationDegradation?,
    ): String = when (degradation) {
        null -> strings.needsApp
        WidgetLocationDegradation.Permission -> strings.needsApp
        WidgetLocationDegradation.Disabled -> strings.locationDisabled
        WidgetLocationDegradation.UnusableFix -> strings.locationUnavailable
        WidgetLocationDegradation.UnresolvedTownship -> strings.locationOutside
        WidgetLocationDegradation.Unavailable -> strings.locationUnavailable
    }

    private fun empty(
        sizeClass: WidgetSizeClass,
        compactLayout: Boolean,
        state: WidgetDisplayState,
        isCurrentLocation: Boolean,
        locationName: String?,
        badgeText: String?,
        hintText: String?,
        canRefresh: Boolean,
        availableWidthDp: Int = minimumWidthDp,
        availableHeightDp: Int = defaultAvailableHeightDp,
        fontScale: Float = 1f,
    ) = WidgetPresentation(
        sizeClass = sizeClass,
        compactLayout = compactLayout,
        state = state,
        hasObservation = false,
        locationName = locationName,
        isCurrentLocation = isCurrentLocation,
        isStale = false,
        badgeText = badgeText,
        hintText = hintText,
        observationTimeMillis = null,
        canRefresh = canRefresh,
        temperatureText = null,
        apparentText = null,
        weatherText = null,
        condition = null,
        isNight = false,
        humidityText = null,
        rainText = null,
        windText = null,
        stationText = null,
        sunLabel = null,
        sunValue = null,
        forecast = emptyList(),
        availableWidthDp = availableWidthDp,
        availableHeightDp = availableHeightDp,
        fontScale = fontScale,
    )

    /**
     * The snapshot's own day/night, advanced past its recorded transition.
     *
     * A snapshot carries one transition ahead; once calibrated time passes it
     * the phase flips without a fresh publish, which is what makes a cached
     * clear-sky snapshot show a moon the moment the sun sets.
     */
    private fun isNight(snapshot: CurrentWeatherSnapshot, calibratedNowMilliseconds: Long): Boolean {
        val transition = WidgetDeadlines.dayNight(snapshot) ?: return snapshot.isNight
        return if (calibratedNowMilliseconds >= transition) !snapshot.isNight else snapshot.isNight
    }

    /**
     * The forecast, or null when it is expired or belongs to another township.
     */
    private fun usableForecast(
        forecast: StoredForecast?,
        snapshot: CurrentWeatherSnapshot,
        calibratedNowMilliseconds: Long,
    ): StoredForecast? {
        if (forecast == null) return null
        if (forecast.regionCode != snapshot.regionCode) return null
        if (forecast.forecast.address != snapshot.address) return null
        if (forecast.points.isEmpty()) return null

        // The deadline recorded when the response was accepted. Recomputing it
        // here from the *snapshot's* offset would apply a correction measured
        // long after the receipt, and a device clock adjustment in between would
        // move an expired entry back into the future.
        return if (calibratedNowMilliseconds < forecast.expiresAtMilliseconds) forecast else null
    }

    /**
     * The next [limit] points, by clock distance from the calibrated instant.
     *
     * A label is a Taipei wall-clock reading with no date, so a label already
     * passed may mean tomorrow — but only inside a short horizon. Past it, the
     * label is too ambiguous to draw and is dropped. The current minute stays
     * eligible. Ties keep API order.
     */
    fun upcoming(
        points: List<ForecastPoint>,
        calibratedNowMilliseconds: Long,
        limit: Int,
    ): List<ForecastPoint> {
        if (limit <= 0) return emptyList()
        val local = LocalDateTime.ofInstant(
            Instant.ofEpochMilli(calibratedNowMilliseconds),
            taipei,
        )
        val currentMinutes = local.hour * 60 + local.minute

        return points.withIndex()
            .mapNotNull { (index, point) ->
                val forecastMinutes = point.minutesSinceMidnight ?: return@mapNotNull null
                val distance = (forecastMinutes - currentMinutes + minutesPerDay) % minutesPerDay
                if (distance > maximumFutureMinutes) return@mapNotNull null
                Triple(distance, index, point)
            }
            .sortedWith(compareBy({ it.first }, { it.second }))
            .take(limit)
            .map { it.third }
    }

    /**
     * The glyph's night form, from the local hour the point names.
     *
     * The day only sets the season and sunrise moves about a minute a day, so a
     * point that actually belongs to tomorrow still resolves correctly — the
     * same reasoning as Dart's `isNightHour`.
     */
    private fun isNightAtHour(
        point: ForecastPoint,
        calibratedNowMilliseconds: Long,
        latitude: Double?,
        longitude: Double?,
    ): Boolean {
        val minutes = point.minutesSinceMidnight ?: return false
        val lat = latitude ?: return false
        val lng = longitude ?: return false
        val times = WidgetSolarTime.sunSeconds(calibratedNowMilliseconds, lat, lng)
        val seconds = minutes * 60
        return seconds < times.sunrise || seconds >= times.sunset
    }

    /**
     * The next day/night transition as a Taipei wall clock, or `--`.
     *
     * iOS draws the same instant with `.time` and labels it sunrise or sunset by
     * phase. The snapshot carries it in calibrated seconds; a non-positive value
     * is the "unknown" the app writes rather than a real crossing.
     */
    private fun sunValue(transitionSeconds: Long): String {
        // 9999-12-31T23:59:59Z; anything past it is the app's "unknown", not a
        // real crossing, and formatting it would overflow `LocalDateTime`.
        if (transitionSeconds <= 0 || transitionSeconds > 253_402_300_799L) return "--"
        return LocalDateTime.ofInstant(
            Instant.ofEpochSecond(transitionSeconds),
            taipei,
        ).format(hourMinute)
    }

    private fun temperatureText(value: Double): String = "${Math.round(value)}°"

    private fun rainMeasurement(value: Double): String =
        String.format(Locale.getDefault(), "%.1f mm", value)

    private fun speedText(value: Double): String =
        String.format(Locale.getDefault(), "%.1f m/s", value)

    /** The original observation instant as a fixed 24-hour Taipei wall clock. */
    fun observationText(observationMilliseconds: Long): String =
        LocalDateTime.ofInstant(Instant.ofEpochMilli(observationMilliseconds), taipei).format(hourMinute)

    /** Keep the full date accessible even though every visual header uses HH:mm. */
    fun observationDescription(observationMilliseconds: Long): String =
        LocalDateTime.ofInstant(Instant.ofEpochMilli(observationMilliseconds), taipei).format(observationDateTime)
}
