package com.ezan.app

import android.app.Notification
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
    private var playbackPrayer: String? = null
    private var isMuted = false

    override fun onCreate() {
        super.onCreate()
        activeInstance = this
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
                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    AdhanPlaybackStateStreamHandler.update(
                        isPlaying = isPlaying,
                        prayer = playbackPrayer,
                        isMuted = isMuted,
                    )
                }

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
        val prayerCode = intent?.getStringExtra("prayer")?.lowercase(Locale.ROOT)
        val prayer = prayerCode?.let {
            PrayerWidgetAppearance.prayerLabel(this, it).takeIf(String::isNotBlank)
        }
        if (
            intent?.action != ACTION_PLAY ||
            assetId == null ||
            assetId !in assetIds ||
            prayer == null
        ) {
            stopPlayback(startId)
            return START_NOT_STICKY
        }

        playbackPrayer = prayerCode
        isMuted = false
        PrayerStatusNotification.cancelStatus(this)
        player.volume = AdhanAudioPreferences.getVolume(this)
        promoteToForeground(PLAYBACK_NOTIFICATION_ID, buildNotification())

        AdhanPlaybackStateStreamHandler.update(
            isPlaying = false,
            prayer = playbackPrayer,
            isMuted = false,
        )

        val mediaItem = MediaItem.Builder()
            .setUri(Uri.parse("android.resource://$packageName/${R.raw.adhan}"))
            .setMediaMetadata(MediaMetadata.Builder().setTitle(prayer).build())
            .build()
        player.setMediaItem(mediaItem)
        player.prepare()
        player.play()
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        AdhanPlaybackStateStreamHandler.reset()
        if (activeInstance === this) activeInstance = null
        player.release()
        super.onDestroy()
        PrayerStatusNotification.refresh(this)
    }

    internal fun setPlaybackMuted(muted: Boolean): Boolean {
        if (!::player.isInitialized || playbackPrayer == null) return false
        isMuted = muted
        player.volume = if (muted) 0f else AdhanAudioPreferences.getVolume(this)
        AdhanPlaybackStateStreamHandler.update(
            isPlaying = player.isPlaying,
            prayer = playbackPrayer,
            isMuted = isMuted,
        )
        promoteToForeground(PLAYBACK_NOTIFICATION_ID, buildNotification())
        return true
    }

    internal fun updateSavedVolume(volume: Float) {
        if (::player.isInitialized && !isMuted) {
            player.volume = volume.coerceIn(0f, 1f)
        }
    }

    private fun stopPlayback(startId: Int? = null) {
        if (::player.isInitialized) {
            player.stop()
            player.clearMediaItems()
        }
        playbackPrayer = null
        isMuted = false
        AdhanPlaybackStateStreamHandler.reset()
        stopForeground(STOP_FOREGROUND_REMOVE)
        PrayerStatusNotification.refresh(this)
        if (startId == null) stopSelf() else stopSelf(startId)
    }

    private fun buildNotification(): Notification =
        PrayerStatusNotification.buildForeground(this, playbackPrayer, isMuted)

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
        // Existing alarms can survive an app update with their earlier per-prayer IDs.
        val assetIds = setOf(
            "adhan",
            "adhan_fajr",
            "adhan_dhuhr",
            "adhan_asr",
            "adhan_maghrib",
            "adhan_isha",
        )
        private var activeInstance: AdhanPlaybackService? = null

        fun setActivePlaybackMuted(muted: Boolean): Boolean =
            activeInstance?.setPlaybackMuted(muted) ?: false

        fun updateActiveVolume(volume: Float) {
            activeInstance?.updateSavedVolume(volume)
        }

        fun refreshActiveNotification(): Boolean {
            val service = activeInstance ?: return false
            if (service.playbackPrayer == null) return false
            service.promoteToForeground(PLAYBACK_NOTIFICATION_ID, service.buildNotification())
            return true
        }

        const val PLAYBACK_CHANNEL_ID = "adhan_playback_v2"
        private const val PLAYBACK_NOTIFICATION_ID = 701
    }
}
