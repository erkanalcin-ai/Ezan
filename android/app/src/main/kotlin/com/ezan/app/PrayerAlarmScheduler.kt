package com.ezan.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject

internal object PrayerAlarmScheduler {
    private const val PREFS = "prayer_alarm_scheduler"
    private const val EVENTS = "events"
    private const val ENABLED = "enabled"
    private const val ENABLE_AFTER_PERMISSION = "enable_after_permission"
    private const val SCHEDULE_INVALIDATED = "schedule_invalidated"
    private const val ACTION_PLAY = "com.ezan.app.action.PLAY_ADHAN"

    fun hasExactAlarmAccess(context: Context): Boolean {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
    }

    fun requestAccess(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(ENABLE_AFTER_PERMISSION, true).apply()
        if (hasExactAlarmAccess(context)) {
            enable(context)
            schedulePersisted(context)
            return
        }
        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
            data = Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun enable(context: Context) {
        if (!hasExactAlarmAccess(context)) return
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(ENABLED, true)
            .putBoolean(ENABLE_AFTER_PERMISSION, false)
            .apply()
    }

    fun disable(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val previous = parseEvents(prefs.getString(EVENTS, "[]"))
        prefs.edit()
            .putBoolean(ENABLED, false)
            .putBoolean(ENABLE_AFTER_PERMISSION, false)
            .putString(EVENTS, "[]")
            .putBoolean(SCHEDULE_INVALIDATED, false)
            .apply()
        cancelAll(context, previous)
    }

    fun status(context: Context): Map<String, Boolean> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val allowed = hasExactAlarmAccess(context)
        if (allowed && prefs.getBoolean(ENABLE_AFTER_PERMISSION, false)) enable(context)
        return mapOf(
            "exactAlarmAllowed" to allowed,
            "enabled" to (prefs.getBoolean(ENABLED, false) && allowed),
            "scheduleInvalidated" to prefs.getBoolean(SCHEDULE_INVALIDATED, false),
        )
    }

    fun replaceEvents(context: Context, eventsJson: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val previous = parseEvents(prefs.getString(EVENTS, "[]"))
        val incoming = parseEvents(eventsJson)
        cancelAll(context, previous)
        prefs.edit()
            .putString(EVENTS, JSONArray(incoming).toString())
            .putBoolean(SCHEDULE_INVALIDATED, false)
            .apply()
        schedule(context, incoming)
    }

    fun invalidateForRecalculation(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        cancelAll(context, parseEvents(prefs.getString(EVENTS, "[]")))
        prefs.edit()
            .putString(EVENTS, "[]")
            .putBoolean(SCHEDULE_INVALIDATED, true)
            .apply()
    }

    fun schedulePersisted(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getBoolean(ENABLE_AFTER_PERMISSION, false) && hasExactAlarmAccess(context)) enable(context)
        val future = parseEvents(prefs.getString(EVENTS, "[]"))
            .filter { it.optLong("timestamp") > System.currentTimeMillis() }
        prefs.edit().putString(EVENTS, JSONArray(future).toString()).apply()
        schedule(context, future)
    }

    fun consume(context: Context, timestamp: Long) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val remaining = parseEvents(prefs.getString(EVENTS, "[]"))
            .filter { it.optLong("timestamp") != timestamp && it.optLong("timestamp") > System.currentTimeMillis() }
        prefs.edit().putString(EVENTS, JSONArray(remaining).toString()).apply()
        schedule(context, remaining)
    }

    private fun schedule(context: Context, events: List<JSONObject>) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(ENABLED, false) || !hasExactAlarmAccess(context)) return
        val manager = context.getSystemService(AlarmManager::class.java)
        val now = System.currentTimeMillis()
        events.forEach { event ->
            val timestamp = event.optLong("timestamp")
            if (timestamp <= now) return@forEach
            val pendingIntent = alarmPendingIntent(context, timestamp, event)
            manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timestamp, pendingIntent)
        }
    }

    private fun cancelAll(context: Context, events: List<JSONObject>) {
        val manager = context.getSystemService(AlarmManager::class.java)
        events.forEach { event ->
            val timestamp = event.optLong("timestamp")
            manager.cancel(alarmPendingIntent(context, timestamp, event))
        }
    }

    private fun alarmPendingIntent(context: Context, timestamp: Long, event: JSONObject): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = ACTION_PLAY
            data = Uri.parse("ezan://prayer-alarm/$timestamp")
            putExtra("assetId", event.optString("assetId"))
            putExtra("timestamp", timestamp)
            putExtra("prayer", event.optString("prayer"))
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun parseEvents(raw: String?): List<JSONObject> = try {
        val array = JSONArray(raw ?: "[]")
        (0 until array.length()).map { array.getJSONObject(it) }
    } catch (_: Exception) {
        emptyList()
    }
}
