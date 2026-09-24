package com.ezan.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val timestamp = intent.getLongExtra("timestamp", 0L)
        if (timestamp != 0L) PrayerAlarmScheduler.consume(context, timestamp)
        val assetId = intent.getStringExtra("assetId") ?: return
        if (assetId !in AdhanPlaybackService.assetIds) return
        val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra("assetId", assetId)
            putExtra("prayer", intent.getStringExtra("prayer"))
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(serviceIntent)
            else context.startService(serviceIntent)
        } catch (_: Exception) {
            // Android/OEM background-start limits may prevent playback; the app does not bypass them.
        }
    }
}
