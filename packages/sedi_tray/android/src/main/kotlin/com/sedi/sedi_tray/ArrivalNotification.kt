package com.sedi.sedi_tray

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * The ARRIVAL of a notification that carries «talk with Sedi» + «not now» (R-073, no-wait): a standard native notification whose
 * «not now» button goes straight to [SediTrayActionReceiver], which grows the notification at once - no Flutter engine is
 * started on the user's tap. The app draws nothing else differently: channel, title and text are decided by the Dart renderer
 * and handed over; a problem returns false and the Dart renderer shows the notification as before.
 */
internal object ArrivalNotification {
    fun show(context: Context, args: Map<*, *>): Boolean {
        val id = (args["id"] as? Number)?.toInt() ?: return false
        val title = GrownNotification.str(args, "title")
        val body = GrownNotification.str(args, "body")
        val channelId = GrownNotification.str(args, "channelId")
        val talkLabel = GrownNotification.str(args, "talkLabel")
        val notNowLabel = GrownNotification.str(args, "notNowLabel")
        val payload = GrownNotification.str(args, "payload")
        val grownJson = GrownNotification.str(args, "grownJson")
        if (channelId.isEmpty() || grownJson.isEmpty() || (title.isEmpty() && body.isEmpty())) return false

        val smallIcon = context.resources.getIdentifier("ic_stat_sedi", "drawable", context.packageName)
        val sphere = context.resources.getIdentifier("sedi_notification_sphere", "drawable", context.packageName)

        val talk = GrownNotification.talkIntent(context, id, payload)
        val notNow = PendingIntent.getBroadcast(
            context,
            id * 10 + 5,
            Intent(context, SediTrayActionReceiver::class.java).apply {
                action = GrownNotification.ACTION_DISLIKE
                putExtra(GrownNotification.EXTRA_ID, id)
                putExtra(GrownNotification.EXTRA_PAYLOAD, payload)
                putExtra(GrownNotification.EXTRA_GROWN_JSON, grownJson)
            },
            GrownNotification.immutableFlags(),
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(if (smallIcon != 0) smallIcon else android.R.drawable.ic_dialog_info)
            .setColor(GrownNotification.ACCENT)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(false) // R-073: Android also dismisses a notification when one of its ACTION buttons is tapped if autoCancel is on; this one is closed or grown explicitly
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        talk?.let {
            builder.setContentIntent(it)
            builder.addAction(0, talkLabel, it)
        }
        builder.addAction(0, notNowLabel, notNow)
        if (sphere != 0) {
            try {
                builder.setLargeIcon(BitmapFactory.decodeResource(context.resources, sphere))
            } catch (e: Exception) {
                // no large icon is fine
            }
        }

        return try {
            NotificationManagerCompat.from(context).notify(id, builder.build())
            true
        } catch (e: Exception) {
            false
        }
    }
}
