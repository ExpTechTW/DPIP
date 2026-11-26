package com.exptech.dpip

import android.app.AlertDialog
import android.content.ClipboardManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.SystemClock
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.ByteArrayOutputStream
import java.io.File
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ClipboardImageOnDeviceTest {
    @Test
    fun clipboardCanReadOriginalPngAfterDialogAndShareCleanup() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val png = ByteArrayOutputStream().also { stream ->
            val bitmap = Bitmap.createBitmap(3, 2, Bitmap.Config.ARGB_8888)
            bitmap.eraseColor(0xff204060.toInt())
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            bitmap.recycle()
        }.toByteArray()
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            lateinit var dialog: AlertDialog
            scenario.onActivity { activity ->
                dialog = AlertDialog.Builder(activity).setTitle("Export").show()
                ClipboardImageStore(activity.applicationContext).copyPng(png)
                val shareDir = File(activity.cacheDir, "dpip-earthquake-share-test")
                shareDir.mkdirs()
                File(shareDir, "export.png").writeBytes(png)
                shareDir.deleteRecursively()
                dialog.dismiss()
            }
            instrumentation.waitForIdleSync()
            // Clipboard reads on Android require a foreground window.
            var clipboard: android.content.ClipData? = null
            repeat(60) {
                if (clipboard == null) {
                    scenario.onActivity { activity ->
                        clipboard = activity.getSystemService(ClipboardManager::class.java).primaryClip
                    }
                    if (clipboard == null) SystemClock.sleep(50)
                }
            }
            scenario.onActivity { activity ->
                assertFalse(dialog.isShowing)
                assertNotNull(clipboard)
                val uri = clipboard!!.getItemAt(0).uri
                assertEquals("${activity.packageName}.clipboard-images", uri.authority)
                assertEquals("image/png", activity.contentResolver.getType(uri))
                val received = activity.contentResolver.openInputStream(uri)!!.use { it.readBytes() }
                assertArrayEquals(png, received)
                val image = BitmapFactory.decodeByteArray(received, 0, received.size)
                try {
                    assertEquals(3, image.width)
                    assertEquals(2, image.height)
                } finally {
                    image.recycle()
                }
                activity.getSystemService(ClipboardManager::class.java).clearPrimaryClip()
            }
        }
    }
}
