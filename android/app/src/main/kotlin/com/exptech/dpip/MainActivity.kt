package com.exptech.dpip

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.exptech.dpip/location"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "startForegroundService" -> {
                        try {
                            val intent = Intent(this, LocationForegroundService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.error("SERVICE_START_FAIL", e.localizedMessage, null)
                        }
                    }

                    "stopForegroundService" -> {
                        try {
                            val intent = Intent(this, LocationForegroundService::class.java)
                            stopService(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.error("SERVICE_STOP_FAIL", e.localizedMessage, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
