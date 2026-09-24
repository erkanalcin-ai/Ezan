package com.ezan.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import java.util.Locale

class AdhanPlaybackService : Service() {
    private lateinit var player: ExoPlayer

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        promoteToForeground(PLAYBACK_NOTIFICATION_ID, buildNotification())
        player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_ALARM)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(),
                false,
            )
            volume = AdhanAudioPreferences.getVolume(this@AdhanPlaybackService)
            addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    if (playbackState == Player.STATE_ENDED) stopPlayback()
                }

                override fun onPlayerError(error: PlaybackException) {
                    stopPlayback()
                }
            })
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val assetId = intent?.getStringExtra("assetId")
        if (intent?.action != ACTION_PLAY || assetId == null || assetId !in assetIds) {
            stopPlayback(startId)
            return START_NOT_STICKY
        }

        val prayer = prayerDisplayName(intent.getStringExtra("prayer"))
        promoteToForeground(PLAYBACK_NOTIFICATION_ID, buildNotification(prayer))

        val resourceId = resources.getIdentifier("placeholder_chime", "raw", packageName)
        if (resourceId == 0) {
            // Production recordings are intentionally absent until licensed files are supplied.
            stopPlayback(startId)
            return START_NOT_STICKY
        }

        val mediaItem = MediaItem.Builder()
            .setUri(Uri.parse("android.resource://$packageName/$resourceId"))
            .setMediaMetadata(MediaMetadata.Builder().setTitle(prayer).build())
            .build()
        player.setMediaItem(mediaItem)
        player.prepare()
        player.play()
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        player.release()
        super.onDestroy()
    }

    private fun stopPlayback(startId: Int? = null) {
        if (::player.isInitialized) {
            player.stop()
            player.clearMediaItems()
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        if (startId == null) stopSelf() else stopSelf(startId)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(PLAYBACK_CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    PLAYBACK_CHANNEL_ID,
                    getString(R.string.playback_notification_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = getString(R.string.playback_notification_channel_description)
                    setSound(null, null)
                    enableVibration(false)
                },
            )
        }
    }

    private fun buildNotification(prayer: String? = null): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, PLAYBACK_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(getString(R.string.playback_notification_title))
            .setContentText(
                prayer?.let { getString(R.string.playback_notification_text, it) }
                    ?: getString(R.string.playback_notification_text_default),
            )
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setShowWhen(false)
            .build()
    }

    private fun prayerDisplayName(prayer: String?): String? {
        val label = when (prayer?.lowercase(Locale.ROOT)) {
            "fajr" -> R.string.prayer_fajr
            "dhuhr" -> R.string.prayer_dhuhr
            "asr" -> R.string.prayer_asr
            "maghrib" -> R.string.prayer_maghrib
            "isha" -> R.string.prayer_isha
            else -> return null
        }
        return getString(label)
    }

    private fun promoteToForeground(notificationId: Int, notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notificationId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(notificationId, notification)
        }
    }

    companion object {
        const val ACTION_PLAY = "com.ezan.app.action.PLAY_ADHAN"
        val assetIds = setOf("adhan_fajr", "adhan_dhuhr", "adhan_asr", "adhan_maghrib", "adhan_isha")

        private const val PLAYBACK_CHANNEL_ID = "adhan_playback"
        private const val PLAYBACK_NOTIFICATION_ID = 701
    }
}
