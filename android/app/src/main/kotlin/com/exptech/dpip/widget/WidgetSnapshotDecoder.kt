package com.exptech.dpip.widget

/**
 * Decodes the versioned payloads that cross the Flutter boundary.
 *
 * The boundary's job is to be the pessimistic gate: every field is checked
 * before it is allowed to become a value the rest of the Widget reasons about,
 * and anything unrecognised is refused rather than coerced. A snapshot that
 * fails here is not an error the user sees — the caller keeps the previous
 * snapshot — so a strict decoder costs nothing and a lenient one would publish
 * a number the source never said.
 *
 * The size ceiling is checked against the encoded bytes before parsing, so an
 * oversized or hostile payload never reaches the parser at all. iOS uses the
 * same 128 KiB ceiling for the same reason.
 */
object WidgetSnapshotDecoder {
    const val maximumPayloadBytes = 128 * 1024

    /** The Dart `CurrentWeatherWidgetSnapshot` schema this build understands. */
    const val currentWeatherSchemaVersion = 7

    /** The Dart `WidgetLocationCatalog` schema this build understands. */
    const val locationCatalogSchemaVersion = 1

    /** The `ForecastWidgetSnapshot` schema this build understands. */
    const val forecastSchemaVersion = 1

    fun decodeCurrentWeather(json: String): CurrentWeatherSnapshot? {
        if (!withinSizeLimit(json)) return null
        val root = WidgetJsonParser.parse(json)?.objOrNull() ?: return null

        if (root["schemaVersion"]?.intOrNull() != currentWeatherSchemaVersion) return null

        val sourceIdentifier = root["sourceIdentifier"]?.strOrNull() ?: return null
        val address = WidgetAddress.fromSourceIdentifier(sourceIdentifier) ?: return null

        val regionCode = root["regionCode"]?.strOrNull() ?: return null
        if (!isValidRegionCode(regionCode)) return null
        // A saved address names its own town; a payload whose region disagrees
        // would file one town's weather under another's key.
        if (address is WidgetAddress.Saved && address.regionCode != regionCode) return null

        val observationTime = root["observationTime"]?.longOrNull() ?: return null
        if (observationTime <= 0) return null

        val regionName = root["regionName"]?.strOrNull() ?: return null
        val stationName = root["stationName"]?.strOrNull() ?: return null
        val weather = root["weather"]?.strOrNull() ?: return null
        val weatherCode = root["weatherCode"]?.intOrNull() ?: return null
        val isNight = root["isNight"]?.boolOrNull() ?: return null
        val nextTransition = root["nextDayNightTransitionTime"]?.longOrNull() ?: return null
        if (nextTransition < 0) return null
        val calibratedOffset = root["calibratedTimeOffsetMilliseconds"]?.longOrNull() ?: return null

        val condition = root["condition"]?.strOrNull()
            ?.let { WeatherCondition.fromWire(it) }
            ?: WeatherCondition.Unknown

        return CurrentWeatherSnapshot(
            schemaVersion = currentWeatherSchemaVersion,
            sourceIdentifier = sourceIdentifier,
            regionCode = regionCode,
            regionName = regionName,
            observationTime = observationTime,
            stationName = stationName,
            weather = weather,
            weatherCode = weatherCode,
            condition = condition,
            isNight = isNight,
            nextDayNightTransitionTime = nextTransition,
            calibratedTimeOffsetMilliseconds = calibratedOffset,
            temperature = root["temperature"].finiteDoubleOrNull(),
            humidity = root["humidity"]?.intOrNull(),
            rain = root["rain"].finiteDoubleOrNull(),
            windDirection = root["windDirection"]?.strOrNull(),
            windSpeed = root["windSpeed"].finiteDoubleOrNull(),
            apparentTemperature = root["apparentTemperature"].finiteDoubleOrNull(),
        )
    }

