package com.exptech.dpip.widget

/**
 * The ordering metadata a committed snapshot carries.
 *
 * `valueTime` is the observation time for current weather and the publication
 * time for a forecast: the two kinds compare different instants, so the field is
 * named for what it does rather than for one of its uses.
 */
data class SnapshotOrderingMetadata(
    val snapshotGeneration: Long,
    val locationGeneration: Long,
    val valueTime: Long,
    val regionCode: String,
)

/**
 * Whether a candidate may replace the committed snapshot for one address.
 *
 * Extracted from the store so the rule is a function and not a statement buried
 * inside a transaction: it is the rule the whole design turns on — a late
 * response must not overwrite a newer one — and it is the one thing that has to
 * be right for `clear`, reconfigure and a township change to be safe.
 *
 * Two orderings, and which applies depends on the address:
 *
 * * **Current Location across townships** compares *location generations*. A
 *   move from township A to B must be accepted even when A's observation is
 *   newer, because the two numbers describe different places; the generation
 *   says which acquisition is the later one. This mirrors
 *   `CurrentWeatherSnapshotStorage.shouldReplace`.
 * * **Everything else** compares the value time, and only falls back to the
 *   generation when two snapshots carry the same instant — a re-fetch of the
 *   same observation must still let the newer request win so a stale payload
 *   from a slower request cannot land after a fresh one.
 */
object SnapshotOrdering {
    fun shouldReplace(
        address: WidgetAddress,
        existing: SnapshotOrderingMetadata?,
        candidate: SnapshotOrderingMetadata,
    ): Boolean {
        if (existing == null) return true

        // A township change is decided only by the location generation, and the
        // comparison returns immediately: the two observations describe
        // different places, so neither one's time is a reason to prefer it. If
        // this fell through to the value time, a move to a township whose first
        // observation is older than the one being left would be refused, and the
        // Widget would stay on a place the device is no longer in. Mirrors
        // `CurrentWeatherSnapshotStorage.shouldReplace`.
        if (address is WidgetAddress.CurrentLocation &&
            candidate.regionCode != existing.regionCode
        ) {
            return candidate.snapshotGeneration > existing.locationGeneration
        }

        if (candidate.valueTime != existing.valueTime) {
            return candidate.valueTime > existing.valueTime
        }
        return candidate.snapshotGeneration > existing.snapshotGeneration
    }

    /**
     * The location generation a candidate commit leaves behind.
     *
     * Only a Current Location has one that outlives a single snapshot: arrival
     * at a new township resets it, because "the newest acquisition in this
     * township" is meaningless across a move. A same-township commit carries the
     * maximum forward, so the fence only ever moves forward.
     */
    fun locationGeneration(
        address: WidgetAddress,
        existing: SnapshotOrderingMetadata?,
        candidate: SnapshotOrderingMetadata,
    ): Long {
        if (address !is WidgetAddress.CurrentLocation) return candidate.snapshotGeneration
        if (existing == null) return candidate.snapshotGeneration
        if (candidate.regionCode != existing.regionCode) return candidate.snapshotGeneration
        return maxOf(existing.locationGeneration, candidate.snapshotGeneration)
    }
}
