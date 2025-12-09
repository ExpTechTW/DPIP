package com.exptech.dpip

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * DPIP 天氣桌面小部件 (小方形版)
 * 2x2 尺寸的緊湊版本
 */
class WeatherWidgetSmallProvider : AppWidgetProvider() {

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
         * 更新單個小部件 (小方形版)
         */
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // 從 SharedPreferences 讀取資料
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.weather_widget_small)

            // 檢查是否有錯誤或沒有資料
            val hasError = widgetData.getBoolean("has_error", false)
            val hasData = widgetData.contains("temperature")

            if (hasError || !hasData) {
                val errorMessage = widgetData.getString("error_message", "無法載入")
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

                // 天氣圖示
                val weatherCode = widgetData.getInt("weather_code", 1)
                val iconRes = WeatherWidgetProvider.getWeatherIcon(weatherCode)
                views.setImageViewResource(R.id.weather_icon, iconRes)
            }

            // 點擊小部件開啟 App
            val pendingIntent = es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_container_small, pendingIntent)

            // 更新小部件
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
