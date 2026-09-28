package com.ezan.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_TIMEZONE_CHANGED -> {
                PrayerAlarmScheduler.invalidateForRecalculation(context)
                PrayerWidgetSchedule.invalidateForTimeZoneChange(context)
            }
            else -> {
                PrayerAlarmScheduler.schedulePersisted(context)
                PrayerWidgetSchedule.restore(context)
            }
        }
    }
}
