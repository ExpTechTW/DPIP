package com.exptech.dpip

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.maplibre.android.MapLibre
import org.maplibre.android.offline.OfflineManager

/**
 * MapLibre ambient tile-cache bridge — size ceiling + preload (Android
 * counterpart of iOS `MapCachePlugin`).
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
            "preload" -> {
                val url = call.argument<String>("url")
                val data = call.argument<ByteArray>("data")
                if (url.isNullOrEmpty() || data == null) {
                    result.error("bad_args", "Missing url/data", null)
                    return
                }
                val etag = call.argument<String>("etag")
                val modified = call.argument<Number>("modified")?.toLong() ?: 0L
                val expires = call.argument<Number>("expires")?.toLong() ?: 0L
                val mustRevalidate = call.argument<Boolean>("mustRevalidate") ?: false
                MapLibre.getInstance(context)
                OfflineManager.getInstance(context).putResourceWithUrl(
                    url,
                    data,
                    modified,
                    expires,
                    etag,
                    mustRevalidate,
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
