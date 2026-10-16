package com.exptech.dpip.widget

import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL

/** The subset of `/api/v5/meteor/weather/realtime/:coords` the Widget needs. */
data class RemoteCurrentWeather(
    val stationName: String,
    val time: Long,
    val weather: String,
    val weatherCode: Int,
    val temperature: Double?,
    val humidity: Int?,
    val rain: Double?,
    val windDirection: String?,
    val windSpeed: Double?,
) {
    val condition: WeatherCondition get() = weatherConditionForCode(weatherCode)
}

/** The narrow forecast response: publication time plus clock-labelled points. */
data class RemoteForecast(
    val updateTime: Long,
    val points: List<ForecastPoint>,
)

/**
 * The region-pinned API surface the native Widget is allowed to reach.
 *
 * `api.md` puts both endpoints on `coreExclusiveApi`, whose only node today is
 * `api.core-tnn1.exptech.dev`. The native side cannot call Dart's `ApiClient`,
 * so it would be easy for a Worker to acquire a host of its own — and then for
 * two parts of the app to disagree about failover. The host lives here, once,
 * and the plan's rule is that it is not this file's decision to add a second
 * one: adding a node is an `api.md` change, not a Widget change.
 */
object WidgetApi {
    const val host = "api.core-tnn1.exptech.dev"

    fun currentWeatherUrl(latitude: Double, longitude: Double): String =
        "https://$host/api/v5/meteor/weather/realtime/$latitude,$longitude"

    fun forecastUrl(regionCode: String): String =
        "https://$host/api/v5/meteor/weather/forecast/$regionCode"
}

/** A transport or decode failure. The caller keeps its previous snapshot. */
class WidgetHttpException(message: String) : Exception(message)

/**
 * The two HTTP calls the refresh makes, over `HttpURLConnection`.
 *
 * Chosen over any client library because it is in the platform: the Widget adds
 * no dependency to the APK for two GETs, and the one behaviour that matters —
 * a hard ceiling on how many bytes a response may cost — is exactly what this
 * class can implement and a large client cannot without configuration.
 *
 * The ceiling is enforced **while streaming**, not after: a download that is
 * checked once it has finished has already paid the memory it was meant to
 * avoid. iOS applies the same 128 KiB ceiling to the same endpoints. The 6 s
 * timeout is iOS's too.
 */
object WidgetHttp {
    private const val requestTimeoutMilliseconds = 6_000
    private const val maximumResponseBytes = 128 * 1024

    fun fetchCurrentWeather(latitude: Double, longitude: Double): RemoteCurrentWeather? {
        if (!latitude.isFinite() || !longitude.isFinite()) {
            throw WidgetHttpException("invalid coordinate")
        }
        if (latitude !in -90.0..90.0 || longitude !in -180.0..180.0) {
            throw WidgetHttpException("invalid coordinate")
        }

        val body = get(WidgetApi.currentWeatherUrl(latitude, longitude))
        val root = WidgetJsonParser.parse(body)?.objOrNull()
            ?: throw WidgetHttpException("invalid current weather payload")

        // An empty object is the endpoint's "no observation here", not an error.
        if (root.values.isEmpty()) return null

        val station = root["station"]?.objOrNull() ?: throw WidgetHttpException("missing station")
        val data = root["data"]?.objOrNull() ?: throw WidgetHttpException("missing data")
        val wind = data["wind"]?.objOrNull()

        val stationName = station["name"]?.strOrNull()
            ?: throw WidgetHttpException("missing station name")
        val time = root["time"]?.longOrNull()?.takeIf { it > 0 }
            ?: throw WidgetHttpException("missing observation time")
        val weather = data["weather"]?.strOrNull()
            ?: throw WidgetHttpException("missing weather")
        val weatherCode = data["weatherCode"]?.intOrNull()
            ?: throw WidgetHttpException("missing weather code")

        return RemoteCurrentWeather(
            stationName = stationName,
            time = time,
            weather = weather,
            weatherCode = weatherCode,
            temperature = data["temperature"].sentinelAwareDouble(),
            humidity = data["humidity"].sentinelAwareInt(),
            rain = data["rain"].sentinelAwareDouble(),
            windDirection = wind?.get("direction")?.strOrNull(),
            windSpeed = wind?.get("speed").sentinelAwareDouble(),
        )
    }

