package com.exptech.dpip

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * App-owned channel that scans the app's on-disk usage (Android Settings
 * reports the same numbers) and clears the system HTTP cache. The big
 * consumers on Android are the SQLite ETag cache in [Context.cacheDir] and
 * MapLibre's own database under [Context.filesDir].
 */
class StorageScanChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "com.exptech.dpip/storage_scan"

        /** Files above this size are reported individually by `scan`. */
        private const val TOP_FILE_FLOOR = 512 * 1024L

        /** Hard cap on visited files so a pathological tree can't hang the channel. */
        private const val VISIT_CAP = 100_000
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scan" -> result.success(scan())
            "configure" -> result.success(null)
            "clearSystemHttpCache" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    private fun scan(): Map<String, Any> {
        val dirs = listOf(context.cacheDir, context.filesDir).filterNotNull()
        val dirEntries = mutableListOf<Map<String, Any>>()
        val topFiles = mutableListOf<Pair<String, Long>>()
        var total = 0L
        for (dir in dirs) {
            val walked = walk(dir)
            dirEntries.add(mapOf("path" to dir.absolutePath, "bytes" to walked.first))
            total += walked.first
            topFiles.addAll(walked.second)
        }
        topFiles.sortByDescending { it.second }
        return mapOf(
            "totalBytes" to total,
            "dirs" to dirEntries,
            "files" to topFiles.take(30).map {
                mapOf("path" to it.first, "bytes" to it.second)
            },
        )
    }

    /** One pass over [root]: total file bytes plus every file above the floor. */
    private fun walk(root: File): Pair<Long, List<Pair<String, Long>>> {
        var bytes = 0L
        val top = mutableListOf<Pair<String, Long>>()
        val stack = ArrayDeque<File>()
        stack.add(root)
        var visited = 0
        while (stack.isNotEmpty()) {
            val dir = stack.removeLast()
            val children = dir.listFiles() ?: continue
            for (child in children) {
                visited++
                if (visited > VISIT_CAP) return bytes to top
                if (child.isDirectory) {
                    stack.add(child)
                } else {
                    val size = child.length()
                    if (size > 0) {
                        bytes += size
                        if (size >= TOP_FILE_FLOOR) {
                            top.add(child.absolutePath to size)
                        }
                    }
                }
            }
        }
        return bytes to top
    }
}
