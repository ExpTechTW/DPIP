package com.exptech.dpip

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.exptech.dpip/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgets" -> {
                    try {
                        updateAllWidgets()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UPDATE_ERROR", "Failed to update widgets: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * 手動觸發所有 widget 實例的更新
     * 發送 APPWIDGET_UPDATE broadcast 來觸發 onUpdate 方法
     */
    private fun updateAllWidgets() {
        val context = applicationContext
        
        // 更新標準版 widget
        val standardManager = AppWidgetManager.getInstance(context)
        val standardComponent = ComponentName(context, WeatherWidgetProvider::class.java)
        val standardIds = standardManager.getAppWidgetIds(standardComponent)
        if (standardIds.isNotEmpty()) {
            val intent = Intent(context, WeatherWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, standardIds)
            context.sendBroadcast(intent)
        }
        
        // 更新小方形版 widget
        val smallComponent = ComponentName(context, WeatherWidgetSmallProvider::class.java)
        val smallIds = standardManager.getAppWidgetIds(smallComponent)
        if (smallIds.isNotEmpty()) {
            val intent = Intent(context, WeatherWidgetSmallProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, smallIds)
            context.sendBroadcast(intent)
        }
    }
}