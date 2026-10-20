package com.exptech.dpip.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.FrameLayout
import android.widget.RemoteViews
import android.widget.TextView
import com.exptech.dpip.MainActivity
import com.exptech.dpip.R

/**
 * Maps a decided [WidgetPresentation] onto `RemoteViews`.
 *
 * This is the only place that knows a view id, and it sets only the ids its
 * chosen layout actually has: a `RemoteViews` action aimed at a missing view
 * throws when the launcher applies it, and the throw is the launcher's, so the
 * Widget would simply stop updating with nothing in this process to show for
 * it. [weatherWidgetLayoutTest] applies every layout for that reason.
 *
 * Two tap targets, each with its own identity:
 *
 * * the whole surface opens the app;
 * * a refresh glyph asks for a one-time refresh of **this** instance's source.
 *
 * Reconfiguration belongs to the launcher's long-press menu. Launchers without
 * that affordance require removing and adding the widget again.
 */
object WidgetRenderer {
    /** The action the surface tap carries, for the app's own route handling. */
    const val ACTION_OPEN_HOME = "com.exptech.dpip.widget.OPEN_HOME"

    /** The broadcast the refresh glyph sends to [WeatherWidgetProvider]. */
    const val ACTION_REFRESH = "com.exptech.dpip.widget.REFRESH"

    fun layoutFor(sizeClass: WidgetSizeClass): Int = when (sizeClass) {
        WidgetSizeClass.Small -> R.layout.widget_small
        WidgetSizeClass.Medium -> R.layout.widget_medium
        WidgetSizeClass.Large -> R.layout.widget_large
    }

    /**
     * The layout a presentation draws in.
     *
     * The empty face is one document for every family, exactly as iOS branches
     * to the same cloud view in all three; the compact form is only reachable
     * for `Small`, where [WidgetPresentation.compactLayout] says the measured
     * box cannot hold the normal one.
     */
    fun layoutFor(presentation: WidgetPresentation): Int {
        if (!presentation.hasObservation) return R.layout.widget_empty
        if (presentation.sizeClass == WidgetSizeClass.Small) {
            if (presentation.compactLayout) {
                return if (presentation.adaptiveCompact) R.layout.widget_small_compact_accessible
                else R.layout.widget_small_compact
            }

            if (presentation.effectiveHeightDp >= 240) {
                return R.layout.widget_small_tall
            }

            return R.layout.widget_small
        }
        if (presentation.sizeClass == WidgetSizeClass.Large) {
            // iOS's section spacing only fits a roomy box; the minimal-height
            // large cell uses the tightened document.
            return if (presentation.effectiveHeightDp >=
                WidgetPresenter.largeRoomyMinimumHeightDp
            ) {
                R.layout.widget_large
            } else {
                R.layout.widget_large_tight
            }
        }
        return layoutFor(presentation.sizeClass)
    }

    fun render(
        context: Context,
        presentation: WidgetPresentation,
        appWidgetId: Int,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layoutFor(presentation))
        // The root carries `@android:id/background` (not an app id) so the
        // launcher can run its Android 12+ widget-to-app transition; the id is
        // still the surface tap target and the TalkBack node.
        views.setOnClickPendingIntent(android.R.id.background, openAppIntent(context, appWidgetId))
        // The surface summarizes current weather; hourly forecasts expose their
        // own groups so a reader can navigate them one hour at a time.
        views.setCharSequence(
            android.R.id.background,
            "setContentDescription",
            contentDescription(context, presentation),
        )
        renderActions(context, views, presentation, appWidgetId)

        if (!presentation.hasObservation) {
            renderEmpty(context, views, presentation)
            return views
        }

        views.setTextViewText(R.id.widget_location, presentation.locationName.orEmpty())
        setLocationIcon(views, presentation.isCurrentLocation, context)
        views.setTextViewText(
            R.id.widget_observation_time,
            observationLine(presentation),
        )
        views.setContentDescription(
            R.id.widget_observation_time,
            presentation.observationTimeMillis?.let(WidgetPresenter::observationDescription),
        )
        setBadge(views, if (presentation.sizeClass == WidgetSizeClass.Small && presentation.compactLayout) {
            compactStatus(context, presentation)
        } else presentation.badgeText)
        views.setTextViewText(R.id.widget_temperature, presentation.temperatureText.orEmpty())
        views.setImageViewResource(
            R.id.widget_icon,
            iconResource(presentation.condition, presentation.isNight),
        )
        views.setInt(R.id.widget_icon, "setColorFilter", secondary(context))

