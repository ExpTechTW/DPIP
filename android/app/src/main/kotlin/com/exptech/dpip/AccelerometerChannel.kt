package com.exptech.dpip

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Streams the accelerometer at about 50 Hz on `com.exptech.dpip/accelerometer`,
 * flushed on the main looper about every 100 ms.
 *
 * Each batch is a [DoubleArray] of `timestampNanos, x, y, z` groups. An
 * interval with no samples sends nothing. Acceleration is gal (m/s² × 100).
 * The timestamp is [SensorEvent.getTimestamp], nanoseconds since boot.
 *
 * Axes are [Sensor.TYPE_ACCELEROMETER]'s device frame, unchanged: +x to the
 * right, +y toward the top of the device, +z out of the screen. They are not
 * rotated into the current screen orientation. A phone at rest, flat, screen
 * up, reads z ≈ +980 gal.
 *
 * Cancelling unregisters the listener and drops the pending flush. No
 * accelerometer, or a listener the system will not register, is an error
 * event with code `unavailable`.
 */
class AccelerometerChannel(context: Context) :
    EventChannel.StreamHandler, SensorEventListener {

    companion object {
        const val NAME = "com.exptech.dpip/accelerometer"

        /** 20 ms. The sensor HAL treats this as a hint, about 50 Hz. */
        private const val SAMPLING_PERIOD_US = 20_000

        /** Deliver each sample as it is taken; this class batches instead. */
        private const val MAX_REPORT_LATENCY_US = 0

        private const val FLUSH_INTERVAL_MS = 100L

        /** 1 gal = 0.01 m/s². */
        private const val GAL_PER_MPS2 = 100.0
    }

    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pending = ArrayList<Double>(32)
    private var sink: EventChannel.EventSink? = null

    private val flush = object : Runnable {
        override fun run() {
            val events = sink ?: return
            if (pending.isNotEmpty()) {
                val batch = pending.toDoubleArray()
                pending.clear()
                events.success(batch)
            }
            if (sink != null) {
                mainHandler.postDelayed(this, FLUSH_INTERVAL_MS)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // A second listen replaces the registration the first one made.
        stop()
        if (events == null) return
        val sensor = accelerometer
        if (sensor == null) {
            events.error("unavailable", "Accelerometer not available", null)
            return
        }
        sink = events
        val registered = sensorManager.registerListener(
            this,
            sensor,
            SAMPLING_PERIOD_US,
            MAX_REPORT_LATENCY_US,
            mainHandler,
        )
        if (!registered) {
            sink = null
            events.error("unavailable", "Accelerometer not available", null)
            return
        }
        mainHandler.postDelayed(flush, FLUSH_INTERVAL_MS)
    }

    override fun onCancel(arguments: Any?) {
        stop()
    }

    private fun stop() {
        sink = null
        mainHandler.removeCallbacks(flush)
        sensorManager.unregisterListener(this)
        pending.clear()
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (sink == null) return
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return
        if (event.values.size < 3) return
        pending.add(event.timestamp.toDouble())
        pending.add(event.values[0].toDouble() * GAL_PER_MPS2)
        pending.add(event.values[1].toDouble() * GAL_PER_MPS2)
        pending.add(event.values[2].toDouble() * GAL_PER_MPS2)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
