package com.pixelsearch.pixelsearch

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.*

class MainActivity : FlutterActivity() {
    private var peopleDecoder: PeopleImageDecoder? = null
    private var recognizer: SpeechRecognizer? = null
    private var reply: MethodChannel.Result? = null
    private var requestId: Int? = null
    private val handler = Handler(Looper.getMainLooper())
    private val timeout = Runnable { finish(null, "Speech timed out. Please try again.", "timeout") }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        peopleDecoder = PeopleImageDecoder(this, flutterEngine.dartExecutor.binaryMessenger)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pixelsearch/on_device_speech")
        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "cancel", "stop" -> {
                        val target = call.argument<Int>("requestId")
                        if (target == null || target == requestId) {
                            if (call.method == "cancel") {
                                finish(null, "Speech cancelled.", "cancelled")
                            } else {
                                try {
                                    recognizer?.stopListening()
                                    if (reply != null) deadline(10000)
                                } catch (_: Exception) {
                                    finish(null, "Could not finish speech. Please try again.", "audio")
                                }
                            }
                        }
                        result.success(null)
                    }
                    "support", "download", "recognize" -> {
                        if (reply != null) { result.error("busy", "Already listening", null); return@setMethodCallHandler }
                        if (Build.VERSION.SDK_INT < 33 || !SpeechRecognizer.isOnDeviceRecognitionAvailable(this)) {
                            result.error("unavailable", "On-device recognition unavailable", null)
                            return@setMethodCallHandler
                        }
                        reply = result
                        requestId = call.argument<Int>("requestId")
                        try {
                            val language = call.argument<String>("language") ?: "en-IN"
                            if (!Regex("[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})*").matches(language)) {
                                finish(null, "Invalid speech language", "language")
                                return@setMethodCallHandler
                            }
                            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
                                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                            }
                            val engine = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
                            recognizer = engine
                            val activeRequest = requestId
                            fun state(value: String) {
                                if (recognizer === engine) channel.invokeMethod("state", mapOf(
                                    "requestId" to activeRequest, "state" to value
                                ))
                            }
                            engine.setRecognitionListener(object : RecognitionListener {
                                override fun onReadyForSpeech(params: Bundle?) {
                                    if (recognizer === engine) { deadline(30000); state("listening") }
                                }
                                override fun onBeginningOfSpeech() {}
                                override fun onRmsChanged(rmsdB: Float) {}
                                override fun onBufferReceived(buffer: ByteArray?) {}
                                override fun onEndOfSpeech() {
                                    if (recognizer === engine) { deadline(10000); state("processing") }
                                }
                                override fun onPartialResults(results: Bundle?) {}
                                override fun onEvent(eventType: Int, params: Bundle?) {}
                                override fun onError(error: Int) {
                                    if (recognizer === engine) speechFailure(error)
                                }
                                override fun onResults(results: Bundle?) {
                                    if (recognizer !== engine) return
                                    val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                                    if (text.isNullOrBlank()) finish(null, "No speech was heard. Please try again.", "no_speech")
                                    else finish(text, null)
                                }
                            })
                            deadline(15000)
                            engine.checkRecognitionSupport(intent, mainExecutor, object : RecognitionSupportCallback {
                                override fun onSupportResult(support: RecognitionSupport) {
                                    if (reply == null || recognizer !== engine) return
                                    fun contains(languages: List<String>) = languages.any {
                                        it.replace('_', '-').equals(language, true) || it.equals(language.substringBefore('-'), true)
                                    }
                                    if (call.method == "support") {
                                        finish(mapOf(
                                            "requested" to language,
                                            "installed" to support.installedOnDeviceLanguages,
                                            "pending" to support.pendingOnDeviceLanguages,
                                            "downloadable" to support.supportedOnDeviceLanguages
                                        ), null)
                                        return
                                    }
                                    if (call.method == "download") {
                                        if (call.argument<Boolean>("confirmed") != true) {
                                            finish(null, "Download approval required", "consent")
                                        } else if (contains(support.installedOnDeviceLanguages)) {
                                            finish("installed", null)
                                        } else if (contains(support.pendingOnDeviceLanguages)) {
                                            finish("scheduled", null)
                                        } else if (!contains(support.supportedOnDeviceLanguages)) {
                                            finish(null, "This language is not offered for offline download", "unavailable")
                                        } else {
                                            try {
                                                deadline(30000)
                                                if (Build.VERSION.SDK_INT >= 34) {
                                                    engine.triggerModelDownload(intent, mainExecutor, object : ModelDownloadListener {
                                                        override fun onProgress(progress: Int) {}
                                                        override fun onSuccess() { if (recognizer === engine) finish("installed", null) }
                                                        override fun onScheduled() { if (recognizer === engine) finish("scheduled", null) }
                                                        override fun onError(error: Int) { if (recognizer === engine) finish(null, "Language download failed ($error)", "download") }
                                                    })
                                                } else {
                                                    engine.triggerModelDownload(intent)
                                                    finish("requested", null)
                                                }
                                            } catch (_: Exception) {
                                                finish(null, "Language download is unavailable", "download")
                                            }
                                        }
                                        return
                                    }
                                    if (!contains(support.installedOnDeviceLanguages)) {
                                        finish(null, "Offline language $language is not ready. Open offline speech setup.", "language_missing")
                                        return
                                    }
                                    try {
                                        deadline(15000)
                                        engine.startListening(intent)
                                    } catch (_: SecurityException) {
                                        finish(null, "Microphone access is unavailable.", "permission")
                                    } catch (_: Exception) {
                                        finish(null, "The microphone could not start. Please try again.", "audio")
                                    }
                                }
                                override fun onError(error: Int) { if (recognizer === engine) speechFailure(error) }
                            })
                        } catch (_: SecurityException) {
                            finish(null, "Microphone access is unavailable.", "permission")
                        } catch (_: Exception) { finish(null, "On-device recognition unavailable", "unavailable") }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    private fun deadline(milliseconds: Long) {
        handler.removeCallbacks(timeout)
        handler.postDelayed(timeout, milliseconds)
    }

    private fun speechFailure(error: Int) {
        val (code, message) = when (error) {
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permission" to "Microphone access is unavailable."
            SpeechRecognizer.ERROR_AUDIO -> "audio" to "The microphone could not start."
            SpeechRecognizer.ERROR_NO_MATCH -> "no_match" to "Speech was not understood. Please try again."
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "no_speech" to "No speech was heard. Please try again."
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "busy" to "The speech recognizer is busy. Please try again."
            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> "language_missing" to "Offline language files are missing. Open offline speech setup."
            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED -> "language_missing" to "This offline language is not supported. Choose another in offline speech setup."
            SpeechRecognizer.ERROR_CANNOT_CHECK_SUPPORT -> "unavailable" to "Android could not check offline language support. No online fallback was used."
            else -> "speech" to "On-device speech failed ($error). Please try again."
        }
        finish(null, message, code)
    }

    private fun finish(text: Any?, error: String?, code: String = "speech") {
        handler.removeCallbacks(timeout)
        val engine = recognizer
        recognizer = null
        val pending = reply
        reply = null
        requestId = null
        try { engine?.cancel() } catch (_: Exception) {}
        try { engine?.destroy() } catch (_: Exception) {}
        if (error == null) pending?.success(text) else pending?.error(code, error, null)
    }
    override fun onDestroy() { peopleDecoder?.close(); finish(null, "Speech cancelled.", "cancelled"); super.onDestroy() }
    override fun onStop() { finish(null, "Speech cancelled.", "cancelled"); super.onStop() }
}
