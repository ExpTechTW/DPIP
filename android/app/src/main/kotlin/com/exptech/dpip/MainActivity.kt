package com.exptech.dpip

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the app's native platform channels. Each capability that replaces a
 * third-party plugin is registered here against the engine's binary messenger.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, DeviceInfoChannel.NAME)
            .setMethodCallHandler(DeviceInfoChannel(applicationContext))

        MethodChannel(messenger, MapSnapshotChannel.NAME)
            .setMethodCallHandler(MapSnapshotChannel(applicationContext))

        EventChannel(messenger, CompassChannel.NAME)
            .setStreamHandler(CompassChannel(applicationContext))
    }
}
