package com.exptech.dpip

import android.content.Context
import android.graphics.Bitmap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.maplibre.android.MapLibre
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.Style
import org.maplibre.android.snapshotter.MapSnapshotter
import java.io.ByteArrayOutputStream

/**
 * Renders a MapLibre style to a PNG off-screen via [MapSnapshotter] — the
 * Android counterpart of the iOS `MapSnapshotPlugin`, used for the home map
 * backdrop (a live platform-view map can't be captured and fights the sheet).
 */
class MapSnapshotChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/map_snapshot"
    }

    /** Snapshotters in flight, retained until their callback runs. */
    private val pending = mutableListOf<MapSnapshotter>()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capture" -> capture(call, result)
            else -> result.notImplemented()
        }
    }

    private fun capture(call: MethodCall, result: MethodChannel.Result) {
        val style = call.argument<String>("style")
        val latitude = call.argument<Double>("latitude")
        val longitude = call.argument<Double>("longitude")
        val zoom = call.argument<Double>("zoom")
        val width = call.argument<Double>("width")
        val height = call.argument<Double>("height")
        val pixelRatio = call.argument<Double>("pixelRatio") ?: 1.0
        if (style == null || latitude == null || longitude == null ||
            zoom == null || width == null || height == null
        ) {
            result.error("bad_args", "Missing snapshot arguments", null)
            return
        }

        MapLibre.getInstance(context)

        val options = MapSnapshotter.Options(
            (width * pixelRatio).toInt(),
            (height * pixelRatio).toInt(),
        )
            .withPixelRatio(pixelRatio.toFloat())
            .withStyleBuilder(Style.Builder().fromJson(style))
            .withCameraPosition(
                CameraPosition.Builder()
                    .target(LatLng(latitude, longitude))
                    .zoom(zoom)
                    .build(),
            )

        val snapshotter = MapSnapshotter(context, options)
        pending.add(snapshotter)
        snapshotter.start({ snapshot ->
            pending.remove(snapshotter)
            val stream = ByteArrayOutputStream()
            snapshot.bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            result.success(stream.toByteArray())
        }, { error ->
            pending.remove(snapshotter)
            result.error("snapshot_failed", error, null)
        })
    }
}
