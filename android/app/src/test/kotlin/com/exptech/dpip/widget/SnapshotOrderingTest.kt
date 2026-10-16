package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SnapshotOrderingTest {
    private val saved = WidgetAddress.Saved("407")

    private fun ordering(
        generation: Long,
        valueTime: Long,
        regionCode: String = "407",
        locationGeneration: Long = generation,
    ) = SnapshotOrderingMetadata(generation, locationGeneration, valueTime, regionCode)

    @Test
    fun `the first snapshot always commits`() {
        assertTrue(SnapshotOrdering.shouldReplace(saved, null, ordering(1, 1_000)))
    }

    @Test
    fun `a newer observation replaces an older one`() {
        assertTrue(SnapshotOrdering.shouldReplace(saved, ordering(1, 1_000), ordering(2, 2_000)))
    }

    @Test
    fun `a later request carrying an older observation does not replace it`() {
        // The whole point of the ordering: a slow request that started first and
        // finished last must not overwrite fresher data.
        assertFalse(SnapshotOrdering.shouldReplace(saved, ordering(2, 2_000), ordering(3, 1_000)))
    }

    @Test
    fun `the same observation is decided by generation`() {
        assertTrue(SnapshotOrdering.shouldReplace(saved, ordering(4, 1_000), ordering(5, 1_000)))
        assertFalse(SnapshotOrdering.shouldReplace(saved, ordering(5, 1_000), ordering(4, 1_000)))
        assertFalse(SnapshotOrdering.shouldReplace(saved, ordering(5, 1_000), ordering(5, 1_000)))
    }

    @Test
    fun `current location may move to another township on a newer acquisition`() {
        // A's observation is newer, but B is where the device is now: the
        // location generation, not the observation time, decides.
        val existing = ordering(generation = 10, valueTime = 9_000, regionCode = "407", locationGeneration = 10)
        val candidate = ordering(generation = 11, valueTime = 1_000, regionCode = "100", locationGeneration = 11)
        assertTrue(SnapshotOrdering.shouldReplace(WidgetAddress.CurrentLocation, existing, candidate))
    }

    @Test
    fun `current location refuses a township change from a superseded acquisition`() {
        val existing = ordering(generation = 11, valueTime = 9_000, regionCode = "100", locationGeneration = 11)
        val stale = ordering(generation = 10, valueTime = 9_500, regionCode = "407", locationGeneration = 10)
        assertFalse(SnapshotOrdering.shouldReplace(WidgetAddress.CurrentLocation, existing, stale))
    }

    @Test
    fun `current location within one township still orders by observation`() {
        val existing = ordering(generation = 5, valueTime = 5_000, regionCode = "407")
        val older = ordering(generation = 6, valueTime = 4_000, regionCode = "407")
        assertFalse(SnapshotOrdering.shouldReplace(WidgetAddress.CurrentLocation, existing, older))
    }

    @Test
    fun `a saved address never compares by location generation`() {
        // Same town by construction, so the location-generation branch must not
        // engage: an older observation is refused even with a higher generation.
        val existing = ordering(generation = 3, valueTime = 5_000, regionCode = "407", locationGeneration = 99)
        val candidate = ordering(generation = 4, valueTime = 4_000, regionCode = "407")
        assertFalse(SnapshotOrdering.shouldReplace(saved, existing, candidate))
    }

    @Test
    fun `location generation only advances within one township`() {
        assertEquals(
            7L,
            SnapshotOrdering.locationGeneration(
                WidgetAddress.CurrentLocation,
                ordering(5, 1_000, regionCode = "407", locationGeneration = 7),
                ordering(6, 2_000, regionCode = "407"),
            ),
        )
        assertEquals(
            6L,
            SnapshotOrdering.locationGeneration(
                WidgetAddress.CurrentLocation,
                ordering(5, 1_000, regionCode = "407", locationGeneration = 7),
                ordering(6, 2_000, regionCode = "100"),
            ),
        )
        assertEquals(
            6L,
            SnapshotOrdering.locationGeneration(WidgetAddress.CurrentLocation, null, ordering(6, 2_000)),
        )
        assertEquals(
            6L,
            SnapshotOrdering.locationGeneration(saved, ordering(5, 1_000), ordering(6, 2_000)),
        )
    }
}
