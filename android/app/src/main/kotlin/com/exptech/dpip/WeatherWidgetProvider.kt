package com.exptech.dpip

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * DPIP 天氣桌面小部件
 * 顯示即時天氣資訊
 */
class WeatherWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // 更新所有小部件實例
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // 第一次添加小部件時呼叫
    }

    override fun onDisabled(context: Context) {
        // 最後一個小部件被移除時呼叫
    }

    companion object {
        /**
         * 更新單個小部件
         */
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // 從 SharedPreferences 讀取資料
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.weather_widget)

            // 檢查是否有錯誤或沒有資料
            val hasError = widgetData.getBoolean("has_error", false)
            val hasData = widgetData.contains("temperature")

            if (hasError || !hasData) {
                val errorMessage = widgetData.getString("error_message", "無法載入天氣")
                views.setTextViewText(R.id.weather_status, errorMessage)
                views.setTextViewText(R.id.temperature, "--°")
            } else {
                // 天氣狀態
                val weatherStatus = widgetData.getString("weather_status", "晴天")
                views.setTextViewText(R.id.weather_status, weatherStatus)

                // 溫度
                val temperature = widgetData.readIntValue("temperature") ?: 0
                views.setTextViewText(R.id.temperature, "${temperature}°")

                // 體感溫度
                val feelsLike = widgetData.readIntValue("feels_like") ?: 0
                views.setTextViewText(R.id.feels_like, "體感 ${feelsLike}°")

                // 濕度
                val humidity = widgetData.readIntValue("humidity") ?: 0
                views.setTextViewText(R.id.humidity, "${humidity}%")

                // 風速
                val windSpeed = widgetData.readNumber("wind_speed") ?: 0.0
                views.setTextViewText(R.id.wind_speed, String.format("%.1fm/s", windSpeed))

                // 風向
                val windDirection = widgetData.getString("wind_direction", "-")
                views.setTextViewText(R.id.wind_direction, windDirection)

                // 降雨
                val rain = widgetData.readNumber("rain") ?: 0.0
                views.setTextViewText(R.id.rain, String.format("%.1fmm", rain))

                // 氣象站
                val stationName = widgetData.getString("station_name", "")
                val stationDistance = widgetData.readNumber("station_distance") ?: 0.0
                views.setTextViewText(
                    R.id.station_info,
                    "${stationName}氣象站 · ${String.format("%.1f", stationDistance)}km"
                )

                // 更新時間
                val updateTime = widgetData.readTimestampMillis("update_time")
                if (updateTime != null && updateTime > 0) {
                    val calendar = java.util.Calendar.getInstance()
                    calendar.timeInMillis = updateTime
                    val timeStr = String.format(
                        "%02d:%02d",
                        calendar.get(java.util.Calendar.HOUR_OF_DAY),
                        calendar.get(java.util.Calendar.MINUTE)
                    )
                    views.setTextViewText(R.id.update_time, timeStr)
                }

                // 天氣圖示 (根據 weatherCode 設定)
                val weatherCode = widgetData.getInt("weather_code", 1)
                val iconRes = getWeatherIcon(weatherCode)
                views.setImageViewResource(R.id.weather_icon, iconRes)
            }

            // 點擊小部件開啟 App
            val pendingIntent = es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            // 更新小部件
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /**
         * 根據天氣代碼返回對應圖示
         * 對應到 Flutter 的 WeatherIcons.getWeatherIcon
         */
        fun getWeatherIcon(code: Int): Int {
            return when (code) {
                1 -> android.R.drawable.ic_menu_day  // 晴天
                2, 3 -> android.R.drawable.ic_partial_secure  // 多雲
                4, 5, 6, 7 -> android.R.drawable.ic_dialog_alert  // 陰天/霧
                8, 9, 10, 11, 12, 13, 14 -> android.R.drawable.ic_dialog_info  // 雨天
                15, 16, 17, 18 -> android.R.drawable.ic_lock_power_off  // 雷雨
                else -> android.R.drawable.ic_menu_day
            }
            // 注意: 實際使用時應該使用自訂圖示,這裡使用系統圖示作為範例
        }
    }
}
