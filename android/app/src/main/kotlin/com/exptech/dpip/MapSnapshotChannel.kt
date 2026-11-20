package com.exptech.dpip

import android.content.Context
import android.graphics.Bitmap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.maplibre.android.MapLibre
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.Style
import org.maplibre.android.snapshotter.MapSnapshot
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
            "capture", "captureWithProjection" -> capture(call, result)
            else -> result.notImplemented()
        }
    }

    private fun capture(call: MethodCall, result: MethodChannel.Result) {
        val style = call.argument<Any>("style") as? String
        val latitude = (call.argument<Any>("latitude") as? Number)?.toDouble()
        val longitude = (call.argument<Any>("longitude") as? Number)?.toDouble()
        val zoom = (call.argument<Any>("zoom") as? Number)?.toDouble()
        val width = (call.argument<Any>("width") as? Number)?.toDouble()
        val height = (call.argument<Any>("height") as? Number)?.toDouble()
        val requestedRatio = (call.argument<Any>("pixelRatio") as? Number)?.toDouble()
        val pixelRatio = requestedRatio ?: 1.0
        if (style == null || latitude == null || longitude == null ||
            zoom == null || width == null || height == null
        ) {
            result.error("bad_args", "Missing snapshot arguments", null)
            return
        }

        val points = if (call.method == "captureWithProjection") {
            val coordinates = projectionPoints(call.argument<Any>("points"))
            if (coordinates == null || !validCoordinate(latitude, longitude) ||
                !zoom.isFinite() || requestedRatio !in listOf(1.0, 2.0, 3.0) ||
                !validDimension(width, pixelRatio) || !validDimension(height, pixelRatio)
            ) {
                result.error("bad_args", "Invalid snapshot viewport, camera or points", null)
                return
            }
            coordinates
        } else {
            null
        }

        MapLibre.getInstance(context)

        val camera = CameraPosition.Builder()
            .target(LatLng(latitude, longitude))
            .zoom(zoom)
        if (points != null) {
            // MapLibre uses an unset bearing of -1° in the native Snapshot.
            // Story's camera fit assumes a north-up, unpitched viewport.
            camera.bearing(0.0).tilt(0.0)
        }

        // Options takes the logical viewport; MapLibre scales the output bitmap.
        val options = MapSnapshotter.Options(width.toInt(), height.toInt())
            .withPixelRatio(pixelRatio.toFloat())
            .withLogo(call.argument<Boolean>("showLogo") ?: true)
            .withStyleBuilder(Style.Builder().fromJson(style))
            .withCameraPosition(camera.build())

        val snapshotter = MapSnapshotter(context, options)
        pending.add(snapshotter)
        snapshotter.start({ snapshot ->
            pending.remove(snapshotter)
            val stream = ByteArrayOutputStream()
            val encoded = snapshot.bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            if (points == null) {
                result.success(stream.toByteArray())
            } else if (!encoded) {
                result.error("no_image", "Snapshot PNG encoding failed", null)
            } else {
                val response = projectionResponse(
                    snapshot, stream.toByteArray(), width, height, pixelRatio, points,
                )
                if (response == null) {
                    result.error("invalid_projection", "Invalid snapshot dimensions or points", null)
                } else {
                    result.success(response)
                }
            }
        }, { error ->
            pending.remove(snapshotter)
            result.error("snapshot_failed", error, null)
        })
    }

    private fun projectionPoints(raw: Any?): Map<String, LatLng>? {
        if (raw !is List<*> || raw.isEmpty()) return null
        val points = mutableMapOf<String, LatLng>()
        for (item in raw) {
            val point = item as? Map<*, *> ?: return null
            val id = point["id"] as? String ?: return null
            val latitude = (point["latitude"] as? Number)?.toDouble() ?: return null
            val longitude = (point["longitude"] as? Number)?.toDouble() ?: return null
            if (id.isEmpty() || id in points || !validCoordinate(latitude, longitude)) return null
            points[id] = LatLng(latitude, longitude)
        }
        return points
    }

    private fun validCoordinate(latitude: Double, longitude: Double): Boolean =
        latitude in -90.0..90.0 && longitude in -180.0..180.0

    private fun validDimension(value: Double, pixelRatio: Double): Boolean =
        value >= 1 && value <= Int.MAX_VALUE / pixelRatio && value % 1 == 0.0

    private fun projectionResponse(
        snapshot: MapSnapshot,
        png: ByteArray,
        width: Double,
        height: Double,
        pixelRatio: Double,
        points: Map<String, LatLng>,
    ): Map<String, Any>? {
        val pngWidth = snapshot.bitmap.width
        val pngHeight = snapshot.bitmap.height
        if (pngWidth != (width * pixelRatio).toInt() ||
            pngHeight != (height * pixelRatio).toInt()
        ) return null

        // MapLibre's Android JNI returns physical bitmap coordinates.
        val projected = points.mapValues { (_, coordinate) ->
            val pixel = snapshot.pixelForLatLng(coordinate)
            if (!pixel.x.isFinite() || !pixel.y.isFinite()) return null
            listOf(pixel.x * width / pngWidth, pixel.y * height / pngHeight)
        }
        return mapOf(
            "png" to png,
            "pngWidth" to pngWidth,
            "pngHeight" to pngHeight,
            "logicalWidth" to width,
            "logicalHeight" to height,
            "points" to projected,
        )
    }
}
