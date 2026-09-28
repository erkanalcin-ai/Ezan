package com.ezan.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

internal data class PrayerStatusEvent(val timestamp: Long, val prayer: String)

internal object PrayerWidgetSchedule {
    private const val PREFS = "prayer_widget_schedule"
    private const val EVENTS = "events"
    private const val READY = "ready"
    private const val STALE = "stale"
    private const val TRANSITION_ACTION = "com.ezan.app.action.PRAYER_WIDGET_TRANSITION"

    fun replace(context: Context, eventsJson: String) {
        val events = parse(eventsJson).filter { it.timestamp > System.currentTimeMillis() }
        preferences(context).edit()
            .putString(EVENTS, JSONArray(events.map(::toJson)).toString())
            .putBoolean(READY, true)
            .putBoolean(STALE, false)
            .apply()
        refresh(context)
    }

    fun clear(context: Context) {
        preferences(context).edit()
            .putString(EVENTS, "[]")
            .putBoolean(READY, false)
            .putBoolean(STALE, false)
            .apply()
        cancelTransition(context)
        refresh(context)
    }

    fun invalidateForTimeZoneChange(context: Context) {
        preferences(context).edit().putBoolean(STALE, true).apply()
        cancelTransition(context)
        refresh(context)
    }

    fun refresh(context: Context) {
        prunePastEvents(context)
        PrayerCountdownWidgetProvider.updateWidgets(context)
        PrayerStatusNotification.refresh(context)
        scheduleNextTransition(context)
    }

    fun nextPrayer(context: Context, now: Long = System.currentTimeMillis()): PrayerStatusEvent? {
        val prefs = preferences(context)
        if (!prefs.getBoolean(READY, false) || prefs.getBoolean(STALE, false)) return null
        return parse(prefs.getString(EVENTS, "[]"))
            .firstOrNull { it.timestamp > now }
    }

    fun shouldSync(context: Context): Boolean =
        PrayerCountdownWidgetProvider.hasWidgets(context) ||
            PrayerStatusPreferences.isEnabled(context)

    fun isStale(context: Context): Boolean = preferences(context).getBoolean(STALE, false)

    fun restore(context: Context) {
        refresh(context)
    }

    fun advance(context: Context) {
        prunePastEvents(context)
        refresh(context)
    }

    private fun prunePastEvents(context: Context) {
        val prefs = preferences(context)
        if (!prefs.getBoolean(READY, false) || prefs.getBoolean(STALE, false)) return
        val now = System.currentTimeMillis()
        val remaining = parse(prefs.getString(EVENTS, "[]"))
            .filter { it.timestamp > now }
        prefs.edit()
            .putString(EVENTS, JSONArray(remaining.map(::toJson)).toString())
            .putBoolean(STALE, remaining.isEmpty())
            .apply()
    }

    private fun scheduleNextTransition(context: Context) {
        cancelTransition(context)
        val shouldSchedule = PrayerCountdownWidgetProvider.hasWidgets(context) ||
            PrayerStatusPreferences.isEnabled(context)
        if (!shouldSchedule) return
        val next = nextPrayer(context) ?: return
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val pendingIntent = transitionPendingIntent(context)
        try {
            if (PrayerAlarmScheduler.hasExactAlarmAccess(context)) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    next.timestamp,
                    pendingIntent,
                )
            } else {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    next.timestamp,
                    pendingIntent,
                )
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                next.timestamp,
                pendingIntent,
            )
        }
    }

    private fun cancelTransition(context: Context) {
        context.getSystemService(AlarmManager::class.java)
            .cancel(transitionPendingIntent(context))
    }

    private fun transitionPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, PrayerWidgetTransitionReceiver::class.java).apply {
            action = TRANSITION_ACTION
            data = Uri.parse("ezan://prayer-widget/transition")
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun parse(raw: String?): List<PrayerStatusEvent> = try {
        val json = JSONArray(raw ?: "[]")
        (0 until json.length())
            .map { json.getJSONObject(it) }
            .mapNotNull { event ->
                val timestamp = event.optLong("timestamp", 0L)
                val prayer = event.optString("prayer")
                    .lowercase(Locale.ROOT)
                    .takeIf { it in SUPPORTED_PRAYERS }
                if (timestamp <= 0L || prayer == null) null
                else PrayerStatusEvent(timestamp, prayer)
            }
            .sortedBy(PrayerStatusEvent::timestamp)
    } catch (_: Exception) {
        emptyList()
    }

    private fun toJson(event: PrayerStatusEvent) = JSONObject().apply {
        put("timestamp", event.timestamp)
        put("prayer", event.prayer)
    }

    private val SUPPORTED_PRAYERS = setOf("fajr", "dhuhr", "asr", "maghrib", "isha")
}
