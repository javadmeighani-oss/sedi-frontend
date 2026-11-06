package com.sedi.sedi_tray

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat

/**
 * The buttons of the native tray notifications (R-073):
 *  - «not now» on the arrival: the notification GROWS AT ONCE (native), the reaction is kept and recorded behind it;
 *  - an answer on the grown notification: the notification CLOSES at once, the answer is kept and delivered behind it.
 * The user never waits for Flutter; anything that cannot be delivered stays in [TrayPrefs] for the next app start.
 */
class SediTrayActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(GrownNotification.EXTRA_ID, -1)
        val payload = intent.getStringExtra(GrownNotification.EXTRA_PAYLOAD) ?: ""

        if (intent.action == GrownNotification.ACTION_DISLIKE) {
            GrownNotification.presentFromJson(context, intent.getStringExtra(GrownNotification.EXTRA_GROWN_JSON) ?: "")
            TrayPrefs.addPending(context, id, GrownNotification.ANSWER_DISLIKE, payload)
            val pendingResult = goAsync()
            BackgroundRunner.run(context, id, GrownNotification.ANSWER_DISLIKE, payload) { pendingResult.finish() }
            return
        }

        val answer = intent.getStringExtra(GrownNotification.EXTRA_ANSWER) ?: return
        if (id >= 0) {
            try {
                NotificationManagerCompat.from(context).cancel(id)
            } catch (e: Exception) {
                // the answer is still delivered below
            }
        }
        TrayPrefs.addPending(context, id, answer, payload)
        val pending = goAsync()
        BackgroundRunner.run(context, id, answer, payload) { pending.finish() }
    }
}
