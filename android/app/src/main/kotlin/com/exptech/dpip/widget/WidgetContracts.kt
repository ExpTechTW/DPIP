package com.exptech.dpip.widget

/**
 * The values the native Widget shares with Dart and with its own storage.
 *
 * Everything here is a fact about the cross-platform contract, so it is stated
 * once and derived nowhere else. `lib/features/weather/domain/
 * current_weather_widget_snapshot.dart` (schema v7), `lib/core/platform/
 * widget_location_catalog.dart` (schema v1) and the iOS
 * `ForecastWidgetSnapshot` (schema v1) are the other halves; the fixtures under
 * `android/app/src/test/resources` are copies of real payloads, and the decoder
 * tests are what keep this file honest.
 */
enum class WidgetSnapshotKind(val wire: String) {
    CurrentWeather("currentWeather"),
    WeatherForecast("weatherForecast"),
    LocationCatalog("locationCatalog"),
    ;

    companion object {
        fun fromWire(value: String?): WidgetSnapshotKind? =
            entries.firstOrNull { it.wire == value }
    }
}

/**
 * Dart's `CurrentWeatherWidgetCondition`, spelled the same in the payload.
 *
 * The coarse meaning is versioned here. [WidgetWeatherCondition] derives the
 * finer glyph at render time, so this enum does not need a case per icon.
 */
enum class WeatherCondition(val wire: String) {
    Clear("clear"),
    Cloudy("cloudy"),
    Overcast("overcast"),
    Rain("rain"),
    Thunderstorm("thunderstorm"),
    Snow("snow"),
    Fog("fog"),
    Unknown("unknown"),
    ;

    companion object {
        fun fromWire(value: String?): WeatherCondition? =
            entries.firstOrNull { it.wire == value }
    }
}

/**
 * Mirrors `weatherConditionForCode` in `lib/core/weather/weather_code.dart`.
 *
 * The suffix (`code % 100`) names the phenomenon and wins; the hundreds family
 * supplies the plain sky only when there is no phenomenon. `106` is therefore
 * rain, not clear. A code `<= 0` is unknown.
 */
fun weatherConditionForCode(code: Int): WeatherCondition {
    if (code <= 0) return WeatherCondition.Unknown
    when (code % 100) {
        1, 2, 5 -> return WeatherCondition.Fog
        3, 4, 14, 15, 16, 17, 18, 19 -> return WeatherCondition.Thunderstorm
        6, 7, 11, 13 -> return WeatherCondition.Rain
        8, 9, 10, 12 -> return WeatherCondition.Snow
        else -> Unit
    }
    return when (code / 100) {
        1 -> WeatherCondition.Clear
        2 -> WeatherCondition.Cloudy
        3 -> WeatherCondition.Overcast
        else -> WeatherCondition.Unknown
    }
}

/**
 * The glyph semantic the Widget draws, finer than [WeatherCondition].
 *
 * Hail, mixed rain and snow, and lightning alone need distinct glyphs but share
 * one coarse condition in the payload, so they are derived at render time rather
 * than persisted. Both the current observation and the hourly forecast use
 * [from], so one code draws one glyph.
 */
enum class WidgetWeatherCondition {
    Clear,
    Cloudy,
    Overcast,
    Fog,
    Rain,
    Sleet,
    Snow,
    Hail,
    Thunder,
    Thunderstorm,
    Unknown,
    ;

    companion object {
        /**
         * Classifies one observation or forecast point.
         *
         * The suffix (`code % 100`) names the phenomenon; the family supplies
         * the plain sky; the text is read only when neither classifies the code.
         */
        fun from(weather: String, weatherCode: Int): WidgetWeatherCondition {
            if (weatherCode > 0) {
                when (weatherCode % 100) {
                    3, 4, 19 -> return Thunder
                    7, 12 -> return Sleet
                    13, 16, 18 -> return Hail
                    15 -> return Snow
                }
            }
            val standard = standard(weatherConditionForCode(weatherCode))
            if (standard != Unknown) return standard

            val hasRain = '雨' in weather
            val hasSnow = '雪' in weather
            if ('雷' in weather && hasRain) return Thunderstorm
            if ('雹' in weather) return Hail
            if (hasRain && hasSnow) return Sleet
            if (!hasSnow && '雷' in weather) return Thunder
            return when {
                hasSnow -> Snow
                hasRain -> Rain
                '霧' in weather || '靄' in weather || '霾' in weather -> Fog
                '晴' in weather -> Clear
                "多雲" in weather -> Cloudy
                '陰' in weather -> Overcast
                else -> Unknown
            }
        }

        private fun standard(condition: WeatherCondition): WidgetWeatherCondition = when (condition) {
            WeatherCondition.Clear -> Clear
            WeatherCondition.Cloudy -> Cloudy
            WeatherCondition.Overcast -> Overcast
            WeatherCondition.Rain -> Rain
            WeatherCondition.Thunderstorm -> Thunderstorm
            WeatherCondition.Snow -> Snow
            WeatherCondition.Fog -> Fog
            WeatherCondition.Unknown -> Unknown
        }
    }
}

