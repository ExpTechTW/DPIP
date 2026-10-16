package com.exptech.dpip.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import android.widget.ListView
import android.widget.TextView
import androidx.test.core.app.ApplicationProvider
import androidx.work.testing.WorkManagerTestInitHelper
import com.exptech.dpip.R
import com.google.android.material.button.MaterialButton
import com.google.android.material.radiobutton.MaterialRadioButton
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

/** Real picker lifecycle, native Material components, insets and rendered proof. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [26, 35], qualifiers = "420dpi")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetConfigurationRenderTest {
    private val context: Context get() = ApplicationProvider.getApplicationContext()
    @Before fun setup() {
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
        WidgetStore.resetForTest()
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
    }
    @After fun cleanup() {
        WidgetStore.resetForTest()
        context.deleteDatabase(WidgetStore.DATABASE_NAME)
    }
    private fun proof(name: String, empty: Boolean = false, scale: Float = 1f, width: Int = 411, height: Int = 891) {
        val store = WidgetStore.open(context)
        if (!empty) store.writeCatalog(listOf(
            WidgetCatalogLocation.create("407", "西屯區", "臺中市", 24.181, 120.645)!!,
            WidgetCatalogLocation.create("718", "關廟區", "臺南市", 22.96, 120.33)!!,
        ), 1L)
        store.writeInstance(42, WidgetAddress.Saved("407"), "407", 1L)
        val config = android.content.res.Configuration(context.resources.configuration).apply { fontScale = scale }
        @Suppress("DEPRECATION")
        context.resources.updateConfiguration(config, context.resources.displayMetrics)
        val controller = Robolectric.buildActivity(WeatherWidgetConfigurationActivity::class.java,
            Intent(context, WeatherWidgetConfigurationActivity::class.java)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 42)).create().start().resume().visible()
        val activity = controller.get()
        val root = activity.findViewById<View>(R.id.widget_config_root)
        val density = activity.resources.displayMetrics.density
        fun px(dp: Int) = (dp * density).toInt()
        @Suppress("DEPRECATION")
        val insets = androidx.core.view.WindowInsetsCompat.Builder()
            .setSystemWindowInsets(androidx.core.graphics.Insets.of(0, px(24), 0, px(24)))
            .setStableInsets(androidx.core.graphics.Insets.of(0, px(24), 0, px(24)))
            .build()
        // The lifecycle's real content view, in a representative standalone viewport;
        // Robolectric's default decor has a different screen size, not this fixture.
        (root.parent as android.view.ViewGroup).removeView(root)
        androidx.core.view.ViewCompat.dispatchApplyWindowInsets(root, insets)
        root.measure(View.MeasureSpec.makeMeasureSpec(px(width), View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(px(height), View.MeasureSpec.EXACTLY))
        root.layout(0, 0, px(width), px(height))
        assertEquals(px(24), root.paddingTop)
        assertEquals(px(24), root.paddingBottom)
        val cancel = root.findViewById<MaterialButton>(R.id.widget_config_cancel)
        assertTrue("bottom action clear of system navigation", cancel.bottom <= root.height - root.paddingBottom)
        assertTrue("48dp action touch target", cancel.height >= px(48))
        WidgetTextVisibility.assertVisible("cancel", cancel)
        if (height > width) WidgetTextVisibility.assertTree("picker $name", root)
        val list = root.findViewById<ListView>(R.id.widget_config_list)
        assertEquals(if (empty) 1 else 3, list.adapter.count)
        assertTrue("permission help visible", list.getChildAt(0).findViewById<TextView>(android.R.id.text2).text.isNotEmpty())
        if (!empty) {
            val saved = list.getChildAt(1) ?: list.adapter.getView(1, null, list)
            assertTrue("configured town is selected", saved.findViewById<MaterialRadioButton>(R.id.widget_config_radio).isChecked)
            assertEquals(activity.getString(R.string.widget_config_saved_locations), saved.findViewById<TextView>(R.id.widget_config_section).text)
        }
        assertEquals(if (empty) View.VISIBLE else View.GONE, root.findViewById<View>(R.id.widget_config_open_app).visibility)
        val bitmap = Bitmap.createBitmap(root.width, root.height, Bitmap.Config.ARGB_8888)
        fun settle(view: View) {
            view.jumpDrawablesToCurrentState()
            if (view is android.view.ViewGroup) for (i in 0 until view.childCount) settle(view.getChildAt(i))
        }
        settle(root)
        root.draw(Canvas(bitmap))
        val dir = File("build/widget-config-previews")
        assertTrue(
            "artifact directory must be creatable: ${dir.absolutePath}",
            dir.isDirectory || dir.mkdirs(),
        )
        File(dir, "$name-api${android.os.Build.VERSION.SDK_INT}.png").outputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        controller.pause().stop().destroy()
    }
    @Test fun `light current saved selected and permission proof`() = proof("settings-light")
    @Test @Config(qualifiers = "night-420dpi")
    fun `dark current saved selected and permission proof`() = proof("settings-dark")
    @Test fun `empty state offers app and cancel proof`() = proof("settings-empty", empty = true)
    @Test @Config(qualifiers = "fil-420dpi")
    fun `long locale and large font proof`() = proof("settings-long-locale", scale = 1.3f)
    @Test fun `landscape action remains above navigation bar`() = proof("settings-landscape", width = 891, height = 411)
}
