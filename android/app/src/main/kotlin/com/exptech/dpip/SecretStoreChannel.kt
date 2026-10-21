package com.exptech.dpip

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.GeneralSecurityException
import java.security.KeyStore
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Secrets the user hands the app — today the AI chat's API key.
 *
 * The AES-GCM key is generated inside the Android Keystore and never leaves
 * it; this class only ever holds ciphertext, written to `noBackupFilesDir` so
 * that even with backups enabled the file would stay on this device. Each file
 * is the 12-byte IV followed by the ciphertext and its tag.
 *
 * A file the Keystore can no longer decrypt (its key was invalidated, e.g. by
 * removing the lock screen) is deleted and read back as absent: there is
 * nothing else to be done with it, and the user simply enters the key again.
 *
 * Keystore work runs off the main thread; results are posted back to it.
 */
class SecretStoreChannel(context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/secret_store"
        private const val KEY_ALIAS = "dpip_secret_store_v1"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val IV_BYTES = 12
        private const val TAG_BITS = 128

        /** Secret names are a fixed set on the Dart side; this keeps a bad
         *  one from naming a path outside the secrets directory. */
        private val SAFE_NAME = Regex("^[A-Za-z0-9._-]{1,64}$")
    }

    private val directory = File(context.noBackupFilesDir, "secrets")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("key")
        if (name == null || !SAFE_NAME.matches(name)) {
            result.error("bad_key", "missing or invalid key name", null)
            return
        }
        when (call.method) {
            "read" -> run(result) { read(name) }
            "write" -> {
                val value = call.argument<String>("value")
                if (value == null) {
                    result.error("bad_value", "missing value", null)
                    return
                }
                run(result) { write(name, value); null }
            }
            "delete" -> run(result) { fileFor(name).delete(); null }
            else -> result.notImplemented()
        }
    }

    private fun run(result: MethodChannel.Result, work: () -> String?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (error: Exception) {
                // The class name only: a message could quote what failed.
                main.post {
                    result.error("failed", error.javaClass.simpleName, null)
                }
            }
        }
    }

    private fun fileFor(name: String) = File(directory, "$name.bin")

    private fun read(name: String): String? {
        val file = fileFor(name)
        if (!file.exists()) return null
        val bytes = file.readBytes()
        if (bytes.size <= IV_BYTES) {
            file.delete()
            return null
        }
        return try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(
                Cipher.DECRYPT_MODE,
                existingKey() ?: run { file.delete(); return null },
                GCMParameterSpec(TAG_BITS, bytes, 0, IV_BYTES),
            )
            String(
                cipher.doFinal(bytes, IV_BYTES, bytes.size - IV_BYTES),
                Charsets.UTF_8,
            )
        } catch (error: GeneralSecurityException) {
            file.delete()
            null
        }
    }

    private fun write(name: String, value: String) {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, existingKey() ?: newKey())
        val sealed = cipher.iv + cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        directory.mkdirs()
        // Write beside, then rename: a crash mid-write must not leave a file
        // that fails its tag and erases the previous key on the next read.
        val staging = File(directory, "$name.tmp")
        staging.writeBytes(sealed)
        if (!staging.renameTo(fileFor(name))) {
            staging.delete()
            throw IllegalStateException("rename failed")
        }
    }

    private fun existingKey(): SecretKey? {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        return store.getKey(KEY_ALIAS, null) as SecretKey?
    }

    private fun newKey(): SecretKey {
        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore",
        )
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }
}
