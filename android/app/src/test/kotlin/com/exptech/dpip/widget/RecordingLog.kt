package com.exptech.dpip.widget

import com.exptech.dpip.NativeLog
import com.exptech.dpip.NativeLogLevel

/**
 * A `NativeLog` that keeps its lines in a list.
 *
 * The Widget logs through the app's file-backed ring so a background failure
 * reaches the in-app log; a test installs this instead
 * (`WidgetLog.overrideSink`) so it can assert the lines without a file system.
 */
class RecordingLog(val lines: MutableList<String> = ArrayList()) : NativeLog {
    override fun record(
        level: NativeLogLevel,
        tag: String,
        message: String,
        timeMillis: Long,
    ) {
        lines.add(message)
    }

    fun contains(fragment: String): Boolean = lines.any { it.contains(fragment) }
}
