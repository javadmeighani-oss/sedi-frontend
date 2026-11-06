package com.sedi.sedi_tray

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * The grown «why not now?» notification (R-073, approved design 1b): ONE notification that keeps its own title and text and
 * its two buttons (the pressed one selected) and grows downward with Sedi's question and the answers. Custom views, so the
 * five buttons the standard actions cannot hold fit. Everything fails open: a problem returns false and the app keeps the
 * standard notification path.
 */
internal object GrownNotification {
    const val EXTRA_ID = "sedi_tray_id"
    const val EXTRA_ANSWER = "sedi_tray_answer"
    const val EXTRA_PAYLOAD = "sedi_tray_payload"
    const val EXTRA_TALK_ID = "sedi_tray_talk_id"
    const val EXTRA_TALK_PAYLOAD = "sedi_tray_talk_payload"
    const val ACTION_ANSWER = "com.sedi.sedi_tray.ANSWER"

    private const val TIMEOUT_MS = 90_000L
    private const val ACCENT = 0xFF48551F.toInt()
    private val ANSWER_VIEWS = intArrayOf(R.id.tray_ans_0, R.id.tray_ans_1, R.id.tray_ans_2)

    private fun str(args: Map<*, *>, key: String): String = (args[key] as? String) ?: ""

    fun show(context: Context, args: Map<*, *>): Boolean {
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
        val answers = (args["answers"] as? List<*>)
            ?.mapNotNull { it as? Map<*, *> }
            ?.take(ANSWER_VIEWS.size)
            ?: return false
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

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        var talkIntent: PendingIntent? = null
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            launch.putExtra(EXTRA_TALK_ID, id)
            launch.putExtra(EXTRA_TALK_PAYLOAD, talkPayload.ifEmpty { answerPayload })
            talkIntent = PendingIntent.getActivity(context, id * 10, launch, flags)
        }
        talkIntent?.let { big.setOnClickPendingIntent(R.id.tray_btn_talk, it) }

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
            val intent = Intent(context, SediTrayActionReceiver::class.java).apply {
                action = ACTION_ANSWER
                putExtra(EXTRA_ID, id)
                putExtra(EXTRA_ANSWER, answerId)
                putExtra(EXTRA_PAYLOAD, answerPayload)
            }
            big.setOnClickPendingIntent(viewId, PendingIntent.getBroadcast(context, id * 10 + index + 1, intent, flags))
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
        talkIntent?.let { builder.setContentIntent(it) }

        return try {
            NotificationManagerCompat.from(context).notify(id, builder.build())
            true
        } catch (e: Exception) {
            false
        }
    }
}
