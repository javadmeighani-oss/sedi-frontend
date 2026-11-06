package com.sedi.sedi_tray

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Small durable state of the native tray: the Dart entry handle, answers not yet delivered, and the «talk» tap. */
internal object TrayPrefs {
    private const val FILE = "sedi_tray"
    private const val MAX_PENDING = 10
    private const val MAX_AGE_MS = 24L * 60L * 60L * 1000L

    private fun prefs(context: Context) = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun setHandle(context: Context, handle: Long) {
        prefs(context).edit().putLong("handle", handle).apply()
    }

    fun handle(context: Context): Long = prefs(context).getLong("handle", 0L)

    @Synchronized
    fun addPending(context: Context, id: Int, answer: String, payload: String) {
        val current = readPending(context)
        current.put(
            JSONObject()
                .put("id", id)
                .put("answer", answer)
                .put("payload", payload)
                .put("ts", System.currentTimeMillis()),
        )
        val trimmed = JSONArray()
        val start = maxOf(0, current.length() - MAX_PENDING)
        for (i in start until current.length()) trimmed.put(current.get(i))
        prefs(context).edit().putString("pending", trimmed.toString()).apply()
    }

    @Synchronized
    fun removePending(context: Context, id: Int, answer: String) {
        val current = readPending(context)
        val kept = JSONArray()
        var removed = false
        for (i in 0 until current.length()) {
            val item = current.getJSONObject(i)
            if (!removed && item.optInt("id", -1) == id && item.optString("answer") == answer) {
                removed = true
            } else {
                kept.put(item)
            }
        }
        prefs(context).edit().putString("pending", kept.toString()).apply()
    }

    /** The answers still waiting (fresh ones only); the list is cleared. */
    @Synchronized
    fun drainPending(context: Context): List<Map<String, Any>> {
        val current = readPending(context)
        prefs(context).edit().putString("pending", "[]").apply()
        val now = System.currentTimeMillis()
        val out = ArrayList<Map<String, Any>>()
        for (i in 0 until current.length()) {
            val item = current.getJSONObject(i)
            if (now - item.optLong("ts", 0L) > MAX_AGE_MS) continue
            out.add(
                mapOf(
                    "id" to item.optInt("id", -1),
                    "answer" to item.optString("answer"),
                    "payload" to item.optString("payload"),
                ),
            )
        }
        return out
    }

    private fun readPending(context: Context): JSONArray {
        return try {
            JSONArray(prefs(context).getString("pending", "[]"))
        } catch (e: Exception) {
            JSONArray()
        }
    }

    fun setLaunch(context: Context, id: Int, payload: String) {
        prefs(context).edit().putInt("launch_id", id).putString("launch_payload", payload).apply()
    }

    /** The «talk» tap, once. */
    @Synchronized
    fun takeLaunch(context: Context): Map<String, Any>? {
        val payload = prefs(context).getString("launch_payload", null) ?: return null
        val id = prefs(context).getInt("launch_id", -1)
        prefs(context).edit().remove("launch_payload").remove("launch_id").apply()
        if (payload.isEmpty()) return null
        return mapOf("id" to id, "payload" to payload)
    }
}
