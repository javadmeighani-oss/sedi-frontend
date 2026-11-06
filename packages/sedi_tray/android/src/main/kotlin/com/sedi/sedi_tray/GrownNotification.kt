package com.sedi.sedi_tray

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * The grown «why not now?» notification (R-073, approved design 1b): ONE notification that keeps its own title and text and
 * its two buttons (the pressed one selected) and grows downward with Sedi's question and the answers.
 *
 * Two renderers, both native (so every button reaches [SediTrayActionReceiver] and the answer is instant):
 *  - the custom-view design, drawn only from Android 12 (API 31) where the templates are unified (a bad render is not an
 *    error a fallback could catch, and custom expanded views are height-limited);
 *  - [StandardGrown], the standard notification (title kept, bold coloured heading, three answer buttons) for everything else.
 * Everything fails open: a problem returns false and the app keeps the Flutter notification path.
 */
internal object GrownNotification {
    const val EXTRA_ID = "sedi_tray_id"
    const val EXTRA_ANSWER = "sedi_tray_answer"
    const val EXTRA_PAYLOAD = "sedi_tray_payload"
    const val EXTRA_GROWN_JSON = "sedi_tray_grown_json"
    const val EXTRA_TALK_ID = "sedi_tray_talk_id"
    const val EXTRA_TALK_PAYLOAD = "sedi_tray_talk_payload"
    const val ACTION_ANSWER = "com.sedi.sedi_tray.ANSWER"
    const val ACTION_DISLIKE = "com.sedi.sedi_tray.DISLIKE"

    /** The «not now» reaction itself (not one of the three reasons): the app records it behind the grown notification. */
    const val ANSWER_DISLIKE = "__dislike__"

    const val TIMEOUT_MS = 90_000L
    const val ACCENT = 0xFF48551F.toInt()

    /**
     * The custom layout is drawn only from Android 12 (API 31), where the notification templates are unified; on older systems
     * the layout may be clipped or restyled by the maker's skin. Below this level [StandardGrown] is used.
     */
    const val MIN_SDK = 31
    private val ANSWER_VIEWS = intArrayOf(R.id.tray_ans_0, R.id.tray_ans_1, R.id.tray_ans_2)

    fun str(args: Map<*, *>, key: String): String = (args[key] as? String) ?: ""

    fun immutableFlags(): Int = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

    /** «talk with Sedi»: opens the app with the payload; Dart picks it up once (the same seam as a tap on the body). */
    fun talkIntent(context: Context, id: Int, payload: String): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        launch.putExtra(EXTRA_TALK_ID, id)
        launch.putExtra(EXTRA_TALK_PAYLOAD, payload)
        return PendingIntent.getActivity(context, id * 10, launch, immutableFlags())
    }

    fun answerIntent(context: Context, id: Int, answerId: String, payload: String, index: Int): PendingIntent {
        val intent = Intent(context, SediTrayActionReceiver::class.java).apply {
            action = ACTION_ANSWER
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_ANSWER, answerId)
            putExtra(EXTRA_PAYLOAD, payload)
        }
        return PendingIntent.getBroadcast(context, id * 10 + index + 1, intent, immutableFlags())
    }

    fun answersOf(args: Map<*, *>): List<Map<*, *>> =
        (args["answers"] as? List<*>)?.mapNotNull { it as? Map<*, *> }?.take(ANSWER_VIEWS.size) ?: emptyList()

    /** The best available grown notification: the custom design where it is safe, the standard one otherwise. */
    fun present(context: Context, args: Map<*, *>): Boolean = show(context, args) || StandardGrown.show(context, args)

    /** The grown arguments the arrival notification carries inside its «not now» button. */
    fun presentFromJson(context: Context, json: String): Boolean {
        if (json.isEmpty()) return false
        return try {
            present(context, jsonToMap(JSONObject(json)))
        } catch (e: Exception) {
            false
        }
    }

    private fun jsonToMap(obj: JSONObject): Map<String, Any?> {
        val out = HashMap<String, Any?>()
        val keys = obj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            out[key] = jsonValue(obj.get(key))
        }
        return out
    }

    private fun jsonValue(value: Any?): Any? = when (value) {
        is JSONObject -> jsonToMap(value)
        is JSONArray -> (0 until value.length()).map { jsonValue(value.get(it)) }
        JSONObject.NULL -> null
        else -> value
    }

    fun show(context: Context, args: Map<*, *>): Boolean {
        if (Build.VERSION.SDK_INT < MIN_SDK) return false
        val id = (args["id"] as? Number)?.toInt() ?: return false
        val rtl = args["rtl"] as? Boolean ?: false
        val title = str(args, "title")
        val body = str(args, "body")
        val question = str(args, "question")
        val talkLabel = str(args, "talkLabel")
        val notNowLabel = str(args, "notNowLabel")
        val channelId = str(args, "channelId")
        val talkPayload = str(args, "payload")
        val answerPayload = str(args, "answerPayload")
        if (channelId.isEmpty() || question.isEmpty()) return false
        val answers = answersOf(args)
        if (answers.isEmpty()) return false

        val big = RemoteViews(context.packageName, if (rtl) R.layout.sedi_tray_grown_rtl else R.layout.sedi_tray_grown_ltr)
        val small = RemoteViews(context.packageName, if (rtl) R.layout.sedi_tray_collapsed_rtl else R.layout.sedi_tray_collapsed_ltr)

        val sphere = context.resources.getIdentifier("sedi_notification_sphere", "drawable", context.packageName)
        big.setTextViewText(R.id.tray_title, title)
        big.setTextViewText(R.id.tray_body, body)
        big.setViewVisibility(R.id.tray_body, if (body.isEmpty()) View.GONE else View.VISIBLE)
        big.setTextViewText(R.id.tray_btn_talk, talkLabel)
        big.setTextViewText(R.id.tray_btn_notnow, "✓  $notNowLabel")
        big.setTextViewText(R.id.tray_question, question)
        if (sphere != 0) big.setImageViewResource(R.id.tray_sphere, sphere)
        small.setTextViewText(R.id.tray_title, title)
        small.setTextViewText(R.id.tray_question, question)

        val talk = talkIntent(context, id, talkPayload.ifEmpty { answerPayload })
        talk?.let { big.setOnClickPendingIntent(R.id.tray_btn_talk, it) }

        for ((index, viewId) in ANSWER_VIEWS.withIndex()) {
            val answer = answers.getOrNull(index)
            if (answer == null) {
                big.setViewVisibility(viewId, View.GONE)
                continue
            }
            val answerId = (answer["id"] as? String) ?: continue
            val label = (answer["label"] as? String) ?: answerId
            big.setViewVisibility(viewId, View.VISIBLE)
            big.setTextViewText(viewId, label)
            big.setOnClickPendingIntent(viewId, answerIntent(context, id, answerId, answerPayload, index))
        }

        val smallIcon = context.resources.getIdentifier("ic_stat_sedi", "drawable", context.packageName)
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(if (smallIcon != 0) smallIcon else android.R.drawable.ic_dialog_info)
            .setColor(ACCENT)
            .setContentTitle(title)
            .setContentText(question)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(small)
            .setCustomBigContentView(big)
            .setOnlyAlertOnce(true)
            .setAutoCancel(true)
            .setTimeoutAfter(TIMEOUT_MS)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        talk?.let { builder.setContentIntent(it) }

        return try {
            NotificationManagerCompat.from(context).notify(id, builder.build())
            true
        } catch (e: Exception) {
            false
        }
    }
}
