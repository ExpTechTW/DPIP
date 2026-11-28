package com.exptech.dpip

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import java.io.File
import java.io.IOException

class ClipboardImageProvider : FileProvider()

/**
 * Clipboard receivers open the URI after the sharing dialog has gone away.
 * Keep up to four recent copies in their own private cache directory. Prune
 * on startup, before every copy, and at expiry while the app process is alive.
 */
internal class ClipboardImageStore(private val context: Context) {
    private val directory = File(context.cacheDir, "clipboard-images")
    private val handler = Handler(Looper.getMainLooper())
    private val expiry = Runnable { cleanUp() }

    init {
        cleanUp()
    }

    fun copyPng(bytes: ByteArray) {
        require(bytes.size <= MAX_PNG_BYTES) { "PNG exceeds the clipboard size limit" }
        if (!directory.isDirectory && !directory.mkdirs()) {
            throw IOException("Could not create the clipboard directory")
        }
        pruneExpired()
        files().sortedByDescending(File::lastModified).drop(MAX_FILES - 1).forEach {
            if (!it.delete()) throw IOException("Could not evict an old clipboard image")
        }

        val file = File.createTempFile("image-", ".png", directory)
        try {
            file.writeBytes(bytes)
            val uri = FileProvider.getUriForFile(
                context, "${context.packageName}.clipboard-images", file, "DPIP.png",
            )
            val clipboard = context.getSystemService(ClipboardManager::class.java)
                ?: throw IOException("Clipboard unavailable")
            // The clipboard service grants per-URI read access to receivers.
            clipboard.setPrimaryClip(ClipData.newUri(context.contentResolver, "DPIP", uri))
        } catch (error: Exception) {
            file.delete()
            throw error
        }
        cleanUp()
    }

    private fun files(): List<File> =
        directory.listFiles { file -> file.isFile && file.extension == "png" }?.toList().orEmpty()

    private fun cleanUp() {
        handler.removeCallbacks(expiry)
        pruneExpired()
        val now = System.currentTimeMillis()
        val next = files().map { it.lastModified() + RETENTION_MILLIS }
            .filter { it > now }.minOrNull()
        if (next != null) handler.postDelayed(expiry, (next - now).coerceAtLeast(1_000L))
    }

    private fun pruneExpired() {
        val cutoff = System.currentTimeMillis() - RETENTION_MILLIS
        files().filter { it.lastModified() <= cutoff }.forEach { it.delete() }
    }

    companion object {
        private const val MAX_FILES = 4
        private const val MAX_PNG_BYTES = 16 * 1024 * 1024
        private const val RETENTION_MILLIS = 60 * 60 * 1000L
    }
}
