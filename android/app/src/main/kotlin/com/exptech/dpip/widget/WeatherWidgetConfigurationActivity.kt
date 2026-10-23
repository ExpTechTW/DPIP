package com.exptech.dpip.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.TextView
import com.exptech.dpip.MainActivity
import com.exptech.dpip.R

/**
 * The location picker the launcher opens when a Widget is added or reconfigured.
 * Reconfiguration availability depends on the platform and launcher; launchers
 * without that entry require removing and adding the Widget again.
 *
 * The result contract is the framework's, and it is the trap this class is
 * careful about:
 *
 * * **Adding.** The result defaults to `RESULT_CANCELED`, and an Activity that
 *   never sets it leaves the user with a Widget that was never added, having
 *   tapped a row. So `RESULT_CANCELED` is set first thing and only replaced
 *   once the choice has been persisted.
 * * **Reconfiguring.** The launcher can reopen the same Activity, and there
 *   "cancel" means *keep what is configured*. It is
 *   answered with `RESULT_OK` **without touching the stored instance**, which is
 *   what "no change" means to the launcher; answering `RESULT_CANCELED` here
 *   would be asking the launcher to undo the reconfiguration.
 *
 * It reads the same catalog Dart published for the iOS configuration intent.
 * There is no second list of places: a location the app does not have is not
 * offerable here, and when the catalog is empty the screen says so and offers to
 * open the app rather than inventing an entry.
 *
 * The chosen address is stored against `appWidgetId` and never read from the
 * app's own selected region, which is what keeps a Widget on its own town when
 * the user changes the app's Home region.
 */
class WeatherWidgetConfigurationActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var isReconfigure = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Wallpaper colors only here; API26–30 retains the DPIP teal fallback.
        com.google.android.material.color.DynamicColors.applyToActivityIfAvailable(this)
        super.onCreate(savedInstanceState)
        androidx.core.view.WindowCompat.setDecorFitsSystemWindows(window, false)
        setResult(RESULT_CANCELED)
        bind(intent)
    }

    /**
     * A launcher may reuse this `singleTop` Activity for another Widget.
     * Validate and rebuild for the latest target, rather than writing a new
     * choice to the Widget whose screen happened to be open first.
     *
     * `setIntent` first, so `getIntent()` — and anything after this that reads it
     * — describes the intent that arrived last, which is the Activity contract.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        setResult(RESULT_CANCELED)
        bind(intent)
    }

    /**
     * Reads the target instance from [source] and builds the screen for it.
     *
     * Shared by `onCreate` and `onNewIntent` because the two must leave
     * identical state: a reused instance that only half-updated would report one
     * Widget and write another.
     */
    private fun bind(source: Intent?) {
        appWidgetId = source?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (!isOwnWidget()) {
            finish()
            return
        }

        val store = WidgetStore.open(this)
        isReconfigure = store.readInstance(appWidgetId) != null

        setContentView(R.layout.activity_widget_config)
        val root = findViewById<View>(R.id.widget_config_root)
        androidx.core.view.ViewCompat.setOnApplyWindowInsetsListener(root) { view, insets ->
            val bars = insets.getInsets(androidx.core.view.WindowInsetsCompat.Type.systemBars() or
                androidx.core.view.WindowInsetsCompat.Type.displayCutout())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        androidx.core.view.ViewCompat.requestApplyInsets(root)
        androidx.core.view.WindowCompat.getInsetsController(window, root).apply {
            val dark = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                android.content.res.Configuration.UI_MODE_NIGHT_YES
            isAppearanceLightStatusBars = !dark
            isAppearanceLightNavigationBars = !dark
        }

        findViewById<TextView>(R.id.widget_config_title).text =
            getString(R.string.widget_config_title)
        findViewById<Button>(R.id.widget_config_cancel).apply {
            text = getString(R.string.widget_config_cancel)
            setOnClickListener { cancel() }
        }

        val message = findViewById<TextView>(R.id.widget_config_message)
        val list = findViewById<ListView>(R.id.widget_config_list)
        val openApp = findViewById<Button>(R.id.widget_config_open_app).apply {
            text = getString(R.string.widget_config_open_app)
            setOnClickListener { openApp() }
        }

        val catalog = store.readCatalog()?.locations.orEmpty()
        val rows = buildRows(catalog)

        if (catalog.isEmpty()) {
            message.visibility = View.VISIBLE
            message.text = getString(R.string.widget_config_empty)
            openApp.visibility = View.VISIBLE
        } else {
            message.visibility = View.VISIBLE
            message.text = getString(R.string.widget_config_hint)
        }

        list.adapter = RowAdapter(this, rows, store.readInstance(appWidgetId)?.address)
        list.setOnItemClickListener { _, _, position, _ -> choose(rows[position]) }
    }

    /**
     * Intent extras are untrusted, even when the launcher normally supplies them.
     *
     * A null `AppWidgetManager` (no `FEATURE_APP_WIDGETS`) answers "not ours",
     * which is both true and the safe direction: this activity is only reachable
     * by an explicit intent on such a device, and that intent is exactly the one
     * this guard exists to reject.
     */
    private fun isOwnWidget(): Boolean =
        appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID &&
            AppWidgetManager.getInstance(this)?.getAppWidgetInfo(appWidgetId)?.provider ==
            ComponentName(this, WeatherWidgetProvider::class.java)

    /**
     * Cancels, preserving an existing configuration.
     *
     * See the class comment: for a reconfigure the framework's "no change" is
     * `RESULT_OK` with the stored instance left exactly as it was.
     */
    private fun cancel() {
        setResult(if (isReconfigure && isOwnWidget()) RESULT_OK else RESULT_CANCELED)
        finish()
    }

    /**
     * Current position first, then the saved towns.
     *
     * The current-position row carries the permission state in its own subtitle,
     * because the alternative — asking for background location from the Worker —
     * is impossible, and asking from here without saying why would be a prompt
     * with no explanation. It still selects; the Widget simply degrades to the
     * last known position and says so.
     */
    private fun buildRows(catalog: List<WidgetCatalogLocation>): List<Row> {
        val rows = ArrayList<Row>(catalog.size + 1)
        val permissionSubtitle = if (WidgetLocationFix.hasBackgroundPermission(this)) {
            null
        } else {
            getString(R.string.widget_config_needs_permission)
        }
        rows.add(
            Row(
                address = WidgetAddress.CurrentLocation,
                regionCode = null,
                title = getString(R.string.widget_current_location),
                subtitle = permissionSubtitle,
            ),
        )
        for (location in catalog) {
            rows.add(
                Row(
                    address = WidgetAddress.Saved(location.regionCode),
                    regionCode = location.regionCode,
                    title = location.displayName,
                    subtitle = location.administrativeAreaName,
                ),
            )
        }
        return rows
    }

    private fun choose(row: Row) {
        // The launcher can remove the Widget while the picker is open. Recheck
        // at the write boundary so no durable ghost or refresh work is created.
        if (!isOwnWidget()) {
            setResult(RESULT_CANCELED)
            finish()
            return
        }
        val store = WidgetStore.open(this)
        if (!store.writeInstance(
                appWidgetId = appWidgetId,
                address = row.address,
                regionCode = row.regionCode,
                updatedAt = System.currentTimeMillis(),
            )
        ) {
            // Persisting the choice is the whole job; if it did not happen the
            // Widget must not be added, so the canceled result stands.
            finish()
            return
        }

        // Draw immediately from whatever is cached, then ask for a fetch. The
        // order matters: the launcher shows the cache while the network runs,
        // not a blank.
        WidgetUpdater.updateInstance(this, appWidgetId)
        WidgetUpdater.refreshForecastDemand(this, row.address)
        WidgetRefreshScheduler.schedulePeriodic(this)
        WidgetRefreshScheduler.scheduleOneTime(this, row.address)

        setResult(
            RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
        )
        finish()
    }

    private fun openApp() {
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
        )
        finish()
    }

    /** One selectable location, already localized. */
    private data class Row(
        val address: WidgetAddress,
        val regionCode: String?,
        val title: String,
        val subtitle: String?,
    )

    private class RowAdapter(
        context: android.content.Context,
        private val rows: List<Row>,
        private val selected: WidgetAddress?,
    ) : ArrayAdapter<Row>(context, 0, rows) {
        private val inflater = LayoutInflater.from(context)

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val view = convertView
                ?: inflater.inflate(R.layout.widget_config_row, parent, false)
            val row = rows[position]
            view.findViewById<TextView>(R.id.widget_config_section).apply {
                androidx.core.view.ViewCompat.setAccessibilityHeading(this, true)
                visibility = if (position <= 1) View.VISIBLE else View.GONE
                text = context.getString(if (position == 0) R.string.widget_current_location else R.string.widget_config_saved_locations)
            }
            val checked = row.address == selected
            view.isSelected = checked
            val primaryInk = com.google.android.material.color.MaterialColors.getColor(view,
                if (checked) com.google.android.material.R.attr.colorOnPrimaryContainer else androidx.appcompat.R.attr.colorPrimary)
            view.findViewById<com.google.android.material.radiobutton.MaterialRadioButton>(R.id.widget_config_radio).apply {
                isChecked = checked
                buttonTintList = android.content.res.ColorStateList.valueOf(primaryInk)
            }
            view.findViewById<android.widget.ImageView>(R.id.widget_config_icon).apply {
                setImageResource(if (row.address is WidgetAddress.CurrentLocation) R.drawable.ic_widget_location else R.drawable.ic_widget_place)
                setColorFilter(primaryInk)
            }
            view.findViewById<com.google.android.material.card.MaterialCardView>(R.id.widget_config_card).setCardBackgroundColor(
                com.google.android.material.color.MaterialColors.getColor(view,
                    if (checked) com.google.android.material.R.attr.colorPrimaryContainer else com.google.android.material.R.attr.colorSurfaceContainer),
            )
            androidx.core.view.ViewCompat.setAccessibilityDelegate(view,
                object : androidx.core.view.AccessibilityDelegateCompat() {
                    override fun onInitializeAccessibilityNodeInfo(host: View, info: androidx.core.view.accessibility.AccessibilityNodeInfoCompat) {
                        super.onInitializeAccessibilityNodeInfo(host, info)
                        info.isCheckable = true
                        info.isChecked = checked
                        info.className = android.widget.RadioButton::class.java.name
                    }
                })
            view.findViewById<TextView>(android.R.id.text1).apply {
                text = row.title
                setTextColor(com.google.android.material.color.MaterialColors.getColor(view,
                    if (checked) com.google.android.material.R.attr.colorOnPrimaryContainer else com.google.android.material.R.attr.colorOnSurface))
            }
            val subtitle = view.findViewById<TextView>(android.R.id.text2)
            subtitle.setTextColor(com.google.android.material.color.MaterialColors.getColor(view,
                if (checked) com.google.android.material.R.attr.colorOnPrimaryContainer else com.google.android.material.R.attr.colorOnSurfaceVariant))
            if (row.subtitle == null) {
                subtitle.visibility = View.GONE
            } else {
                subtitle.visibility = View.VISIBLE
                subtitle.text = row.subtitle
            }
            return view
        }
    }
}
