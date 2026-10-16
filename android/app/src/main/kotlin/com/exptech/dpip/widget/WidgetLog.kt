package com.exptech.dpip.widget

import android.content.Context
import com.exptech.dpip.NativeLog
import com.exptech.dpip.NativeLogLevel
import com.exptech.dpip.NativeLogs

/**
 * The Widget's diagnostics, through the app's existing native log ring.
 *
 * `NativeLogs.open(context)` is the 50-line file ring under the app's files
 * directory that Dart drains into `Log` on the next launch (`NativeLogChannel`,
 * and the iOS `FileNativeLog` equivalent). Using it rather than `android.util.Log`
 * is the difference between a Widget failure the user reports and one that
 * reaches the App 日誌 page: the Widget's refresh runs in a background worker
 * with no engine attached, so logcat is the only other destination and the user
 * cannot read it.
 *
 * What is logged is deliberately narrow: the operation, the snapshot kind, the
 * source identifier, the township code and the exception *class*. Never a
 * coordinate — a diagnostic must not become a location record, and the plan
 * requires the Widget's logs not to carry precise positions.
 *
 * The sink is overridable so a unit test can assert the lines without touching
 * the filesystem.
 */
object WidgetLog {
    const val TAG = "Widget"

    /** Test seam. Null means the production ring. */
    internal var overrideSink: ((Context) -> NativeLog)? = null

    fun debug(context: Context, message: String) =
        record(context, NativeLogLevel.DEBUG, message)

    fun info(context: Context, message: String) =
        record(context, NativeLogLevel.INFO, message)

    fun warning(context: Context, message: String) =
        record(context, NativeLogLevel.WARNING, message)

    fun error(context: Context, message: String) =
        record(context, NativeLogLevel.ERROR, message)

    fun record(context: Context, level: NativeLogLevel, message: String) {
        val sink = overrideSink?.invoke(context) ?: NativeLogs.open(context)
        sink.record(level, TAG, message, System.currentTimeMillis())
    }

    fun resetForTest() {
        overrideSink = null
    }
}

/** The exception's class name, which is all a log line needs of it. */
internal fun Throwable.logName(): String = javaClass.simpleName ?: "Throwable"
