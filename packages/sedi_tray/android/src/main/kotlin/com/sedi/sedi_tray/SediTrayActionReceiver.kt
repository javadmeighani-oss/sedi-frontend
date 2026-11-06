package com.sedi.sedi_tray

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat

/** An answer button of the grown notification: the notification closes AT ONCE, the answer is kept durably, Dart runs behind. */
class SediTrayActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(GrownNotification.EXTRA_ID, -1)
        val answer = intent.getStringExtra(GrownNotification.EXTRA_ANSWER) ?: return
        val payload = intent.getStringExtra(GrownNotification.EXTRA_PAYLOAD) ?: ""
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
