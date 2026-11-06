package com.sedi.sedi_tray

import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * R-073: the native side of the tray. Registered in EVERY engine (also the headless one that renders notifications and the one
 * the answer receiver starts), so the grown notification can be posted from the background isolate. Every call is fail-open.
 */
class SediTrayPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.NewIntentListener {

    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "sedi/tray").also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context
        if (ctx == null) {
            result.success(if (call.method == "showGrown" || call.method == "registerBackground") false else null)
            return
        }
        try {
            when (call.method) {
                "showGrown" -> result.success(GrownNotification.show(ctx, (call.arguments as? Map<*, *>) ?: emptyMap<Any, Any>()))
                "registerBackground" -> {
                    val handle = (call.argument<Number>("handle"))?.toLong() ?: 0L
                    if (handle != 0L) TrayPrefs.setHandle(ctx, handle)
                    result.success(handle != 0L)
                }
                "drainPending" -> result.success(TrayPrefs.drainPending(ctx))
                "takeLaunch" -> result.success(TrayPrefs.takeLaunch(ctx))
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.success(if (call.method == "showGrown" || call.method == "registerBackground") false else null)
        }
    }

    // ---- the «talk with Sedi» tap: the launch intent carries the payload; Dart picks it up once -------------------------
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        capture(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        capture(intent)
        return false
    }

    private fun capture(intent: Intent?) {
        val ctx = context ?: return
        val launch = intent ?: return
        val payload = launch.getStringExtra(GrownNotification.EXTRA_TALK_PAYLOAD) ?: return
        val id = launch.getIntExtra(GrownNotification.EXTRA_TALK_ID, -1)
        TrayPrefs.setLaunch(ctx, id, payload)
        launch.removeExtra(GrownNotification.EXTRA_TALK_PAYLOAD)
        if (id >= 0) {
            try {
                NotificationManagerCompat.from(ctx).cancel(id)
            } catch (e: Exception) {
                // the app still opens the chat
            }
        }
    }
}
