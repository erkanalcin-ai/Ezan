package com.ezan.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PrayerStatusActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == PrayerStatusNotification.ACTION_MUTE_ADHAN) {
            AdhanPlaybackService.setActivePlaybackMuted(true)
            PrayerStatusNotification.refresh(context)
        }
    }
}
