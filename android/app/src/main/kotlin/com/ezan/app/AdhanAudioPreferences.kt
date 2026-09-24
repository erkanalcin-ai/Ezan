package com.ezan.app

import android.content.Context

internal object AdhanAudioPreferences {
    private const val PREFS = "adhan_audio"
    private const val VOLUME = "volume"

    fun getVolume(context: Context): Float = context
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        .getFloat(VOLUME, 1f)
        .coerceIn(0f, 1f)

    fun setVolume(context: Context, volume: Float) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putFloat(VOLUME, volume.coerceIn(0f, 1f))
            .apply()
    }
}