/**
 * A Widget instance's address: the app's current position, or one saved town.
 *
 * The wire form is exactly the `sourceIdentifier` Dart and iOS write —
 * `current-location` or `region:<three digits>` — and nothing else is a valid
 * source, so an attacker-supplied identifier can never be turned into a path,
 * a query, or a table key of its own choosing.
 */
sealed interface WidgetAddress {
    val sourceIdentifier: String

    data object CurrentLocation : WidgetAddress {
        override val sourceIdentifier: String = "current-location"
    }

    data class Saved(val regionCode: String) : WidgetAddress {
        override val sourceIdentifier: String get() = "region:$regionCode"
    }

    companion object {
        fun fromSourceIdentifier(value: String?): WidgetAddress? {
            if (value == CurrentLocation.sourceIdentifier) return CurrentLocation
            val prefix = "region:"
            if (value == null || !value.startsWith(prefix)) return null
            val code = value.substring(prefix.length)
            if (!isValidRegionCode(code)) return null
            return Saved(code)
        }
    }
}

/** A township region code: exactly three ASCII digits. */
fun isValidRegionCode(value: String?): Boolean =
    value != null && value.length == 3 && value.all { it in '0'..'9' }

/**
 * One township as Dart published it in the location catalog (schema v1).
 *
 * The coordinates are the township centroid, which is the weather query point
 * for a saved location. They are validated once, here, because an out-of-range
 * coordinate silently becomes a 400 from the weather endpoint otherwise.
 */
data class WidgetCatalogLocation(
    val regionCode: String,
    val displayName: String,
    val administrativeAreaName: String,
    val latitude: Double,
    val longitude: Double,
) {
    companion object {
        fun create(
            regionCode: String?,
            displayName: String?,
            administrativeAreaName: String?,
            latitude: Double?,
            longitude: Double?,
        ): WidgetCatalogLocation? {
            val code = regionCode?.takeIf { isValidRegionCode(it) } ?: return null
            if (displayName == null || displayName.isEmpty()) return null
            if (administrativeAreaName == null) return null
            if (latitude == null || !latitude.isFinite() || latitude !in -90.0..90.0) return null
            if (longitude == null || !longitude.isFinite() || longitude !in -180.0..180.0) return null
            return WidgetCatalogLocation(
                regionCode = code,
                displayName = displayName,
                administrativeAreaName = administrativeAreaName,
                latitude = latitude,
                longitude = longitude,
            )
        }
    }
}

/**
 * The Dart current-weather payload, schema v7.
 *
 * `observationTime` is the source observation, Unix seconds — never the publish
 * time. `calibratedTimeOffsetMilliseconds` is calibrated minus device time, the
 * same sign convention iOS and Dart use, so every freshness decision is made in
 * calibrated time and a device clock change cannot move it.
 */
data class CurrentWeatherSnapshot(
    val schemaVersion: Int,
    val sourceIdentifier: String,
    val regionCode: String,
    val regionName: String,
    val observationTime: Long,
    val stationName: String,
    val weather: String,
    val weatherCode: Int,
    val condition: WeatherCondition,
    val isNight: Boolean,
    val nextDayNightTransitionTime: Long,
    val calibratedTimeOffsetMilliseconds: Long,
    val temperature: Double?,
    val humidity: Int?,
    val rain: Double?,
    val windDirection: String?,
    val windSpeed: Double?,
    val apparentTemperature: Double?,
) {
    val address: WidgetAddress? get() = WidgetAddress.fromSourceIdentifier(sourceIdentifier)
}

