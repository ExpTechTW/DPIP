package com.exptech.dpip

import android.content.Intent
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
                        val intent = Intent(this, LocationForegroundService::class.java)
                        startForegroundService(intent)
                        result.success(null)
                    }

                    "stopForegroundService" -> {
                        val intent = Intent(this, LocationForegroundService::class.java)
                        stopService(intent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
