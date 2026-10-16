package com.exptech.dpip.widget

import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneOffset
import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * Sunrise, sunset and day/night, for a point on the ground.
 *
 * Ported from `lib/core/weather/solar_time.dart`, which is the authoritative
 * engine: the Widget must agree with the app about which glyph is a moon, and
 * the app decides by this same low-precision ephemeris. Sunrise and sunset are
 * fixed for the local calendar day and rounded to whole seconds, the same
 * precision the snapshot contract carries, so `isNightAt` and
 * `nextDayNightTransitionAt` agree at the boundary rather than a second apart.
 *
 * Taiwan is UTC+8 all year and has no DST, which is why the offset is a
 * constant 8 rather than a zone lookup: `Asia/Taipei` computes the same thing
 * and would only add a timezone database dependency to the Widget process.
 */
object WidgetSolarTime {
    const val taipeiUtcOffsetHours = 8.0
    private const val millisecondsPerDay = 86_400_000.0
    private const val j2000UnixDayOffset = 10_957.5
    private val taipeiOffset = ZoneOffset.ofHours(8)

    private const val degreesToRadians = Math.PI / 180.0

    /** Sunrise/sunset as whole seconds past local midnight. */
    data class SunSeconds(val sunrise: Int, val sunset: Int)

    fun isNightAt(
        unixMilliseconds: Long,
        latitude: Double,
        longitude: Double,
    ): Boolean {
        val local = LocalDateTime.ofInstant(Instant.ofEpochMilli(unixMilliseconds), taipeiOffset)
        val times = sunSecondsForLocalDate(local.toLocalDate(), latitude, longitude)
        return isNightAtLocalSecond(local, times)
    }

    /**
     * The next sunrise or sunset as **Unix seconds**.
     *
     * Seconds, because that is the unit the snapshot contract stores
     * (`nextDayNightTransitionTime`) on both platforms: Dart writes
     * `millisecondsSinceEpoch ~/ 1000` and the iOS factory stores whole seconds.
     * A millisecond value here would be written into a seconds field and read
     * back as a date a thousand times too far away, which is why the unit is in
     * this function's name and why the factory's tests pin the boundary.
     */
    fun nextDayNightTransitionSecondsAt(
        unixMilliseconds: Long,
        latitude: Double,
        longitude: Double,
    ): Long {
        val local = LocalDateTime.ofInstant(Instant.ofEpochMilli(unixMilliseconds), taipeiOffset)
        val today = sunSecondsForLocalDate(local.toLocalDate(), latitude, longitude)

        if (localSecond(local) < today.sunrise) {
            return localSecondToUnixMilliseconds(local.toLocalDate(), today.sunrise) / 1_000
        }
        if (localSecond(local) < today.sunset) {
            return localSecondToUnixMilliseconds(local.toLocalDate(), today.sunset) / 1_000
        }

        val tomorrow = local.toLocalDate().plusDays(1)
        val tomorrowTimes = sunSecondsForLocalDate(tomorrow, latitude, longitude)
        return localSecondToUnixMilliseconds(tomorrow, tomorrowTimes.sunrise) / 1_000
    }

    /** Sunrise/sunset for the local day containing [unixMilliseconds]. */
    fun sunSeconds(
        unixMilliseconds: Long,
        latitude: Double,
        longitude: Double,
    ): SunSeconds {
        val local = LocalDateTime.ofInstant(Instant.ofEpochMilli(unixMilliseconds), taipeiOffset)
        return sunSecondsForLocalDate(local.toLocalDate(), latitude, longitude)
    }

    private fun isNightAtLocalSecond(local: LocalDateTime, times: SunSeconds): Boolean {
        val second = localSecond(local)
        return second < times.sunrise || second >= times.sunset
    }

    private fun localSecond(local: LocalDateTime): Int =
        local.hour * 3_600 + local.minute * 60 + local.second

    private fun localSecondToUnixMilliseconds(date: LocalDate, second: Int): Long =
        date.atStartOfDay().plusSeconds(second.toLong()).toInstant(taipeiOffset).toEpochMilli()

    private fun sunSecondsForLocalDate(
        date: LocalDate,
        latitude: Double,
        longitude: Double,
    ): SunSeconds {
        // The local noon of that day, expressed in UTC: the ephemeris takes an
        // instant, and noon is the one instant whose day is unambiguous in both
        // hemispheres of the date line.
        val anchor = date.atTime(LocalTime.NOON).toInstant(taipeiOffset).toEpochMilli()
        val times = sunTimes(anchor, latitude, longitude)
        return SunSeconds(
            sunrise = (times.first * 3_600).roundToInt(),
            sunset = (times.second * 3_600).roundToInt(),
        )
    }

    /** Sunrise and sunset in local decimal hours for the UTC day of [unixMilliseconds]. */
    private fun sunTimes(
        unixMilliseconds: Long,
        latitude: Double,
        longitude: Double,
    ): Pair<Double, Double> {
        val n = unixMilliseconds / millisecondsPerDay - j2000UnixDayOffset

        val meanLongitude = positiveModulo(280.460 + 0.9856474 * n, 360.0)
        val meanAnomaly = positiveModulo(357.528 + 0.9856003 * n, 360.0) * degreesToRadians
        val eclipticLongitude = (
            meanLongitude + 1.915 * sin(meanAnomaly) + 0.020 * sin(2 * meanAnomaly)
            ) * degreesToRadians
        val obliquity = (23.439 - 0.0000004 * n) * degreesToRadians
        val declination = asin(sin(obliquity) * sin(eclipticLongitude))

        val lat = latitude * degreesToRadians
        val altitude = -0.833 * degreesToRadians

        val cosHourAngle = (sin(altitude) - sin(lat) * sin(declination)) /
            (cos(lat) * cos(declination))

        // Polar day or night — no crossing exists.
        if (cosHourAngle <= -1.0) return 0.0 to 24.0
        if (cosHourAngle >= 1.0) return 12.0 to 12.0

        val hourAngle = acos(cosHourAngle) / degreesToRadians / 15.0

        val rightAscension = kotlin.math.atan2(
            cos(obliquity) * sin(eclipticLongitude),
            cos(eclipticLongitude),
        )
        var equationOfTime = (meanLongitude * degreesToRadians - rightAscension) /
            degreesToRadians / 15.0
        // Unwrap: the difference must stay within a few minutes of zero.
        equationOfTime = positiveModulo(equationOfTime + 12.0, 24.0) - 12.0

        val solarNoon = 12.0 - longitude / 15.0 + taipeiUtcOffsetHours - equationOfTime
        return (solarNoon - hourAngle) to (solarNoon + hourAngle)
    }

    private fun positiveModulo(value: Double, modulus: Double): Double {
        val remainder = value % modulus
        if (remainder == 0.0) return 0.0
        return if (remainder > 0) remainder else remainder + modulus
    }
}
