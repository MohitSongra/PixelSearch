package com.pixelsearch.pixelsearch

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/** Bounded decode of gallery originals; no network or gallery enumeration. */
class PeopleImageDecoder(context: Context, messenger: BinaryMessenger) {
    private val root = File(context.cacheDir, "people_stage").apply { mkdirs() }
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, "pixelsearch/people_decode")

    init {
        clearTemporary()
        channel.setMethodCallHandler { call, result ->
            if (call.method == "clearTemporary") {
                executor.execute { clearTemporary(); main.post { result.success(null) } }
                return@setMethodCallHandler
            }
            if (call.method != "prepare") { result.notImplemented(); return@setMethodCallHandler }
            val path = call.argument<String>("path")
            if (path.isNullOrBlank()) { result.error("decode", "Photo unavailable.", null); return@setMethodCallHandler }
            executor.execute {
                var decoded: Bitmap? = null
                var upright: Bitmap? = null
                var output: File? = null
                try {
                    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeFile(path, bounds)
                    require(bounds.outWidth > 0 && bounds.outHeight > 0)
                    var sample = 1
                    while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 2048) sample *= 2
                    val options = BitmapFactory.Options().apply {
                        inSampleSize = sample
                        inPreferredConfig = Bitmap.Config.ARGB_8888
                    }
                    decoded = BitmapFactory.decodeFile(path, options) ?: error("decode")
                    val orientation = try {
                        ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, 1)
                    } catch (_: Exception) { 1 }
                    val matrix = Matrix()
                    when (orientation) {
                        2 -> matrix.setScale(-1f, 1f)
                        3 -> matrix.setRotate(180f)
                        4 -> matrix.setScale(1f, -1f)
                        5 -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
                        6 -> matrix.setRotate(90f)
                        7 -> { matrix.setRotate(-90f); matrix.postScale(-1f, 1f) }
                        8 -> matrix.setRotate(-90f)
                    }
                    upright = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
                    output = File.createTempFile("face_", ".jpg", root)
                    output.outputStream().use { stream -> check(upright.compress(Bitmap.CompressFormat.JPEG, 95, stream)) }
                    val response = mapOf("path" to output.absolutePath, "width" to upright.width, "height" to upright.height)
                    main.post { result.success(response) }
                } catch (_: Exception) {
                    output?.delete()
                    main.post { result.error("decode", "Could not decode this indexed photo.", null) }
                } finally {
                    if (upright !== decoded) upright?.recycle()
                    decoded?.recycle()
                }
            }
        }
    }

    private fun clearTemporary() {
        root.listFiles()?.filter { it.isFile && it.name.startsWith("face_") && it.extension == "jpg" }
            ?.forEach { it.delete() }
    }

    fun close() { channel.setMethodCallHandler(null); executor.shutdown() }
}