    fun decodeLocationCatalog(json: String): List<WidgetCatalogLocation>? {
        if (!withinSizeLimit(json)) return null
        val root = WidgetJsonParser.parse(json)?.objOrNull() ?: return null
        if (root["schemaVersion"]?.intOrNull() != locationCatalogSchemaVersion) return null

        val locations = root["locations"]?.arrOrNull()?.values ?: return null
        val decoded = ArrayList<WidgetCatalogLocation>(locations.size)
        val seen = HashSet<String>()

        for (element in locations) {
            val location = element.objOrNull() ?: return null
            val decodedLocation = WidgetCatalogLocation.create(
                regionCode = location["regionCode"]?.strOrNull(),
                displayName = location["displayName"]?.strOrNull(),
                administrativeAreaName = location["administrativeAreaName"]?.strOrNull(),
                latitude = location["latitude"].finiteDoubleOrNull(),
                longitude = location["longitude"].finiteDoubleOrNull(),
            ) ?: return null
            // Dart's catalog is keyed by region code on the other side too; a
            // duplicate here would make "which row wins" an accident of order.
            if (!seen.add(decodedLocation.regionCode)) return null
            decoded.add(decodedLocation)
        }

        return decoded
    }

    fun decodeForecast(json: String): ForecastSnapshot? {
        if (!withinSizeLimit(json)) return null
        val root = WidgetJsonParser.parse(json)?.objOrNull() ?: return null
        if (root["schemaVersion"]?.intOrNull() != forecastSchemaVersion) return null

        val sourceIdentifier = root["sourceIdentifier"]?.strOrNull() ?: return null
        val address = WidgetAddress.fromSourceIdentifier(sourceIdentifier) ?: return null
        val regionCode = root["regionCode"]?.strOrNull() ?: return null
        if (!isValidRegionCode(regionCode)) return null
        if (address is WidgetAddress.Saved && address.regionCode != regionCode) return null

        val updateTime = root["updateTime"]?.longOrNull() ?: return null
        if (updateTime <= 0) return null
        val receivedAt = root["receivedAt"]?.longOrNull() ?: return null
        if (receivedAt <= 0) return null

        val points = root["points"]?.arrOrNull()?.values ?: return null
        if (points.isEmpty()) return null
        val decodedPoints = ArrayList<ForecastPoint>(points.size)
        for (element in points) {
            decodedPoints.add(decodeForecastPoint(element) ?: return null)
        }

        return ForecastSnapshot(
            schemaVersion = forecastSchemaVersion,
            sourceIdentifier = sourceIdentifier,
            regionCode = regionCode,
            updateTime = updateTime,
            receivedAt = receivedAt,
            points = decodedPoints,
        )
    }

    /**
     * Decodes one point of a `ForecastRemoteDTO`, which is what the native
     * client receives. Dart and iOS write the same shape, so the boundary
     * decoder and the network decoder share it.
     */
    fun decodeForecastPoint(element: WidgetJson): ForecastPoint? {
        val point = element.objOrNull() ?: return null
        val time = point["time"]?.strOrNull() ?: return null
        val temperature = point["temperature"].finiteDoubleOrNull() ?: return null
        val weather = point["weather"]?.strOrNull() ?: return null
        if (weather.isBlank()) return null
        val weatherCode = point["weatherCode"]?.intOrNull() ?: return null

        val decoded = ForecastPoint(
            time = time,
            temperature = temperature,
            weather = weather,
            weatherCode = weatherCode,
            pop = null,
        )
        if (decoded.minutesSinceMidnight == null) return null

        // PoP is optional and only meaningful inside 0–100; anything else is
        // dropped rather than drawn as a percentage.
        val pop = point["pop"]?.intOrNull()
        val validPop = if (pop != null && pop in 0..100) pop else null
        return decoded.copy(pop = validPop)
    }

    private fun withinSizeLimit(json: String): Boolean {
        // UTF-8 bytes, not characters: the ceiling is a memory bound, and a
        // CJK string is three bytes per character.
        var bytes = 0
        for (character in json) {
            bytes += when {
                character.code < 0x80 -> 1
                character.code < 0x800 -> 2
                else -> 3
            }
            if (bytes > maximumPayloadBytes) return false
        }
        return bytes > 0
    }
}

/** A finite `Double` member, or null for absent, null, or non-finite. */
fun WidgetJson?.finiteDoubleOrNull(): Double? = this?.doubleOrNull()