/** One hourly forecast point. `time` is an `HH:mm` Taipei clock label, no date. */
data class ForecastPoint(
    val time: String,
    val temperature: Double,
    val weather: String,
    val weatherCode: Int,
    val pop: Int?,
) {
    val condition: WidgetWeatherCondition get() = WidgetWeatherCondition.from(weather, weatherCode)

    /** Minutes since local midnight, or null when the label is not `HH:mm`. */
    val minutesSinceMidnight: Int?
        get() {
            if (time.length != 5 || time[2] != ':') return null
            if (time[0] !in '0'..'9' || time[1] !in '0'..'9') return null
            if (time[3] !in '0'..'9' || time[4] !in '0'..'9') return null
            val hour = (time[0] - '0') * 10 + (time[1] - '0')
            val minute = (time[3] - '0') * 10 + (time[4] - '0')
            if (hour >= 24 || minute >= 60) return null
            return hour * 60 + minute
        }
}

/**
 * The hourly forecast cache entry, schema v1.
 *
 * `updateTime` is the API's publication instant (server clock, Unix
 * milliseconds) and `receivedAt` is when the device accepted the response — the
 * two are compared in calibrated time when the entry is expired, which is why
 * both are kept rather than one derived from the other.
 */
data class ForecastSnapshot(
    val schemaVersion: Int,
    val sourceIdentifier: String,
    val regionCode: String,
    val updateTime: Long,
    val receivedAt: Long,
    val points: List<ForecastPoint>,
) {
    val address: WidgetAddress? get() = WidgetAddress.fromSourceIdentifier(sourceIdentifier)
}

/** A resolved weather query point: which address, which town, which coordinate. */
data class ResolvedWeatherLocation(
    val address: WidgetAddress,
    val regionCode: String,
    val regionName: String,
    val latitude: Double,
    val longitude: Double,
) {
    companion object {
        fun create(
            address: WidgetAddress,
            regionCode: String?,
            regionName: String?,
            latitude: Double?,
            longitude: Double?,
        ): ResolvedWeatherLocation? {
            val code = regionCode?.takeIf { isValidRegionCode(it) } ?: return null
            if (latitude == null || !latitude.isFinite() || latitude !in -90.0..90.0) return null
            if (longitude == null || !longitude.isFinite() || longitude !in -180.0..180.0) return null
            if (address is WidgetAddress.Saved && address.regionCode != code) return null
            return ResolvedWeatherLocation(
                address = address,
                regionCode = code,
                regionName = regionName.orEmpty(),
                latitude = latitude,
                longitude = longitude,
            )
        }
    }
}

/**
 * The forecast cache entry with the instants it was accepted at.
 *
 * `expiresAtMilliseconds` is **absolute and calibrated**, computed once when the
 * entry is committed and then never recomputed. The alternative — deriving it
 * later from the snapshot's device→calibrated offset — is wrong the moment the
 * device clock is adjusted: a fresh offset applied to a *historical* receipt
 * moves an already-expired entry into the future, and a failed forecast refresh
 * would then leave it on screen looking current. The receipt is a fact from the
 * past; only a value recorded at the time can describe it.
 */
data class StoredForecast(
    val forecast: ForecastSnapshot,
    val receivedCalibratedMilliseconds: Long,
    val expiresAtMilliseconds: Long,
) {
    val sourceIdentifier: String get() = forecast.sourceIdentifier
    val regionCode: String get() = forecast.regionCode
    val points: List<ForecastPoint> get() = forecast.points
}

/**
 * Why a Widget instance cannot show the position the user asked for.
 *
 * The plan's explicit degradation, and the reason it is a value rather than a
 * boolean: "we have no permission" and "this position is outside the covered
 * area" need different words on screen. Neither ever turns into a silent
 * substitution of the app's selected saved town.
 */
enum class WidgetLocationDegradation(val wire: String) {
    /** Background location is not granted, so a headless refresh cannot fix. */
    Permission("permission"),

    /** Location services are switched off, or no provider is enabled. */
    Disabled("disabled"),

    /** A fix arrived but was too old or too coarse to call a position. */
    UnusableFix("unusable_fix"),

    /** A fix was obtained, but no township could be resolved from it. */
    UnresolvedTownship("unresolved_township"),

    /** No fix could be obtained at all, and no more specific reason is known. */
    Unavailable("unavailable"),

    ;

    companion object {
        fun fromWire(value: String?): WidgetLocationDegradation? =
            entries.firstOrNull { it.wire == value }
    }
}

/** How a commit should leave an address's stored location degradation. */
sealed interface LocationStateWrite {
    /** Leave whatever is stored. */
    data object Keep : LocationStateWrite

    /** Store [degradation], or clear the row when it is null. */
    data class Set(val degradation: WidgetLocationDegradation?) : LocationStateWrite
}
