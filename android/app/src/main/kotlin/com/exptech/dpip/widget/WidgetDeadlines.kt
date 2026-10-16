package com.exptech.dpip.widget

import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneOffset

/**
 * The instants at which the screen would change on its own.
 *
 * All of them are **calibrated** deadlines: an observation ages out, the sun
 * crosses the horizon, a forecast expires. The presenter uses them to decide
 * what to draw now, and the refresh worker uses the same functions to ask for a
 * cache-only redraw at the first one that is still in the future — one set of
 * rules, so the screen cannot turn stale at a different moment from the one the
 * redraw was scheduled for.
 *
 * The forecast's deadline is the earlier of `published + 30 min` and the next
 * Taipei hour after receipt, because publication is a server instant while
 * receipt is a device reading: they are brought into calibrated time before
 * being compared. It is computed **once**, when the entry is committed
 * ([WidgetStore.commitForecast]) and stored, because a deadline re-derived from
 * a *later* weather refresh uses a device→calibrated offset that did not exist
 * when the response arrived — which is how an expired forecast comes back.
 */
object WidgetDeadlines {
    const val staleAfterMilliseconds = 30L * 60 * 1_000
    const val forecastExpiryMilliseconds = 30L * 60 * 1_000

    private val taipeiOffset = ZoneOffset.ofHours(8)

    /** When the observation stops being current. */
    fun staleness(snapshot: CurrentWeatherSnapshot): Long =
        snapshot.observationTime * 1_000 + staleAfterMilliseconds

    /** When the day/night phase flips, or null when the snapshot has no transition. */
    fun dayNight(snapshot: CurrentWeatherSnapshot): Long? =
        if (snapshot.nextDayNightTransitionTime > 0) {
            snapshot.nextDayNightTransitionTime * 1_000
        } else {
            null
        }

    fun nextTaipeiHourStart(calibratedMilliseconds: Long): Long {
        val local = LocalDateTime.ofInstant(
            Instant.ofEpochMilli(calibratedMilliseconds),
            taipeiOffset,
        )
        val startOfHour = local.withMinute(0).withSecond(0).withNano(0)
        return startOfHour.plusHours(1).toInstant(taipeiOffset).toEpochMilli()
    }

    /**
     * The absolute expiry for a forecast accepted at [receivedCalibratedMilliseconds].
     *
     * Called once, at commit, while the clock anchor that produced the receipt is
     * still the one in hand.
     */
    fun forecastExpiry(
        updateTimeMilliseconds: Long,
        receivedCalibratedMilliseconds: Long,
    ): Long = minOf(
        updateTimeMilliseconds + forecastExpiryMilliseconds,
        nextTaipeiHourStart(receivedCalibratedMilliseconds),
    )

    /**
     * The earliest future instant that would change what is on screen, or null.
     *
     * A null means nothing on screen will change by itself, so no redraw is
     * worth scheduling — the difference between "wait for the next boundary" and
     * the every-minute re-render this replaced.
     */
    fun nextChange(
        snapshot: CurrentWeatherSnapshot,
        forecast: StoredForecast?,
        calibratedNowMilliseconds: Long,
    ): Long? {
        val candidates = buildList {
            add(staleness(snapshot))
            dayNight(snapshot)?.let { add(it) }
            // The stored deadline, not a recomputation: it is the same instant
            // the presenter hides the forecast at, so the redraw and the screen
            // cannot disagree.
            if (forecast != null) add(forecast.expiresAtMilliseconds)
        }
        return candidates.filter { it > calibratedNowMilliseconds }.minOrNull()
    }
}