    fun fetchForecast(regionCode: String): RemoteForecast {
        if (!isValidRegionCode(regionCode)) throw WidgetHttpException("invalid region code")

        val body = get(WidgetApi.forecastUrl(regionCode))
        val root = WidgetJsonParser.parse(body)?.objOrNull()
            ?: throw WidgetHttpException("invalid forecast payload")

        val updateTime = root["updateTime"]?.longOrNull()?.takeIf { it > 0 }
            ?: throw WidgetHttpException("missing forecast publication time")
        val points = root["forecast"]?.arrOrNull()?.values
            ?: throw WidgetHttpException("missing forecast points")

        // A point the decoder refuses is dropped, not fatal: the API publishes
        // an array whose individual entries can be unusable, and iOS keeps the
        // rest rather than discarding the whole township.
        val decoded = points.mapNotNull { WidgetSnapshotDecoder.decodeForecastPoint(it) }
        return RemoteForecast(updateTime, decoded)
    }

    private fun get(url: String): String {
        var connection: HttpURLConnection? = null
        try {
            connection = URL(url).openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = requestTimeoutMilliseconds
            connection.readTimeout = requestTimeoutMilliseconds
            connection.setRequestProperty("Accept", "application/json")

            val status = connection.responseCode
            if (status != HttpURLConnection.HTTP_OK) {
                throw WidgetHttpException("http status $status")
            }

            val stream: InputStream = connection.inputStream
            return stream.use { readBounded(it) }
        } catch (error: WidgetHttpException) {
            throw error
        } catch (error: Exception) {
            throw WidgetHttpException(error.javaClass.simpleName)
        } finally {
            connection?.disconnect()
        }
    }

    /** Reads at most the ceiling plus one byte, so an oversize body is provable. */
    private fun readBounded(stream: InputStream): String {
        val buffer = ByteArray(8 * 1024)
        val output = java.io.ByteArrayOutputStream()
        var total = 0
        while (true) {
            val read = stream.read(buffer)
            if (read < 0) break
            total += read
            if (total > maximumResponseBytes) throw WidgetHttpException("response too large")
            output.write(buffer, 0, read)
        }
        return output.toString("UTF-8")
    }

    /**
     * The API's `-99` sentinel, which means "no reading" rather than a value.
     *
     * iOS and Dart both drop it; leaving it in would draw −99 °C on the widget.
     */
    private fun WidgetJson?.sentinelAwareDouble(): Double? {
        val value = this?.doubleOrNull() ?: return null
        return if (value == -99.0) null else value
    }

    private fun WidgetJson?.sentinelAwareInt(): Int? {
        val value = this?.intOrNull() ?: return null
        return if (value == -99) null else value
    }
}

/**
 * CWA outdoor, ventilated, shaded apparent temperature, in degrees Celsius.
 *
 * Ported from `currentApparentTemperature` in Dart so the Android Widget and the
 * iOS Widget cannot disagree about a number the user compares between devices.
 */
fun currentApparentTemperature(
    temperature: Double?,
    humidity: Int?,
    windSpeed: Double?,
): Double? {
    if (temperature == null || humidity == null || windSpeed == null) return null
    if (!temperature.isFinite() || !windSpeed.isFinite()) return null
    if (humidity < 0 || humidity > 100 || windSpeed < 0) return null

    val vapourPressure = (humidity / 100.0) * 6.105 *
        Math.exp(17.27 * temperature / (237.7 + temperature))
    val apparent = 1.04 * temperature + 0.2 * vapourPressure - 0.65 * windSpeed - 2.7
    return if (apparent.isFinite()) apparent else null
}
