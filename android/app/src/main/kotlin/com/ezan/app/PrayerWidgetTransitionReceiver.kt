package com.ezan.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PrayerWidgetTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        PrayerWidgetSchedule.advance(context)
    }
}
