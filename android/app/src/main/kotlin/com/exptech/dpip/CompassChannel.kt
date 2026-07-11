package com.exptech.dpip

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Surface
import android.view.WindowManager
import kotlin.math.abs
import io.flutter.plugin.common.EventChannel

/**
 * Streams device heading (degrees clockwise from magnetic north) from the
 * fused rotation-vector sensor, replacing the `flutter_compass` plugin.
 */
class CompassChannel(private val context: Context) :
    EventChannel.StreamHandler, SensorEventListener {

    companion object {
        const val NAME = "com.exptech.dpip/compass"
    }

    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val rotationSensor: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

    private var sink: EventChannel.EventSink? = null
    private val rotationMatrix = FloatArray(9)
    private val remapped = FloatArray(9)
    private val orientation = FloatArray(3)
    private var lastEmitted = Double.NaN

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        val sensor = rotationSensor
        if (sensor == null) {
            events?.error("UNAVAILABLE", "Rotation-vector sensor not available", null)
            return
        }
        sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ROTATION_VECTOR) return
        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)

        val (axisX, axisY) = when (displayRotation()) {
            Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
            Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
            Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
            else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
        }
        SensorManager.remapCoordinateSystem(rotationMatrix, axisX, axisY, remapped)
        SensorManager.getOrientation(remapped, orientation)

        var azimuth = Math.toDegrees(orientation[0].toDouble())
        if (azimuth < 0) azimuth += 360.0

        // Throttle to ~1° changes to avoid flooding the channel.
        if (lastEmitted.isNaN() || abs(azimuth - lastEmitted) >= 1.0) {
            lastEmitted = azimuth
            sink?.success(mapOf("heading" to azimuth, "accuracy" to null))
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    @Suppress("DEPRECATION")
    private fun displayRotation(): Int {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        return wm.defaultDisplay.rotation
    }
}
