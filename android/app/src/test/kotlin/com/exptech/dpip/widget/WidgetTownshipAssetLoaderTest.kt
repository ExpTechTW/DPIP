package com.exptech.dpip.widget

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/** Exercises the production AssetManager path against merged Android assets. */
@RunWith(RobolectricTestRunner::class)
class WidgetTownshipAssetLoaderTest {
    @Test fun `production loader resolves Taiwan coordinates from packaged assets`() {
        val context: Context = ApplicationProvider.getApplicationContext()
        val resolver = checkNotNull(WidgetTownshipResolver.load(context)) {
            "the bundled directory and boundaries must load through Android AssetManager"
        }
        fun resolve(latitude: Double, longitude: Double) =
            resolver.resolve(WidgetFix(latitude, longitude, 50.0, 1_000))
        assertEquals("100", resolve(25.032188, 121.5183226)?.regionCode)
        assertEquals("894", resolve(24.4294, 118.2444)?.regionCode)
        assertEquals("中正區", resolver.township("100")?.displayName)
        assertNull(resolve(24.4798, 118.0894))
    }
}
