package com.exptech.dpip.widget

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Where the Widget's HTTPS clock fallback asks — pinned because a host name
 * that stops answering fails silently: the fallback just never calibrates.
 *
 * Mirrors `WidgetHTTPTimeSourceTests.testAsksTheRegionPinnedLBNamesOverHTTPS`
 * on iOS, so the two Widgets cannot drift onto different hosts.
 */
class WidgetClockTest {
    @Test
    fun asksTheRegionPinnedLbNamesOverHttps() {
        // No bare host: the reading comes from the same edge the app talks to,
        // and the Widget has no region setting, so it takes the app's default
        // order with the other region as the fallback.
        assertEquals(
            listOf("api.lb-tpe1.exptech.dev", "api.lb-khh1.exptech.dev"),
            WidgetClock.httpHosts,
        )
        assertEquals(
            "https://api.lb-tpe1.exptech.dev/ntp",
            WidgetClock.httpTimeUrl(WidgetClock.httpHosts[0]),
        )
    }
}
