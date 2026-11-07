package com.sedi.sedi_tray

import android.content.Context
import android.graphics.BitmapFactory
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.text.HtmlCompat

/**
 * The standard (no custom views) grown notification: the notification TITLE stays, the text keeps its place, Sedi's question is
 * a bold coloured heading below it, her sphere is the large icon and the three answers are the notification's buttons (every
 * one reaches [SediTrayActionReceiver], so it works on every Android version the app supports and an answer is instant).
 */
internal object StandardGrown {
    fun show(context: Context, args: Map<*, *>): Boolean {
        val id = (args["id"] as? Number)?.toInt() ?: return false
        val title = GrownNotification.str(args, "title")
        val question = GrownNotification.str(args, "question")
        val html = GrownNotification.str(args, "html").ifEmpty { question }
        val channelId = GrownNotification.str(args, "channelId")
        val talkPayload = GrownNotification.str(args, "payload")
        val answerPayload = GrownNotification.str(args, "answerPayload")
        if (channelId.isEmpty() || html.isEmpty()) return false
        val answers = GrownNotification.answersOf(args)
        if (answers.isEmpty()) return false

        val smallIcon = context.resources.getIdentifier("ic_stat_sedi", "drawable", context.packageName)
        val sphere = context.resources.getIdentifier("sedi_notification_sphere", "drawable", context.packageName)
        val styled = HtmlCompat.fromHtml(html, HtmlCompat.FROM_HTML_MODE_LEGACY)
        val talk = GrownNotification.talkIntent(context, id, talkPayload.ifEmpty { answerPayload })

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(if (smallIcon != 0) smallIcon else android.R.drawable.ic_dialog_info)
            .setColor(GrownNotification.ACCENT)
            .setContentTitle(title)
            .setContentText(question)
            .setStyle(NotificationCompat.BigTextStyle().bigText(styled))
            .setOnlyAlertOnce(true)
            .setAutoCancel(false) // R-073: Android also dismisses a notification when one of its ACTION buttons is tapped if autoCancel is on; this one is closed or grown explicitly
            .setTimeoutAfter(GrownNotification.TIMEOUT_MS)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        talk?.let { builder.setContentIntent(it) }
        if (sphere != 0) {
            try {
                builder.setLargeIcon(BitmapFactory.decodeResource(context.resources, sphere))
            } catch (e: Exception) {
                // no large icon is fine
            }
        }
        for ((index, answer) in answers.withIndex()) {
            val answerId = (answer["id"] as? String) ?: continue
            val label = (answer["label"] as? String) ?: answerId
            builder.addAction(0, label, GrownNotification.answerIntent(context, id, answerId, answerPayload, index))
        }

        return try {
            NotificationManagerCompat.from(context).notify(id, builder.build())
            true
        } catch (e: Exception) {
            false
        }
    }
}
