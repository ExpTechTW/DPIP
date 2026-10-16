package com.exptech.dpip

import android.content.Intent
import android.os.Bundle
import com.exptech.dpip.widget.WidgetRenderer
import com.exptech.dpip.widget.WidgetSnapshotChannel
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
    /**
     * The channel that tells Dart a home-screen Widget was tapped.
     *
     * Created with the engine, so the action that *started* the process cannot be
     * delivered until then — `onCreate` only remembers that it must be. A warm
     * tap arrives through `onNewIntent` and goes out immediately.
     */
    private var widgetHomeChannel: MethodChannel? = null
    private var pendingWidgetHome = false

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // The maplibre_gl fork's HttpRequestImpl class-init calls
        // MapLibre.getApplicationContext(), which throws unless MapLibre was
        // initialized first — and it runs during automatic plugin registration
        // (inside super.onCreate). Init before the engine attaches or startup
        // dies with ExceptionInInitializerError and stalls on the splash.
        // getInstance is idempotent; MapSnapshotChannel re-inits later.
        MapLibre.getInstance(applicationContext)
        pendingWidgetHome = intent?.action == WidgetRenderer.ACTION_OPEN_HOME
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == WidgetRenderer.ACTION_OPEN_HOME) {
            deliverWidgetHome()
        }
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

        MethodChannel(messenger, PermissionSettingsChannel.NAME)
            .setMethodCallHandler(PermissionSettingsChannel(applicationContext))

        MethodChannel(messenger, UnusedAppRestrictionsChannel.NAME)
            .setMethodCallHandler(UnusedAppRestrictionsChannel(this))

        MethodChannel(messenger, BackgroundExecutionChannel.NAME)
            .setMethodCallHandler(BackgroundExecutionChannel(applicationContext))

        // Activity-scoped: the keep-awake window flag belongs to this window.
        MethodChannel(messenger, ScreenWakeChannel.NAME)
            .setMethodCallHandler(ScreenWakeChannel(this))

        EventChannel(messenger, CompassChannel.NAME)
            .setStreamHandler(CompassChannel(applicationContext))

        EventChannel(messenger, NetworkChannel.NAME)
            .setStreamHandler(NetworkChannel(applicationContext))

        MethodChannel(messenger, PlainChannelsChannel.NAME)
            .setMethodCallHandler(PlainChannelsChannel(applicationContext))

        MethodChannel(messenger, NativeLogChannel.NAME)
            .setMethodCallHandler(NativeLogChannel(applicationContext))

        // The snapshot bridge for the home-screen Widget. Same channel name and
        // protocol as iOS's WidgetSnapshotPlugin, so the Dart writer is one
        // implementation and the platform is the only difference.
        MethodChannel(messenger, WidgetSnapshotChannel.NAME)
            .setMethodCallHandler(WidgetSnapshotChannel(applicationContext))

        widgetHomeChannel = MethodChannel(messenger, WIDGET_HOME_CHANNEL)
        if (pendingWidgetHome) {
            pendingWidgetHome = false
            deliverWidgetHome()
        }
    }

    private fun deliverWidgetHome() {
        widgetHomeChannel?.invokeMethod("openHome", null)
    }

    companion object {
        /** The same name `WidgetHomeIntent.channel` uses on the Dart side. */
        const val WIDGET_HOME_CHANNEL = "com.exptech.dpip/widget_home"
    }
}
