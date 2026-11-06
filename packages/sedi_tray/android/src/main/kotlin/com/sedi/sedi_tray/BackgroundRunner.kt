package com.sedi.sedi_tray

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

/**
 * Starts the app's Dart entry (registered by the app at start-up) in a headless engine, hands it ONE tray answer and tears
 * the engine down. The notification is already closed by the receiver, so the user never waits for any of this.
 * Fail-open: anything that goes wrong leaves the answer in [TrayPrefs] and the app delivers it on its next start.
 */
internal object BackgroundRunner {
    private const val BG_CHANNEL = "sedi/tray_bg"
    private const val TIMEOUT_MS = 9000L

    fun run(context: Context, id: Int, answer: String, payload: String, done: () -> Unit) {
        val app = context.applicationContext
        val handle = TrayPrefs.handle(app)
        val main = Handler(Looper.getMainLooper())
        if (handle == 0L) {
            done()
            return
        }
        main.post {
            var engine: FlutterEngine? = null
            var finished = false
            fun finish(delivered: Boolean) {
                if (finished) return
                finished = true
                if (delivered) TrayPrefs.removePending(app, id, answer)
                try {
                    engine?.destroy()
                } catch (e: Exception) {
                    // nothing left to do
                }
                done()
            }
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(app)
                loader.ensureInitializationComplete(app, null)
                val info = FlutterCallbackInformation.lookupCallbackInformation(handle)
                if (info == null) {
                    done()
                    return@post
                }
                val created = FlutterEngine(app)
                engine = created
                val channel = MethodChannel(created.dartExecutor.binaryMessenger, BG_CHANNEL)
                channel.setMethodCallHandler { call, result ->
                    if (call.method == "ready") {
                        result.success(null)
                        channel.invokeMethod(
                            "onAction",
                            mapOf("id" to id, "answer" to answer, "payload" to payload),
                            object : MethodChannel.Result {
                                override fun success(value: Any?) = finish(value == true)
                                override fun error(code: String, message: String?, details: Any?) = finish(false)
                                override fun notImplemented() = finish(false)
                            },
                        )
                    } else {
                        result.notImplemented()
                    }
                }
                main.postDelayed({ finish(false) }, TIMEOUT_MS)
                created.dartExecutor.executeDartCallback(
                    DartExecutor.DartCallback(app.assets, loader.findAppBundlePath(), info),
                )
            } catch (e: Exception) {
                finish(false)
            }
        }
    }
}