        if (presentation.sizeClass == WidgetSizeClass.Small && presentation.compactLayout) {
            views.setTextViewText(R.id.widget_humidity_value, presentation.humidityText.orEmpty())
            views.setTextViewText(R.id.widget_rain_value, presentation.rainText.orEmpty())
            tint(views, R.id.widget_humidity, context)
            tint(views, R.id.widget_rain, context)
            if (presentation.adaptiveCompact) {
                // Always reset both rows on reapply, including after resize.
                views.setViewVisibility(R.id.widget_compact_header, View.VISIBLE)
                views.setViewVisibility(R.id.widget_compact_metrics, View.VISIBLE)
                val secondaryVisibility = if (compactNeedsFallback(context, presentation, views)) View.GONE else View.VISIBLE
                views.setViewVisibility(R.id.widget_compact_header, secondaryVisibility)
                views.setViewVisibility(R.id.widget_compact_metrics, secondaryVisibility)
            }
            return views
        }

        views.setTextViewText(R.id.widget_weather, presentation.weatherText.orEmpty())

        when (presentation.sizeClass) {
            WidgetSizeClass.Small -> {
                views.setTextViewText(
                    R.id.widget_humidity_value,
                    presentation.humidityText.orEmpty(),
                )
                tint(views, R.id.widget_humidity, context)
                views.setTextViewText(R.id.widget_rain_value, presentation.rainText.orEmpty())
                tint(views, R.id.widget_rain, context)
            }

            WidgetSizeClass.Medium -> {
                setOptionalText(views, R.id.widget_apparent, presentation.apparentText)
                renderForecast(context, views, presentation, R.layout.widget_forecast_item)
            }

            WidgetSizeClass.Large -> {
                setOptionalText(views, R.id.widget_apparent, presentation.apparentText)
                views.setTextViewText(
                    R.id.widget_grid_humidity_value,
                    presentation.humidityText.orEmpty(),
                )
                views.setTextViewText(
                    R.id.widget_grid_rain_value,
                    presentation.rainText.orEmpty(),
                )
                views.setTextViewText(
                    R.id.widget_grid_sun_label,
                    presentation.sunLabel.orEmpty(),
                )
                views.setTextViewText(
                    R.id.widget_grid_sun_value,
                    presentation.sunValue.orEmpty(),
                )
                views.setTextViewText(
                    R.id.widget_grid_wind_value,
                    presentation.windText.orEmpty(),
                )
                views.setTextViewText(
                    R.id.widget_grid_station_value,
                    presentation.stationText.orEmpty(),
                )
                renderForecast(context, views, presentation, R.layout.widget_forecast_item_large)
            }
        }
        return views
    }

    /**
     * Measure the bound four-row document before publishing it. Character counts
     * and linear dp/fontScale envelopes cannot model weighted metric columns,
     * fallback fonts or Android 14+'s nonlinear sp conversion. Keep Android view
     * work here, rather than introducing a Context into the pure presentation.
     *
     * This detached, single-pass probe uses the same resources, actions and box
     * as the host; it does not attach a window or draw, start refresh work, or
     * depend on a later layout traversal. Only enlarged Compact pays this cost.
     * Long place names retain the existing header ellipsis policy; the clock,
     * status and numeric readings must fit whole at the XML's autosize floors.
     */
    private fun compactNeedsFallback(
        context: Context,
        presentation: WidgetPresentation,
        views: RemoteViews,
    ): Boolean {
        val probe = views.apply(context, FrameLayout(context))
        val density = context.resources.displayMetrics.density
        val width = (presentation.availableWidthDp * density).toInt()
        val height = (presentation.availableHeightDp * density).toInt()
        probe.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        probe.layout(0, 0, width, height)
        return listOf(
            R.id.widget_observation_time, R.id.widget_stale, R.id.widget_temperature,
            R.id.widget_humidity_value, R.id.widget_rain_value,
        ).any { id ->
            val text = probe.findViewById<TextView>(id)
            if (text.visibility != View.VISIBLE || text.text.isEmpty()) return@any false
            val layout = text.layout ?: return@any true
            val contentHeight = text.height - text.compoundPaddingTop - text.compoundPaddingBottom
            val contentWidth = text.width - text.compoundPaddingLeft - text.compoundPaddingRight
            layout.height > contentHeight || (0 until layout.lineCount).any { line ->
                layout.getEllipsisCount(line) != 0 || layout.getLineLeft(line) < 0 ||
                    layout.getLineRight(line) > contentWidth
            }
        }
    }

    /** The empty face: the cloud and the presenter's message, in secondary ink. */
    private fun renderEmpty(
        context: Context,
        views: RemoteViews,
        presentation: WidgetPresentation,
    ) {
        views.setTextViewText(
            R.id.widget_empty_message,
            presentation.badgeText ?: presentation.hintText.orEmpty(),
        )
        views.setInt(R.id.widget_empty_icon, "setColorFilter", secondary(context))
    }

    /** The Taipei observation clock, with the position hint when present. */
    private fun observationLine(presentation: WidgetPresentation): String = buildString {
        val observation = presentation.observationTimeMillis
        if (observation != null) {
            append(WidgetPresenter.observationText(observation))
        }
        val hint = presentation.hintText
        if (isNotEmpty() && hint != null) append("  ·  ")
        if (hint != null) append(hint)
    }

    /** Fixed-size feedback: the launcher animates the ProgressBar, not our worker. */
    private fun renderActions(
        context: Context,
        views: RemoteViews,
        presentation: WidgetPresentation,
        appWidgetId: Int,
    ) {
        val feedback = presentation.refreshFeedback
        val busy = feedback == WidgetRefreshFeedback.Queued || feedback == WidgetRefreshFeedback.Running
        val visible = presentation.showRefresh
        val actionable = visible && presentation.canRefresh && !busy
        // Reapply must clear an old click binding as well as collapse its box.
        views.setViewVisibility(R.id.widget_refresh, if (visible) View.VISIBLE else View.GONE)
        views.setOnClickPendingIntent(R.id.widget_refresh, if (actionable) refreshIntent(context, appWidgetId) else null)
        views.setBoolean(R.id.widget_refresh, "setEnabled", actionable)
        views.setContentDescription(context, feedback)
        views.setViewVisibility(R.id.widget_refresh_icon, if (busy) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.widget_refresh_progress, if (busy) View.VISIBLE else View.GONE)
        views.setProgressBar(R.id.widget_refresh_progress, 0, 0, true)
        views.setImageViewResource(
            R.id.widget_refresh_icon,
            if (feedback == WidgetRefreshFeedback.Failed) R.drawable.ic_widget_refresh_failed
            else R.drawable.ic_widget_refresh,
        )
        views.setInt(R.id.widget_refresh_icon, "setColorFilter", secondary(context))
        if (!presentation.hasObservation || presentation.sizeClass == WidgetSizeClass.Small) return
        // Only roomy content boxes can spend 48dp on each action without
        // taking the town's width or the forecast's height. Pre-S keeps its
        // bounded XML targets; dynamic layout-param actions are API 31+.
        val roomy = presentation.effectiveWidthDp >= 300 &&
            presentation.effectiveHeightDp >= if (presentation.sizeClass == WidgetSizeClass.Medium) 230 else 400
        if (android.os.Build.VERSION.SDK_INT >= 31) {
            // RemoteViews may reapply onto the previous layout during resize:
            // restoring the XML defaults is an action too, not just an omission.
            val size = context.resources.getDimension(
                if (roomy) R.dimen.widget_icon_action_touch
                else if (presentation.sizeClass == WidgetSizeClass.Medium) R.dimen.widget_icon_action_target
                else R.dimen.widget_icon_action_target_large,
            )
            val padding = context.resources.getDimensionPixelSize(
                if (roomy) R.dimen.widget_action_padding_empty else R.dimen.widget_spacing_xs,
            )
            for (id in listOf(R.id.widget_refresh)) {
                views.setViewLayoutWidth(id, size, android.util.TypedValue.COMPLEX_UNIT_PX)
                views.setViewLayoutHeight(id, size, android.util.TypedValue.COMPLEX_UNIT_PX)
                views.setViewPadding(id, padding, padding, padding, padding)
            }
        }
    }

    private fun RemoteViews.setContentDescription(context: Context, feedback: WidgetRefreshFeedback?) {
        setContentDescription(R.id.widget_refresh, context.getString(when (feedback) {
            WidgetRefreshFeedback.Queued -> R.string.widget_refresh_queued
            WidgetRefreshFeedback.Running -> R.string.widget_refresh_running
            WidgetRefreshFeedback.Updated -> R.string.widget_refresh_updated
            WidgetRefreshFeedback.Failed -> R.string.widget_refresh_failed
            null -> R.string.widget_refresh
        }))
    }

    private fun renderForecast(
        context: Context,
        views: RemoteViews,
        presentation: WidgetPresentation,
        itemLayout: Int,
    ) {
        views.removeAllViews(R.id.widget_forecast_container)
        val tint = secondary(context)
        for (point in presentation.forecast) {
            val item = RemoteViews(context.packageName, itemLayout)
            item.setTextViewText(R.id.widget_forecast_time, point.time)
            item.setImageViewResource(
                R.id.widget_forecast_icon,
                iconResource(point.condition, point.isNight),
            )
            item.setContentDescription(R.id.widget_forecast_icon, conditionDescription(context, point.condition))
            item.setInt(R.id.widget_forecast_icon, "setColorFilter", tint)
            item.setTextViewText(R.id.widget_forecast_temperature, point.temperatureText)
            item.setTextViewText(R.id.widget_forecast_pop, point.popText)
            item.setContentDescription(
                R.id.widget_forecast_pop,
                if (point.popText == "—") context.getString(R.string.widget_forecast_pop_unavailable)
                else context.getString(R.string.widget_forecast_pop_description, point.popText),
            )
            views.addView(R.id.widget_forecast_container, item)
        }
    }

    /**
     * Sets a line that may not be there, and collapses it when it is not.
     *
     * An empty `TextView` still occupies a line, so "the layout drops what it
     * cannot fit" means `GONE`, not empty text: the row has to give its height
     * back to the rows that are still shown.
     */
    private fun setOptionalText(views: RemoteViews, viewId: Int, text: String?) {
        if (text.isNullOrEmpty()) {
            views.setViewVisibility(viewId, View.GONE)
            return
        }
        views.setViewVisibility(viewId, View.VISIBLE)
        views.setTextViewText(viewId, text)
    }

    private fun setLocationIcon(views: RemoteViews, isCurrentLocation: Boolean, context: Context) {
        if (isCurrentLocation) {
            views.setViewVisibility(R.id.widget_location_icon, View.VISIBLE)
            views.setInt(R.id.widget_location_icon, "setColorFilter", secondary(context))
        } else {
            views.setViewVisibility(R.id.widget_location_icon, View.GONE)
        }
    }

    private fun setBadge(views: RemoteViews, text: String?) {
        if (text == null) {
            views.setViewVisibility(R.id.widget_stale, View.GONE)
            return
        }
        views.setViewVisibility(R.id.widget_stale, View.VISIBLE)
        views.setTextViewText(R.id.widget_stale, text)
    }

    private fun tint(views: RemoteViews, viewId: Int, context: Context) {
        views.setInt(viewId, "setColorFilter", secondary(context))
    }

    /**
     * The glyph for a condition and phase, from the bundled vector set.
     *
     * Never a Material `Icons` codepoint and never a system drawable: the
     * renderer runs in the launcher's process, where the app's bundled font is
     * not resolvable, and a system drawable's name is not a stable contract
     * across OEM builds. `WeatherCondition.Unknown` — which an unrecognised
     * code maps to — has its own neutral marker rather than a guessed glyph,
     * the same rule DESIGN.md states for the Flutter weather font.
     */
    private fun iconResource(condition: WeatherCondition?, isNight: Boolean): Int = when (condition) {
        WeatherCondition.Clear ->
            if (isNight) R.drawable.ic_widget_weather_clear_night
            else R.drawable.ic_widget_weather_clear_day

        WeatherCondition.Cloudy ->
            if (isNight) R.drawable.ic_widget_weather_cloudy_night
            else R.drawable.ic_widget_weather_cloudy_day

        WeatherCondition.Overcast -> R.drawable.ic_widget_weather_overcast
        WeatherCondition.Rain -> R.drawable.ic_widget_weather_rain
        WeatherCondition.Thunderstorm -> R.drawable.ic_widget_weather_thunderstorm
        WeatherCondition.Snow -> R.drawable.ic_widget_weather_snow
        WeatherCondition.Fog -> R.drawable.ic_widget_weather_fog
        WeatherCondition.Unknown, null -> R.drawable.ic_widget_weather_unknown
    }

    private fun secondary(context: Context): Int = context.getColor(R.color.widget_secondary)

    /** Mirrors the glyph's meaning in the system language, not the API's text. */
    private fun conditionDescription(context: Context, condition: WeatherCondition): String =
        context.getString(when (condition) {
            WeatherCondition.Clear -> R.string.widget_weather_clear
            WeatherCondition.Cloudy -> R.string.widget_weather_cloudy
            WeatherCondition.Overcast -> R.string.widget_weather_overcast
            WeatherCondition.Rain -> R.string.widget_weather_rain
            WeatherCondition.Thunderstorm -> R.string.widget_weather_thunderstorm
            WeatherCondition.Snow -> R.string.widget_weather_snow
            WeatherCondition.Fog -> R.string.widget_weather_fog
            WeatherCondition.Unknown -> R.string.widget_weather_unknown
        })

    /**
     * The surface's TalkBack label: the readings it draws, and — when it has
     * nothing to name — the Widget's own name.
     *
     * Only the non-blank fields are joined, in a fixed order, so the first
     * reading never inherits a separator written for a later one. The fallback
     * is the localized `widget_name` rather than a literal: the description is
     * announced in the system language, so an English default here would speak
     * English at a reader whose entire Widget is translated.
     */
    private fun contentDescription(context: Context, presentation: WidgetPresentation): String {
        val compact = presentation.hasObservation &&
            presentation.sizeClass == WidgetSizeClass.Small && presentation.compactLayout
        return listOf(
            presentation.locationName,
            if (compact && presentation.isCurrentLocation) context.getString(R.string.widget_current_location) else null,
            if (compact) presentation.condition?.let { conditionDescription(context, it) } ?: presentation.weatherText
            else presentation.weatherText,
            presentation.temperatureText,
            presentation.observationTimeMillis?.let(WidgetPresenter::observationDescription),
            if (compact) presentation.humidityText?.let { "${context.getString(R.string.widget_humidity)} $it" } else null,
            if (compact) presentation.rainText?.let { "${context.getString(R.string.widget_rain)} $it" } else null,
            presentation.badgeText,
            if (compact) presentation.hintText else null,
            if (compact) context.getString(R.string.widget_compact_details) else null,
        )
            .mapNotNull { it?.trim() }
            .filter { it.isNotEmpty() }
            .let { if (compact) it.distinct() else it }
            .joinToString(", ")
            .ifEmpty { context.getString(R.string.widget_name) }
    }

    /** Short visual labels; the full degradation message stays on the surface. */
    private fun compactStatus(context: Context, presentation: WidgetPresentation): String? {
        if (presentation.badgeText == null) return null
        return context.getString(when {
            presentation.isStale -> if (presentation.adaptiveCompact) R.string.widget_compact_stale
                else return presentation.badgeText
            presentation.state == WidgetDisplayState.LocationUnavailable -> R.string.widget_compact_location
            presentation.state == WidgetDisplayState.NeedsApp -> R.string.widget_compact_attention
            else -> return presentation.badgeText
        })
    }

    /**
     * The tap targets, each unique per instance **and per action**.
     *
     * `IMMUTABLE` because nothing downstream rewrites the intent — Android 12+
     * refuses a mutable one from a creator that does not opt in, and an implicit
     * intent would let another app's activity receive the tap. The request code
     * is derived from the instance id, so two Widgets cannot share one
     * `PendingIntent`, which `FLAG_UPDATE_CURRENT` would otherwise rewrite to
     * whichever instance rendered last.
     */
    private fun openAppIntent(context: Context, appWidgetId: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_HOME
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode(appWidgetId, REQUEST_OPEN),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun refreshIntent(context: Context, appWidgetId: Int): PendingIntent {
        // An explicit broadcast to this app's own provider: no other app can
        // receive it, and it carries the id rather than a location.
        val intent = Intent(context, WeatherWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode(appWidgetId, REQUEST_REFRESH),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun requestCode(appWidgetId: Int, action: Int): Int =
        (appWidgetId and 0x0FFF_FFFF) * 4 + action

    private const val REQUEST_OPEN = 1
    private const val REQUEST_REFRESH = 3
}
