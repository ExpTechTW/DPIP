package com.exptech.dpip

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.maplibre.android.MapLibre
import org.maplibre.android.offline.OfflineManager

/**
 * MapLibre ambient tile-cache bridge — size ceiling only (Android counterpart
 * of iOS `MapCachePlugin`).
 *
 * The app disables ambient caching (`MapCache.disabledBytes`) and serves those
 * bytes from its own store through the MapLibre tile bridge.
 */
class MapCacheChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/map_cache"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setMaximumAmbientCacheSize" -> {
                val bytes = call.argument<Number>("bytes")?.toLong()
                if (bytes == null || bytes < 0) {
                    result.error("bad_args", "Missing bytes", null)
                    return
                }
                MapLibre.getInstance(context)
                OfflineManager.getInstance(context).setMaximumAmbientCacheSize(
                    bytes,
                    object : OfflineManager.FileSourceCallback {
                        override fun onSuccess() = result.success(null)
                        override fun onError(message: String) =
                            result.error("cache_failed", message, null)
                    },
                )
            }
            else -> result.notImplemented()
        }
    }
}
