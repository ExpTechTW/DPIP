package com.exptech.dpip

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.concurrent.ConcurrentHashMap

/** Levels the Dart `Log` facade already knows by name. */
enum class NativeLogLevel(val wire: String) {
    DEBUG("debug"),
    INFO("info"),
    WARNING("warning"),
    ERROR("error"),
}

/**
 * What native background code logs through.
 *
 * Callers depend on this, not on a file path. [timeMillis] is the wall clock
 * at the moment the event happened. [FileNativeLog] is the production store,
 * and it does not need a Flutter isolate.
 */
interface NativeLog {
    fun record(level: NativeLogLevel, tag: String, message: String, timeMillis: Long)
}

/** Captures the wall clock at the call, which is the event time. */
fun NativeLog.record(level: NativeLogLevel, tag: String, message: String) {
    record(level, tag, message, System.currentTimeMillis())
}

private data class NativeLogEntry(
    val level: String,
    val tag: String,
    val message: String,
    val timeMillis: Long,
) {
    fun wire(): Map<String, Any> = mapOf(
        "level" to level,
        "tag" to tag,
        "message" to message,
        "time" to timeMillis,
    )
}

/**
 * File-backed ring under the app files directory, so a background receiver
 * can record a line after the process has been killed and the next launch
 * can still read it.
 *
 * The ceiling is 50 lines, the same size as [BgLocationStore]'s breadcrumb
 * ring: this only has to last until the next time the app opens and drains
 * it into `Log`, not for the 24-hour table. A message is clipped at 2000
 * characters and a tag at 64. Oldest lines are dropped.
 *
 * Writers share a lock per path. [take] replaces the file only after the
 * read has returned; a failed replace leaves the previous file in place.
 */
class FileNativeLog(private val file: File) : NativeLog {
    override fun record(
        level: NativeLogLevel,
        tag: String,
        message: String,
        timeMillis: Long,
    ) {
        val clipped = message.take(MAX_MESSAGE_LENGTH)
        if (clipped.isEmpty()) return
        try {
            synchronized(gate(file)) {
                val entries = readEntries().toMutableList()
                entries.add(
                    NativeLogEntry(
                        level = level.wire,
                        tag = tag.take(MAX_TAG_LENGTH),
                        message = clipped,
                        timeMillis = timeMillis,
                    ),
                )
                val kept = if (entries.size > MAX_ENTRIES) {
                    entries.takeLast(MAX_ENTRIES)
                } else {
                    entries
                }
                writeEntries(kept)
            }
        } catch (_: Exception) {
            // A diagnostic must not take down the background work that logged it.
        }
    }

    /**
     * Reads the ring and replaces it with an empty file.
     *
     * The payload is built before the replace. If the replace throws, the
     * previous file is still the one on disk and the caller must not treat
     * the handoff as done.
     */
    fun take(): List<Map<String, Any>> {
        synchronized(gate(file)) {
            val payload = readEntries().map { it.wire() }
            writeEntries(emptyList())
            return payload
        }
    }

    private fun readEntries(): List<NativeLogEntry> {
        if (!file.exists()) return emptyList()
        val text = file.readText(Charsets.UTF_8)
        if (text.isBlank()) return emptyList()
        val array = try {
            JSONArray(text)
        } catch (_: Exception) {
            return emptyList()
        }
        val entries = ArrayList<NativeLogEntry>(array.length())
        for (index in 0 until array.length()) {
            val row = array.optJSONObject(index) ?: continue
            val level = row.optString("level", "")
            val message = row.optString("message", "")
            if (level.isEmpty() || message.isEmpty() || !row.has("time")) continue
            entries.add(
                NativeLogEntry(
                    level = level,
                    tag = row.optString("tag", ""),
                    message = message,
                    timeMillis = row.optLong("time"),
                ),
            )
        }
        return entries
    }

    private fun writeEntries(entries: List<NativeLogEntry>) {
        val array = JSONArray()
        for (entry in entries) {
            array.put(
                JSONObject()
                    .put("level", entry.level)
                    .put("tag", entry.tag)
                    .put("message", entry.message)
                    .put("time", entry.timeMillis),
            )
        }
        val parent = file.parentFile ?: throw IOException("native log has no directory")
        if (!parent.isDirectory && !parent.mkdirs()) {
            throw IOException("native log directory")
        }
        val temporary = File(parent, "${file.name}.tmp")
        temporary.writeText(array.toString(), Charsets.UTF_8)
        try {
            Files.move(
                temporary.toPath(),
                file.toPath(),
                StandardCopyOption.REPLACE_EXISTING,
                StandardCopyOption.ATOMIC_MOVE,
            )
        } catch (_: AtomicMoveNotSupportedException) {
            Files.move(
                temporary.toPath(),
                file.toPath(),
                StandardCopyOption.REPLACE_EXISTING,
            )
        }
    }

    companion object {
        const val MAX_ENTRIES = 50
        const val MAX_MESSAGE_LENGTH = 2000
        const val MAX_TAG_LENGTH = 64
        const val FILE_NAME = "native-log.json"

        private val gates = ConcurrentHashMap<String, Any>()

        private fun gate(file: File): Any {
            val key = file.absolutePath
            return gates.getOrPut(key) { Any() }
        }
    }
}

/** The production buffer. Safe to open from a receiver with no Flutter engine. */
object NativeLogs {
    fun open(context: Context): FileNativeLog =
        FileNativeLog(File(context.applicationContext.filesDir, FileNativeLog.FILE_NAME))
}
