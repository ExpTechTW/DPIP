package com.exptech.dpip

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

/**
 * Saves encoded image bytes into the device's photo library.
 *
 * The counterpart of iOS's `ImageSaverPlugin`, and the same channel name and
 * protocol, so the Dart side is one implementation and the platform is the only
 * difference. The bytes are the ones the app already fetched (the CWA report
 * image), so nothing here downloads anything.
 *
 * Two paths, because the storage model changed in Android 10:
 *
 * - **API 29+** writes through MediaStore with `RELATIVE_PATH`, which needs no
 *   storage permission at all and lets the gallery index the file itself. The
 *   row is inserted as `IS_PENDING` and published only once the bytes are
 *   written, so a camera roll can never pick up a half-written image.
 * - **API 26–28** writes into the public Pictures directory, which does need
 *   `WRITE_EXTERNAL_STORAGE` (declared `maxSdkVersion="28"`). Losing that grant
 *   is reported as `permission_denied` rather than guessed at here: Dart asks
 *   for the permission and retries once.
 *
 * Nothing is overwritten. A name that already exists gets a ` (n)` suffix, the
 * way a desktop file manager would — saving the same report twice is a normal
 * thing to do, and silently replacing the first copy is not.
 */
class ImageSaverChannel(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/image_saver"

        /** The album the saved pictures land in, shared with iOS's asset album. */
        private const val ALBUM = "DPIP"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "save" -> save(call, result)
            "status" -> result.success(status())
            else -> result.notImplemented()
        }
    }

    /**
     * Whether a save can be written right now.
     *
     * API 29+ needs no permission (`granted` unconditionally): MediaStore owns
     * the write, and the manifest caps `WRITE_EXTERNAL_STORAGE` at 28 so asking
     * on a newer device would be a prompt nobody can grant. Only the legacy
     * public-directory path reports `denied`, which is what the Dart side turns
     * into a runtime request.
     */
    private fun status(): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ||
            context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            "granted"
        } else {
            "denied"
        }

    private fun save(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType") ?: "image/png"
        if (bytes == null || bytes.isEmpty() || fileName.isNullOrBlank()) {
            result.error("invalid_args", "bytes and fileName are required", null)
            return
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveToMediaStore(bytes, fileName, mimeType)
            } else {
                saveToPicturesDirectory(bytes, fileName, mimeType)
            }
            result.success(null)
        } catch (error: SecurityException) {
            // The legacy grant, and only that: API 29+ needs no permission, so
            // reaching this there means something else refused the write.
            result.error("permission_denied", error.message, null)
        } catch (error: Exception) {
            result.error("save_failed", error.message, null)
        }
    }

    /** API 29+: one MediaStore row, published after the bytes are written. */
    private fun saveToMediaStore(bytes: ByteArray, fileName: String, mimeType: String) {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_PICTURES}/$ALBUM",
            )
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("MediaStore refused the image entry")

        try {
            val stream = resolver.openOutputStream(uri)
                ?: throw IOException("MediaStore could not open the image for writing")
            stream.use { it.write(bytes) }
        } catch (error: Exception) {
            // A failed write must not leave a pending row behind: it would be
            // invisible to the gallery and never cleaned up by it.
            resolver.delete(uri, null, null)
            throw error
        }

        resolver.update(
            uri,
            ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) },
            null,
            null,
        )
    }

    /** API 26–28: the public Pictures directory, then tell the gallery about it. */
    private fun saveToPicturesDirectory(bytes: ByteArray, fileName: String, mimeType: String) {
        if (context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException("WRITE_EXTERNAL_STORAGE is not granted")
        }
        if (Environment.getExternalStorageState() != Environment.MEDIA_MOUNTED) {
            throw IOException("External storage is not mounted")
        }

        val album = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
            ALBUM,
        )
        if (!album.exists() && !album.mkdirs()) {
            throw IOException("Could not create the $ALBUM album")
        }

        val file = uniqueFile(album, fileName)
        file.writeBytes(bytes)
        // Writes outside MediaStore are invisible until something tells the
        // gallery to index them; without this the picture exists but no Photos
        // app lists it.
        MediaScannerConnection.scanFile(context, arrayOf(file.absolutePath), arrayOf(mimeType), null)
    }

    /** [fileName] in [directory], or the first `name (n).ext` that is free. */
    private fun uniqueFile(directory: File, fileName: String): File {
        val candidate = File(directory, fileName)
        if (!candidate.exists()) return candidate

        val dot = fileName.lastIndexOf('.')
        val base = if (dot > 0) fileName.substring(0, dot) else fileName
        val extension = if (dot > 0) fileName.substring(dot) else ""
        var index = 1
        while (true) {
            val next = File(directory, "$base ($index)$extension")
            if (!next.exists()) return next
            index++
        }
    }
}
