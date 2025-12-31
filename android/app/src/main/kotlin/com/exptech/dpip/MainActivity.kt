package com.exptech.dpip

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.exptech.dpip/shortcut"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getInitialShortcut") {
                    val shortcut = getSharedPreferences("shortcut", MODE_PRIVATE)
                        .getString("initialShortcut", null)
                    result.success(shortcut)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val shortcut = intent?.getStringExtra("shortcut")
        if (shortcut != null) {
            getSharedPreferences("shortcut", MODE_PRIVATE)
                .edit()
                .putString("initialShortcut", shortcut)
                .apply()
        }
    }
}
