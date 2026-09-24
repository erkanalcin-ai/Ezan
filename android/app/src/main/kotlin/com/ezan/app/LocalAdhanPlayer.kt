package com.ezan.app

import android.content.Context
import android.net.Uri
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer

/** Foreground local playback for preview/testing; Phase 5 supplies scheduled playback. */
internal class LocalAdhanPlayer(private val context: Context) {
    private var player: ExoPlayer? = null
    private var readinessListener: Player.Listener? = null
    private var readinessCallback: ((Throwable?) -> Unit)? = null

    fun play(assetId: String, onReady: (Throwable?) -> Unit) {
        require(assetId in adhanSlots) { "Unknown local adhan slot." }
        val placeholderResource = context.resources.getIdentifier(
            "placeholder_chime",
            "raw",
            context.packageName,
        )
        check(placeholderResource != 0) { "Licensed local adhan audio is not installed." }

        val currentPlayer = player ?: ExoPlayer.Builder(context).build().also { created ->
            created.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_ALARM)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(),
                false,
            )
            created.volume = AdhanAudioPreferences.getVolume(context)
            player = created
        }

        cancelPendingPlayback(IllegalStateException("Playback was replaced."))
        val listener = object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_READY) {
                    finishPendingPlayback(null)
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                finishPendingPlayback(error)
            }
        }
        readinessListener = listener
        readinessCallback = onReady
        currentPlayer.addListener(listener)
        currentPlayer.setMediaItem(
            MediaItem.fromUri(
                Uri.parse("android.resource://${context.packageName}/$placeholderResource"),
            ),
        )
        currentPlayer.prepare()
        currentPlayer.play()
    }

    fun setVolume(volume: Float) {
        player?.volume = volume.coerceIn(0f, 1f)
    }

    fun stop() {
        cancelPendingPlayback(IllegalStateException("Playback stopped."))
        player?.run {
            stop()
            clearMediaItems()
        }
    }

    fun release() {
        cancelPendingPlayback(IllegalStateException("Player released."))
        player?.release()
        player = null
    }

    private fun finishPendingPlayback(error: Throwable?) {
        val listener = readinessListener ?: return
        player?.removeListener(listener)
        readinessListener = null
        val callback = readinessCallback
        readinessCallback = null
        callback?.invoke(error)
    }

    private fun cancelPendingPlayback(error: Throwable) {
        if (readinessListener != null) finishPendingPlayback(error)
    }

    private companion object {
        val adhanSlots = setOf("adhan_fajr", "adhan_dhuhr", "adhan_asr", "adhan_maghrib", "adhan_isha")
    }
}
