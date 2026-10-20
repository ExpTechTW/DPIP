package com.exptech.dpip.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.graphics.RectF
import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import com.exptech.dpip.R
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.util.ReflectionHelpers
import java.io.File
import java.time.LocalDateTime
import java.time.ZoneOffset
import java.util.Locale
import kotlin.math.ceil

/** A padded line can still lose fallback-font ink above its nominal top on API 26. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 35], qualifiers = "420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetBadgeGlyphRegressionTest {
    private val fixture = WidgetLargeRoomyForecastRegressionTest()
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    private val at = LocalDateTime.of(2026, 10, 12, 14, 20)
        .toInstant(ZoneOffset.ofHours(8)).toEpochMilli()
    private val output get() = File("build/widget-badge-glyph").apply { mkdirs() }
    private val locales = listOf("th", "zh-TW", "en", "ja", "ko", "fil")
    private val scales = listOf(1f, 1.3f, 2f)

    @Before fun setUp() = fixture.setUp()
    @After fun tearDown() = fixture.tearDown()

    private fun configured(locale: String, scale: Float, dark: Boolean): Context =
        context.createConfigurationContext(Configuration(context.resources.configuration).apply {
            setLocale(Locale.forLanguageTag(locale))
            fontScale = scale
            uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                if (dark) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
        })

    private fun presentation(c: Context, width: Int, height: Int, state: String): WidgetPresentation {
        val scale = c.resources.configuration.fontScale
        val w = ceil(width * scale.toDouble()).toInt()
        val h = ceil(height * scale.toDouble()).toInt()
        val store = WidgetStore.open(c)
        val base = WidgetPresenter.present(
            WidgetPresenter.sizeClass(w, h, scale), WidgetUpdater.strings(c),
            WidgetAddress.CurrentLocation, "西屯區",
            store.readCurrentWeather(WidgetAddress.Saved("407")),
            store.readForecast(WidgetAddress.Saved("407")),
            when (state) {
                "needs-app" -> WidgetLocationDegradation.Permission
                "location-unavailable" -> WidgetLocationDegradation.Unavailable
                else -> null
            },
            true, at, 24.181, 120.645, w, h, scale,
        )
        return when (state) {
            "stale" -> base.copy(isStale = true, badgeText = c.getString(R.string.widget_stale))
            "queued" -> base.copy(refreshFeedback = WidgetRefreshFeedback.Queued)
            "running" -> base.copy(refreshFeedback = WidgetRefreshFeedback.Running)
            "failed" -> base.copy(refreshFeedback = WidgetRefreshFeedback.Failed)
            "updated" -> base.copy(refreshFeedback = WidgetRefreshFeedback.Updated)
            else -> base
        }
    }

    private fun measure(c: Context, p: WidgetPresentation, view: View) {
        val density = c.resources.displayMetrics.density
        val w = (p.availableWidthDp * density).toInt()
        val h = (p.availableHeightDp * density).toInt()
        view.measure(View.MeasureSpec.makeMeasureSpec(w, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(h, View.MeasureSpec.EXACTLY))
        view.layout(0, 0, w, h)
    }

    /** Compare unbounded Layout ink with TextView.draw, using TextView's own origin. */
    private fun assertGlyphs(label: String, text: TextView, root: ViewGroup, allowEllipsis: Boolean) {
        val layout = text.layout!!
        val offset = ReflectionHelpers.callInstanceMethod<Int>(text, "getVerticalOffset",
            ReflectionHelpers.ClassParameter.from(Boolean::class.javaPrimitiveType, false))
        val bounds = Rect(0, 0, text.width, text.height)
        root.offsetDescendantRectToMyCoords(text, bounds)
        val clip = RectF(bounds.left + text.compoundPaddingLeft.toFloat(), bounds.top.toFloat(),
            bounds.right - text.compoundPaddingRight.toFloat(), bounds.bottom.toFloat())
        var node: View = text
        while (node !== root) {
            val parent = node.parent as ViewGroup
            val b = Rect(0, 0, parent.width, parent.height)
            if (parent !== root) root.offsetDescendantRectToMyCoords(parent, b)
            if (parent.clipChildren) {
                if (parent.clipToPadding) {
                    b.left += parent.paddingLeft; b.top += parent.paddingTop
                    b.right -= parent.paddingRight; b.bottom -= parent.paddingBottom
                }
                assertTrue("$label ancestor clip", clip.intersect(RectF(b)))
            }
            node = parent
        }
        for (line in 0 until layout.lineCount) {
            if (!allowEllipsis) assertEquals("$label unwanted ellipsis", 0, layout.getEllipsisCount(line))
            val box = RectF(bounds.left + text.compoundPaddingLeft + layout.getLineLeft(line),
                (bounds.top + text.extendedPaddingTop + offset + layout.getLineTop(line)).toFloat(),
                bounds.left + text.compoundPaddingLeft + layout.getLineRight(line),
                (bounds.top + text.extendedPaddingTop + offset + layout.getLineBottom(line)).toFloat())
            assertTrue("$label line $box outside $clip", clip.contains(box))
        }
        val guard = text.textSize.toInt().coerceAtLeast(1)
        val width = (0 until layout.lineCount).maxOf { ceil(layout.getLineRight(it).toDouble()).toInt() }.coerceAtLeast(1)
        val expected = Bitmap.createBitmap(width + guard * 2, layout.height + guard * 2, Bitmap.Config.ARGB_8888)
        val actual = Bitmap.createBitmap(text.width + guard * 2, text.height + guard * 2, Bitmap.Config.ARGB_8888)
        try {
            Canvas(actual).also { it.translate(guard.toFloat(), guard.toFloat()); text.draw(it) }
            Canvas(expected).also { it.translate(guard.toFloat(), guard.toFloat()); layout.draw(it) }
            val pixels = IntArray(expected.width * expected.height)
            expected.getPixels(pixels, 0, expected.width, 0, 0, expected.width, expected.height)
            var ink = 0
            for (i in pixels.indices) if (pixels[i] ushr 24 != 0) {
                ink++
                val x = text.compoundPaddingLeft - text.scrollX + i % expected.width - guard
                val y = text.extendedPaddingTop + offset - text.scrollY + i / expected.width - guard
                assertTrue("$label glyph ($x,$y) outside $clip", clip.contains(bounds.left + x + 0.5f, bounds.top + y + 0.5f))
                assertTrue("$label glyph ($x,$y) missing from TextView.draw",
                    actual.getPixel(x + guard, y + guard) ushr 24 != 0)
            }
            assertTrue("$label nonempty native glyph raster", ink > 0)
        } finally { expected.recycle(); actual.recycle() }
    }

    private fun check(label: String, p: WidgetPresentation, root: ViewGroup, forecast: Boolean = false) {
        val badge = root.findViewById<TextView>(R.id.widget_stale)
        assertEquals("$label badge visibility", p.badgeText != null, badge.visibility == View.VISIBLE)
        if (badge.visibility == View.VISIBLE) {
            // Status explicitly permits END ellipsis. Its full meaning lives on the surface.
            assertTrue("$label full accessible status", root.contentDescription.toString().contains(p.badgeText!!))
            WidgetTextVisibility.assertVisible("$label badge", badge, allowEllipsis = true)
            assertGlyphs("$label badge", badge, root, allowEllipsis = true)
        }
        if (p.state == WidgetDisplayState.NeedsApp) {
            assertTrue(p.hasObservation && p.isCurrentLocation && !p.canRefresh)
            assertEquals(p.temperatureText, root.findViewById<TextView>(R.id.widget_temperature).text.toString())
            assertEquals(View.GONE, root.findViewById<View>(R.id.widget_refresh).visibility)
        }
        val refresh = root.findViewById<View>(R.id.widget_refresh)
        assertEquals("$label refresh visibility", if (p.showRefresh) View.VISIBLE else View.GONE, refresh.visibility)
        val busy = p.refreshFeedback in listOf(WidgetRefreshFeedback.Queued, WidgetRefreshFeedback.Running)
        assertEquals("$label refresh action", p.showRefresh && p.canRefresh && !busy, refresh.isEnabled)
        if (!forecast) return
        val columns = root.findViewById<ViewGroup>(R.id.widget_forecast_container)
        assertEquals("$label five columns", 5, columns.childCount)
        for (i in 0 until 5) {
            val column = columns.getChildAt(i) as ViewGroup
            for ((id, expected) in listOf(R.id.widget_forecast_time to p.forecast[i].time,
                R.id.widget_forecast_temperature to p.forecast[i].temperatureText,
                R.id.widget_forecast_pop to p.forecast[i].popText)) {
                val text = column.findViewById<TextView>(id)
                assertEquals("$label column $i", expected, text.text.toString())
                WidgetTextVisibility.assertVisible("$label column $i", text)
                assertGlyphs("$label column $i", text, root, allowEllipsis = false)
            }
            val icon = column.findViewById<ImageView>(R.id.widget_forecast_icon)
            assertTrue("$label column $i icon", icon.visibility == View.VISIBLE && icon.drawable != null && icon.width > 0 && icon.height > 0)
            val children = (0 until column.childCount).map { column.getChildAt(it) }
                .flatMap { child -> if (child is ViewGroup) (0 until child.childCount).map { child.getChildAt(it) } else listOf(child) }
                .filter { it.visibility == View.VISIBLE }
            for (child in children) assertTrue("$label column $i height", child.top >= 0 && child.bottom <= column.height)
            children.zipWithNext().forEach { (a, b) -> assertTrue("$label column $i overlap", a.bottom <= b.top) }
            if (i > 0) assertTrue("$label column overlap", columns.getChildAt(i - 1).right <= column.left)
        }
    }

    private fun exercise(c: Context, p: WidgetPresentation, label: String, forecast: Boolean = false, evidence: Boolean = false) {
        val remote = WidgetRenderer.render(c, p, 42)
        val root = remote.apply(c, FrameLayout(c)) as ViewGroup
        measure(c, p, root)
        check("$label first", p, root, forecast)
        val bitmap = Bitmap.createBitmap(root.width, root.height, Bitmap.Config.ARGB_8888)
        try {
            root.draw(Canvas(bitmap))
            if (evidence) File(output, "$label-api${Build.VERSION.SDK_INT}.png").outputStream().use {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
        } finally { bitmap.recycle() }
        remote.reapply(c, root)
        measure(c, p, root)
        check("$label reapply", p, root, forecast)
        if (evidence) {
            val t = root.findViewById<TextView>(R.id.widget_stale)
            val columns = root.findViewById<View>(R.id.widget_forecast_container)
            File(output, "budgets-api${Build.VERSION.SDK_INT}.jsonl").appendText(org.json.JSONObject()
                .put("case", label).put("layout", c.resources.getResourceEntryName(remote.layoutId))
                .put("rootHeight", root.height).put("badgeHeight", t.height).put("badgePaddingTop", t.paddingTop)
                .put("badgeBaseline", t.baseline).put("badgeLayoutHeight", t.layout.height)
                .put("forecastTop", columns?.top).put("forecastHeight", columns?.height)
                .put("forecastBottom", columns?.bottom).toString() + "\n")
        }
    }

    @Test fun thaiNeedsAppRetainsWholeGlyphRaster() {
        for (scale in scales) for (dark in listOf(false, true)) for (height in listOf(170, 320, 336)) {
            val c = configured("th", scale, dark)
            val p = presentation(c, 200, height, "needs-app")
            assertEquals(WidgetDisplayState.NeedsApp, p.state)
            exercise(c, p, "th-$height-f$scale-dark$dark", evidence = true)
        }
    }

    @Test fun localizedBadgeAndAdjacentRefreshStates() {
        for (locale in locales) for (scale in scales) for (dark in listOf(false, true)) {
            val c = configured(locale, scale, dark)
            for (height in listOf(170, 320, 336)) for (state in listOf("needs-app", "location-unavailable", "stale", "fresh", "queued", "running", "failed", "updated")) {
                val p = presentation(c, 200, height, state)
                exercise(c, p, "$locale-$height-f$scale-dark$dark-$state")
            }
        }
    }

    @Test fun needsAppPreservesFiveColumnsAtEveryHeightBoundary() {
        for (locale in locales) for (scale in scales) for (dark in listOf(false, true)) {
            val c = configured(locale, scale, dark)
            for (height in listOf(170, 320, 335, 336, 337, 344)) {
                val p = presentation(c, 200, height, "needs-app")
                assertEquals("production layout at $height", when {
                    height < 320 -> R.layout.widget_medium
                    height < 336 -> R.layout.widget_large_tight
                    else -> R.layout.widget_large
                }, WidgetRenderer.layoutFor(p))
                exercise(c, p, "$locale-$height-f$scale-dark$dark-needs-app", forecast = true, evidence = true)
            }
        }
    }

    @Test fun smallTallAndCompactKeepTheirStatusAndIconContracts() {
        for (locale in locales) for (scale in scales) for (dark in listOf(false, true)) {
            val c = configured(locale, scale, dark)
            for ((width, height) in listOf(120 to 172, 120 to 240, 110 to 110)) {
                val p = presentation(c, width, height, "needs-app")
                exercise(c, p, "$locale-${width}x$height-f$scale-dark$dark-needs-app")
                if (!p.compactLayout) {
                    val root = WidgetRenderer.render(c, p, 42).apply(c, FrameLayout(c))
                    measure(c, p, root)
                    val icon = root.findViewById<ImageView>(R.id.widget_icon)
                    val expected = c.resources.getDimensionPixelSize(if (height == 240) R.dimen.widget_icon_small_tall else R.dimen.widget_icon_small_standard)
                    assertEquals("$locale Small/Tall icon", expected, icon.width)
                    assertEquals(expected, icon.height)
                }
            }
        }
    }
}
