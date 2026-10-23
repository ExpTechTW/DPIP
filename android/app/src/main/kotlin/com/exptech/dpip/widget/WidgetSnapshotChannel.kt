package com.exptech.dpip.widget

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * The Flutter → native snapshot bridge.
 *
 * It is a **boundary**, not a feature: the payload is already encoded and
 * versioned by Dart, and this class decides only whether it is a thing it knows
 * (kind, schema, size) and where it belongs. No App Group path, database file
 * name or SQL crosses it, exactly as on iOS — the Dart side names a kind and a
 * source, never a location.
 *
 * Storage work runs on a single-threaded executor because SQLite writes here are
 * transactional and there is nothing to gain from parallel ones; the reply is
 * posted back to the main thread, which is where the platform channel expects it.
 *
 * Every outcome is mapped deliberately:
 *
 * * `invalid_kind` / `invalid_payload` — the payload is refused.
 * * `write_failed` — the store could not perform the write. This is the case the
 *   first version could not report: a database failure came back as "rejected",
 *   indistinguishable from losing an ordering race, and Dart was told the write
 *   had succeeded.
 * * success — including a *superseded* write, which iOS reports the same way: a
 *   newer refresh on this device won the ordering race, which is normal and not
 *   something the app can act on. It is logged, not raised.
 */
class WidgetSnapshotChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "write" -> handleWrite(call, result)
            "clear" -> handleClear(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleWrite(call: MethodCall, result: MethodChannel.Result) {
        val rawKind = call.argument<String>("kind")
        val json = call.argument<String>("json")
        val sourceIdentifier = call.argument<String>("sourceIdentifier")

        val kind = WidgetSnapshotKind.fromWire(rawKind)
        if (kind == null) {
            reply(result, error("invalid_kind", "kind=$rawKind"))
            return
        }
        if (json == null) {
            reply(result, error("invalid_payload", "missing json"))
            return
        }

        executor.execute {
            reply(result, guarded("write kind=${kind.wire}") { write(kind, json, sourceIdentifier) })
        }
    }

    private fun handleClear(call: MethodCall, result: MethodChannel.Result) {
        val kind = WidgetSnapshotKind.fromWire(call.argument<String>("kind"))
        if (kind == null) {
            reply(result, error("invalid_kind", call.argument<String>("kind")))
            return
        }
        val rawSource = call.argument<String>("sourceIdentifier")

        // This channel supports source-scoped clear only for currentWeather.
        // Forecasts are also stored per source, but clearForecast clears every
        // source, and the catalog is global. Reject unsupported combinations
        // before any side effect rather than silently widening a scoped clear.
        if (rawSource != null && kind != WidgetSnapshotKind.CurrentWeather) {
            reply(result, error("invalid_payload", "source for ${kind.wire}"))
            return
        }

        val address = if (rawSource == null) {
            null
        } else {
            WidgetAddress.fromSourceIdentifier(rawSource)
                ?: run {
                    reply(result, error("invalid_payload", "source"))
                    return
                }
        }

        executor.execute {
            reply(
                result,
                guarded("clear kind=${kind.wire}") {
                    val store = WidgetStore.open(context)
                    val cleared = when (kind) {
                        WidgetSnapshotKind.CurrentWeather -> if (address == null) {
                            store.clearCurrentWeather()
                        } else {
                            store.clearCurrentWeatherSource(address)
                        }
                        WidgetSnapshotKind.WeatherForecast -> store.clearForecast()
                        // Clearing the catalog is "there are no saved locations":
                        // the same code path a publish with an empty list takes,
                        // so the fence on a removed town is applied here too.
                        WidgetSnapshotKind.LocationCatalog ->
                            store.writeCatalog(emptyList(), System.currentTimeMillis())
                    }

                    WidgetUpdater.updateAll(context)
                    if (cleared) null else error("write_failed", "clear kind=${kind.wire}")
                },
            )
        }
    }

    /**
     * Runs one storage task and turns anything it throws into `write_failed`.
     *
     * The reply is the point. Dart serialises its publishes behind the future
     * this channel completes (`WidgetLocationCatalogCoordinator`'s pending-write
     * chain), so a task that escapes with an exception does not merely lose its
     * own result — `result` is never completed and every later publish queues
     * behind a future that will never resolve. The platform channel has no
     * timeout to rescue it.
     *
     * A backstop, not the only guard: the store's own writes answer `false`
     * rather than throwing, and `WidgetUpdater.updateInstance` catches the
     * launcher's own failures. What reaches here is everything *between* them —
     * opening the store, asking the launcher for its ids, and whatever a future
     * caller adds to these tasks. Deliberately `Throwable`: this is the top of an
     * executor task, where the alternative to catching is an uncaught-exception
     * handler that cannot reply.
     */
    private fun guarded(operation: String, body: () -> FlutterErrorLike?): FlutterErrorLike? {
        return try {
            body()
        } catch (failure: Throwable) {
            WidgetLog.error(
                context,
                "channel failed operation=$operation error=${failure.logName()}",
            )
            error("write_failed", operation)
        }
    }

    /** Applies one write; returns null on success or the Dart-facing error. */
    private fun write(
        kind: WidgetSnapshotKind,
        json: String,
        sourceIdentifier: String?,
    ): FlutterErrorLike? {
        val store = WidgetStore.open(context)
        val now = System.currentTimeMillis()

        return when (kind) {
            WidgetSnapshotKind.CurrentWeather -> {
                val snapshot = WidgetSnapshotDecoder.decodeCurrentWeather(json)
                    ?: return error("invalid_payload", "currentWeather")
                if (sourceIdentifier != null && snapshot.sourceIdentifier != sourceIdentifier) {
                    return error("invalid_payload", "source mismatch")
                }

                val address = snapshot.address ?: return error("invalid_payload", "source")
                val token = store.beginCurrentWeatherWrite(address)
                    ?: return error("write_failed", "begin currentWeather")
                when (store.commitCurrentWeather(token, snapshot, now)) {
                    WidgetWriteResult.Written -> {
                        WidgetUpdater.updateAddress(context, address)
                        // Only a source some instance is actually showing earns a
                        // fetch. The app publishes for its own selected region,
                        // which often has no Widget on the home screen at all —
                        // enqueuing for it would spend location, clock and HTTP
                        // work on a screen that does not exist.
                        if (store.hasInstanceFor(address)) {
                            WidgetRefreshScheduler.scheduleOneTime(context, address)
                        } else {
                            WidgetLog.info(
                                context,
                                "write cached without a widget source=${address.sourceIdentifier}",
                            )
                        }
                    }
                    WidgetWriteResult.Superseded -> WidgetLog.info(
                        context,
                        "current weather write superseded source=${address.sourceIdentifier}",
                    )
                    WidgetWriteResult.Failed ->
                        return error("write_failed", "currentWeather")
                }
                null
            }

            WidgetSnapshotKind.WeatherForecast -> {
                val forecast = WidgetSnapshotDecoder.decodeForecast(json)
                    ?: return error("invalid_payload", "forecast")
                val address = forecast.address ?: return error("invalid_payload", "source")
                // The deadline has to be fixed in calibrated time now, or not at
                // all: storing a device-time receipt would let a later refresh's
                // offset move it. An unanchored clock therefore refuses the write
                // rather than recording a deadline it cannot vouch for.
                val receivedCalibrated = WidgetClock.calibratedNowMilliseconds()
                    ?: return error("write_failed", "clock unavailable")
                val token = store.beginForecastWrite(address)
                    ?: return error("write_failed", "begin forecast")
                val expiresAt = WidgetDeadlines.forecastExpiry(
                    updateTimeMilliseconds = forecast.updateTime,
                    receivedCalibratedMilliseconds = receivedCalibrated,
                )
                when (store.commitForecast(token, forecast, receivedCalibrated, expiresAt, now)) {
                    WidgetWriteResult.Written -> {
                        WidgetUpdater.updateAddress(context, address)
                        store.setForecastDemand(address, demand = false, updatedAt = now)
                    }
                    WidgetWriteResult.Superseded -> WidgetLog.info(
                        context,
                        "forecast write superseded source=${address.sourceIdentifier}",
                    )
                    WidgetWriteResult.Failed -> return error("write_failed", "forecast")
                }
                null
            }

            WidgetSnapshotKind.LocationCatalog -> {
                val locations = WidgetSnapshotDecoder.decodeLocationCatalog(json)
                    ?: return error("invalid_payload", "catalog")
                if (!store.writeCatalog(locations, now)) {
                    return error("write_failed", "catalog")
                }
                // A removed town turns its instances into "reconfigure", so the
                // whole surface is redrawn, not only the ones Dart named.
                WidgetUpdater.updateAll(context)
                null
            }
        }
    }

    private fun reply(result: MethodChannel.Result, failure: FlutterErrorLike?) {
        mainHandler.post {
            if (failure == null) {
                result.success(null)
            } else {
                result.error(failure.code, failure.message, null)
            }
        }
    }

    private fun error(code: String, message: String?) = FlutterErrorLike(code, message)

    /** A platform-channel error, kept out of Flutter's own type for testability. */
    data class FlutterErrorLike(val code: String, val message: String?)

    companion object {
        const val NAME = "com.exptech.dpip/widget_snapshot"

        /**
         * One write thread for the whole process, not one per Activity.
         *
         * A channel is constructed for every `FlutterEngine`, and an Activity
         * recreation builds a new engine — so a per-instance executor would leak
         * one thread per recreation. Serialising all writes is also what the
         * store wants: its transactions are cheap and ordering them costs
         * nothing.
         */
        private val executor: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "widget-snapshot")
        }
    }
}
