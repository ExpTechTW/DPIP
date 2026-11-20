package com.exptech.dpip

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.maplibre.android.MapLibre
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.Style
import org.maplibre.android.snapshotter.MapSnapshot
import org.maplibre.android.snapshotter.MapSnapshotter
import java.io.ByteArrayOutputStream
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit
import kotlin.math.hypot

@RunWith(AndroidJUnit4::class)
class MapSnapshotProjectionTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext
    private val channel = MapSnapshotChannel(context)
    private var nativeControl: MapSnapshotter? = null

    private val style = """
        {"version":8,"sources":{},"layers":[
          {"id":"background","type":"background","paint":{"background-color":"#66bbcc"}}
        ]}
    """.trimIndent()
    private val center = LatLng(22.458492717664083, 120.71)
    private val zoom = 5.806293217527967
    private val points = linkedMapOf(
        "epicenter" to LatLng(22.64, 121.59),
        "west" to LatLng(23.57, 119.56),
        "north" to LatLng(25.08, center.longitude),
        "south" to LatLng(21.90, center.longitude),
        "center" to center,
    )

    @Test
    fun projectsNorthUpInLogicalPixelsAndKeepsLegacyPngAtAllThreeScales() {
        for (scale in 1..3) {
            val args = arguments(scale)
            val response = projected(args)
            val png = response["png"] as ByteArray
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(png, 0, png.size, bounds)
            assertEquals(360 * scale, bounds.outWidth)
            assertEquals(640 * scale, bounds.outHeight)
            assertEquals(bounds.outWidth, response["pngWidth"])
            assertEquals(bounds.outHeight, response["pngHeight"])
            assertEquals(360.0, response["logicalWidth"])
            assertEquals(640.0, response["logicalHeight"])
            assertArrayEquals(png, capture("capture", args - "points").get(30, TimeUnit.SECONDS) as ByteArray)

            val positions = response["points"] as Map<*, *>
            assertEquals(points.keys, positions.keys)
            val control = CompletableFuture<Unit>()
            instrumentation.runOnMainSync {
                MapLibre.getInstance(context)
                val options = MapSnapshotter.Options(360, 640)
                    .withPixelRatio(scale.toFloat())
                    .withLogo(false)
                    .withStyleBuilder(Style.Builder().fromJson(style))
                    .withCameraPosition(
                        CameraPosition.Builder()
                            .target(center)
                            .zoom(zoom)
                            .bearing(0.0)
                            .tilt(0.0)
                            .build(),
                    )
                val snapshotter = MapSnapshotter(context, options)
                nativeControl = snapshotter
                snapshotter.start({ snapshot ->
                    try {
                        val bitmapPng = ByteArrayOutputStream()
                        assertTrue(snapshot.bitmap.compress(Bitmap.CompressFormat.PNG, 100, bitmapPng))
                        assertArrayEquals(png, bitmapPng.toByteArray())
                        comparePoints(snapshot, scale, positions)
                        control.complete(Unit)
                    } catch (error: AssertionError) {
                        control.completeExceptionally(error)
                    } finally {
                        nativeControl = null
                    }
                }, { message ->
                    nativeControl = null
                    control.completeExceptionally(AssertionError(message))
                })
            }
            control.get(30, TimeUnit.SECONDS)
        }
    }

    @Test
    fun rejectsInvalidCoordinatesAndDuplicateIds() {
        val original = arguments(2)
        val invalid = mapOf("id" to "invalid", "latitude" to Double.NaN, "longitude" to 121.5)
        val duplicate = mapOf("id" to "same", "latitude" to 22.64, "longitude" to 121.59)
        for (points in listOf(emptyList(), listOf(invalid), listOf(duplicate, duplicate))) {
            val response = capture("captureWithProjection", original + ("points" to points))
            assertEquals("bad_args", response.get(30, TimeUnit.SECONDS))
        }
    }

    @Test
    fun reportsNativeStyleFailureThroughProjectionCapture() {
        val response = capture("captureWithProjection", arguments(2) + ("style" to "invalid JSON"))
        assertEquals("snapshot_failed", response.get(30, TimeUnit.SECONDS))
    }

    @Test
    fun keepsConcurrentSnapshotsPairedWithTheirCameraAndDimensions() {
        val first = capture("captureWithProjection", arguments(1))
        val second = capture("captureWithProjection", arguments(3) + ("zoom" to 7.0))
        val lowZoom = first.get(30, TimeUnit.SECONDS) as Map<*, *>
        val highZoom = second.get(30, TimeUnit.SECONDS) as Map<*, *>
        assertEquals(360, lowZoom["pngWidth"])
        assertEquals(1080, highZoom["pngWidth"])
        fun eastOffset(response: Map<*, *>): Double {
            val locations = response["points"] as Map<*, *>
            return ((locations["epicenter"] as List<*>)[0] as Double) - 180
        }
        assertEquals(
            eastOffset(lowZoom) * Math.pow(2.0, 7.0 - zoom),
            eastOffset(highZoom),
            0.01,
        )
    }

    private fun comparePoints(snapshot: MapSnapshot, scale: Int, projected: Map<*, *>) {
        for ((id, coordinate) in points) {
            val reference = snapshot.pixelForLatLng(coordinate)
            val point = projected[id] as List<*>
            val x = point[0] as Double
            val y = point[1] as Double
            val error = hypot(x - reference.x.toDouble() / scale, y - reference.y.toDouble() / scale)
            assertTrue("$id at ${scale}x: $error logical px", error < 0.001)
            // Three points on the camera's meridian must stay on one column.
            when (id) {
                "north" -> {
                    assertEquals(180.0, x, 0.001)
                    assertTrue(y < 320.0)
                }
                "south" -> {
                    assertEquals(180.0, x, 0.001)
                    assertTrue(y > 320.0)
                }
                "center" -> {
                    assertEquals(180.0, x, 0.001)
                    assertEquals(320.0, y, 0.001)
                }
            }
        }
    }

    private fun arguments(scale: Int): Map<String, Any> = mapOf(
        "style" to style,
        "latitude" to center.latitude,
        "longitude" to center.longitude,
        "zoom" to zoom,
        "width" to 360.0,
        "height" to 640.0,
        "pixelRatio" to scale.toDouble(),
        "showLogo" to false,
        "points" to points.map { (id, coordinate) ->
            mapOf("id" to id, "latitude" to coordinate.latitude, "longitude" to coordinate.longitude)
        },
    )

    private fun projected(args: Map<String, Any>): Map<*, *> =
        capture("captureWithProjection", args).get(30, TimeUnit.SECONDS) as Map<*, *>

    private fun capture(method: String, args: Map<String, Any>): CompletableFuture<Any?> {
        val response = CompletableFuture<Any?>()
        instrumentation.runOnMainSync {
            channel.onMethodCall(MethodCall(method, args), object : MethodChannel.Result {
                override fun success(result: Any?) { response.complete(result) }
                override fun error(code: String, message: String?, details: Any?) {
                    response.complete(code)
                }
                override fun notImplemented() {
                    response.completeExceptionally(AssertionError("$method is not implemented"))
                }
            })
        }
        return response
    }
}
