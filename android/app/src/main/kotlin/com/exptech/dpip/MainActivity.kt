package com.exptech.dpip

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.maplibre.android.MapLibre

/**
 * Hosts the app's native platform channels. Each capability that replaces a
 * third-party plugin is registered here against the engine's binary messenger.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // The maplibre_gl fork's HttpRequestImpl class-init calls
        // MapLibre.getApplicationContext(), which throws unless MapLibre was
        // initialized first — and it runs during automatic plugin registration
        // (inside super.onCreate). Init before the engine attaches or startup
        // dies with ExceptionInInitializerError and stalls on the splash.
        // getInstance is idempotent; MapSnapshotChannel re-inits later.
        MapLibre.getInstance(applicationContext)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, DeviceInfoChannel.NAME)
            .setMethodCallHandler(DeviceInfoChannel(applicationContext))

        MethodChannel(messenger, MapSnapshotChannel.NAME)
            .setMethodCallHandler(MapSnapshotChannel(applicationContext))

        MethodChannel(messenger, MapCacheChannel.NAME)
            .setMethodCallHandler(MapCacheChannel(applicationContext))

        MethodChannel(messenger, StorageScanChannel.NAME)
            .setMethodCallHandler(StorageScanChannel(applicationContext))

        MethodChannel(messenger, BackgroundLocationChannel.NAME)
            .setMethodCallHandler(BackgroundLocationChannel(applicationContext))

        MethodChannel(messenger, BatteryOptimizationChannel.NAME)
            .setMethodCallHandler(BatteryOptimizationChannel(applicationContext))

        MethodChannel(messenger, UnusedAppRestrictionsChannel.NAME)
            .setMethodCallHandler(UnusedAppRestrictionsChannel(applicationContext))

        MethodChannel(messenger, BackgroundExecutionChannel.NAME)
            .setMethodCallHandler(BackgroundExecutionChannel(applicationContext))

        // Activity-scoped: the keep-awake window flag belongs to this window.
        MethodChannel(messenger, ScreenWakeChannel.NAME)
            .setMethodCallHandler(ScreenWakeChannel(this))

        EventChannel(messenger, CompassChannel.NAME)
            .setStreamHandler(CompassChannel(applicationContext))
    }
}
