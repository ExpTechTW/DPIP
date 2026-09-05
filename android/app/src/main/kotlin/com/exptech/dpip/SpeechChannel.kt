package com.exptech.dpip

import android.content.Context
import android.media.AudioManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.atomic.AtomicInteger

/**
 * Speaks a short phrase and reports when it has finished, for the foreground
 * EEW announcement that must complete before the warning sound plays.
 *
 * `android.speech.tts.TextToSpeech` directly rather than a package: the only
 * pub package with this API ships no Swift Package Manager support, which the
 * iOS half of this app needs, so both halves are owned here instead.
 *
 * One utterance at a time. A `speak` while another is in flight flushes it, and
 * the flushed call still returns normally — the caller's contract is
 * latest-report-wins, so a superseded phrase is the expected path rather than
 * an error. Every `speak` replies exactly once, which the channel requires, and
 * every reply is posted to the main thread: `UtteranceProgressListener` fires
 * on a binder thread, and a `MethodChannel.Result` answered from there is a
 * crash rather than a warning.
 */
class SpeechChannel(context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "com.exptech.dpip/speech"
    }

    private val main = Handler(Looper.getMainLooper())
    private val ids = AtomicInteger()

    /** The reply owed to the utterance in flight, or null when none is. */
    private var pending: MethodChannel.Result? = null
    private var pendingId: String? = null

    /**
     * The engine's init result, or null while it is still starting.
     *
     * `TextToSpeech` binds to the system engine asynchronously and rejects
     * everything until it is connected. The first announcement is the one that
     * matters most, so calls that arrive before then wait here rather than
     * being refused.
     */
    private var initStatus: Int? = null
    private val waiting = ArrayDeque<(Boolean) -> Unit>()

    private val tts =
        TextToSpeech(context.applicationContext) { status ->
            main.post {
                initStatus = status
                val ready = status == TextToSpeech.SUCCESS
                val queued = waiting.toList()
                waiting.clear()
                queued.forEach { it(ready) }
            }
        }

    init {
        tts.setOnUtteranceProgressListener(
            object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) = Unit

                override fun onDone(utteranceId: String?) = settle(utteranceId)

                // Abstract in the Java base class, so it has to be here even
                // though the two-argument form below replaced it.
                @Suppress("OVERRIDE_DEPRECATION")
                override fun onError(utteranceId: String?) = settle(utteranceId)

                override fun onError(utteranceId: String?, errorCode: Int) = settle(utteranceId)

                override fun onStop(utteranceId: String?, interrupted: Boolean) =
                    settle(utteranceId)
            }
        )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "speak" -> {
                val text = call.argument<String>("text")
                val language = call.argument<String>("language")
                if (text == null || language == null) {
                    result.error("BAD_ARGUMENTS", "speak needs text and language", null)
                    return
                }
                whenReady { ready ->
                    if (!ready) {
                        result.error("UNAVAILABLE", "No system speech engine", null)
                        return@whenReady
                    }
                    speak(text, language, result)
                }
            }

            "stop" -> {
                tts.stop()
                settleNow(null)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun speak(text: String, language: String, result: MethodChannel.Result) {
        // Supersede first, so the previous call is answered before this one can
        // take its place — QUEUE_FLUSH's onStop would otherwise settle *this*
        // reply against the outgoing utterance's id.
        settleNow(null)

        // A language the device has no voice data for leaves whatever the
        // engine defaults to in place: a phrase in the wrong accent still
        // carries the intensity, and silence does not.
        tts.setLanguage(Locale.forLanguageTag(language))

        val id = ids.incrementAndGet().toString()
        // Loudest within the user's media volume, on the stream the warning
        // sound uses. Changing the device volume would be intrusive and would
        // outlast the warning, so that stays theirs.
        val params =
            Bundle().apply {
                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
                putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
            }

        pending = result
        pendingId = id
        if (tts.speak(text, TextToSpeech.QUEUE_FLUSH, params, id) != TextToSpeech.SUCCESS) {
            pending = null
            pendingId = null
            result.error("REJECTED", "System TTS refused the utterance", null)
        }
    }

    /**
     * Answers the utterance in flight, if [utteranceId] is still the current
     * one. Hops to the main thread first, because the progress listener that
     * calls it does not run there.
     */
    private fun settle(utteranceId: String?) {
        main.post { settleNow(utteranceId) }
    }

    /**
     * [settle] without the hop, for the two callers that are already on the
     * main thread and must answer *before* they install a new reply — a posted
     * settle would run after that and cancel the wrong one.
     */
    private fun settleNow(utteranceId: String?) {
        if (utteranceId != null && utteranceId != pendingId) return
        pending?.success(null)
        pending = null
        pendingId = null
    }

    private fun whenReady(action: (Boolean) -> Unit) {
        val status = initStatus
        if (status == null) {
            waiting.add(action)
            return
        }
        action(status == TextToSpeech.SUCCESS)
    }
}
