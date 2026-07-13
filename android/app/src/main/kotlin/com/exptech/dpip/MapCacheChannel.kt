package com.exptech.dpip

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.maplibre.android.MapLibre
import org.maplibre.android.offline.OfflineManager

/**
 * Raises MapLibre's shared ambient tile-cache ceiling via [OfflineManager] — the
 * Android counterpart of iOS `MapCachePlugin`. maplibre_gl exposes no size bound
 * and the native default is only ~50 MB, so a bigger ceiling keeps more radar
 * frames cached and scrubbing re-fetches less. Writes to the same shared cache
 * the map view and the home snapshot read.
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
