package com.exptech.dpip.widget

/**
 * The next hour's per-minute rainfall, ported from
 * `lib/features/weather/domain/rain_hour_trend.dart`.
 *
 * Wire shape (`GET /api/weather/rainforecast/{code}` on `exptech.dingbot.tw`):
 * a single-series envelope keyed by name (`rainfallWarnings-rkai`) whose value
 * is a list of `{start, rain}` records — a minute-aligned Unix-second
 * [startSecond] and sixty samples, one millimetre value per minute. The
 * grading, the continuity rule and the decode are the app's, line for line, so
 * the Widget and the home sheet never disagree about the same hour. There is no
 * placeholder: a Widget that has no trend draws no chart.
 */
data class RainHourTrend(val startSecond: Long, val mm: List<Double>) {
    init {
        require(mm.size == SAMPLES) { "expected $SAMPLES one-minute samples" }
    }

    /**
     * Intensity grade + continuity of the hour: the peak picks the grade, and
     * for light/heavy the position of the last wet minute decides whether the
     * rain is sustained or when it stops.
     */
    val summary: RainHourTrendSummary
        get() {
            val peak = mm.max()
            if (peak <= 0) return RainHourTrendSummary(RainHourTrendGrade.None, sustained = false)
            val grade = when {
                peak < SCATTERED_MM -> RainHourTrendGrade.Scattered
                peak < LIGHT_MM -> RainHourTrendGrade.Light
                else -> RainHourTrendGrade.Heavy
            }
            if (grade == RainHourTrendGrade.Scattered) return RainHourTrendSummary(grade, sustained = false)
            val lastRain = mm.indexOfLast { it > 0 }
            val sustained = lastRain >= SUSTAINED_FROM
            return RainHourTrendSummary(grade, sustained, if (sustained) null else lastRain + 1)
        }

    /** The hour carries no rain at all: an empty response or an all-zero series. */
    val isDry: Boolean get() = summary.grade == RainHourTrendGrade.None

    /** When the data runs out, calibrated Unix milliseconds. */
    val endMilliseconds: Long get() = (startSecond + SAMPLES * 60L) * 1_000

    companion object {
        const val SAMPLES = 60

        /** Peak per-minute mm below which the hour reads as isolated showers. */
        const val SCATTERED_MM = 5.0

        /** Peak per-minute mm at which the hour reads as heavy rain. */
        const val LIGHT_MM = 15.0

        /** The hour is continuous when the last wet minute is this late or later. */
        const val SUSTAINED_FROM = 45

        /**
         * The chart's fixed ceiling: the API can forecast more, and such a bar
         * is drawn full rather than rescaling every other bar.
         */
        const val MAXIMUM_MM = 35.0

        /**
         * Decodes the envelope: the first non-empty series wins. Every series
         * empty is the API's "no rain this hour", a dry trend starting at the
         * current calibrated minute. A non-empty series that is not the expected
         * record — a non-numeric `start`, a non-list `rain`, a sample count other
         * than sixty or a non-numeric sample — is a malformed response, null, and
         * never a dry hour.
         */
        fun decode(root: WidgetJson, calibratedNowMilliseconds: Long): RainHourTrend? {
            val envelope = root.objOrNull() ?: return null
            for (series in envelope.values.values) {
                val records = series.arrOrNull()?.values ?: continue
                if (records.isEmpty()) continue
                val record = records.first().objOrNull() ?: return null
                val start = record["start"]?.doubleOrNull() ?: return null
                val rain = record["rain"]?.arrOrNull()?.values ?: return null
                if (rain.size != SAMPLES) return null
                val samples = rain.map { it.doubleOrNull() ?: return null }
                return RainHourTrend(start.toLong(), samples)
            }
            return dry(calibratedNowMilliseconds)
        }

        /** A dry hour aligned to the minute of [calibratedNowMilliseconds]. */
        fun dry(calibratedNowMilliseconds: Long): RainHourTrend {
            val seconds = Math.floorDiv(calibratedNowMilliseconds, 1_000L)
            return RainHourTrend(seconds - Math.floorMod(seconds, 60L), List(SAMPLES) { 0.0 })
        }
    }
}

/** Rain intensity grade for the next hour, from the peak per-minute value. */
enum class RainHourTrendGrade { None, Scattered, Light, Heavy }

/** How the next hour reads; [stopInMinutes] is null when sustained or scattered. */
data class RainHourTrendSummary(
    val grade: RainHourTrendGrade,
    val sustained: Boolean,
    val stopInMinutes: Int? = null,
)

/** A trend as the cache holds it: which township it is for. */
data class StoredRainTrend(val regionCode: String, val trend: RainHourTrend)
