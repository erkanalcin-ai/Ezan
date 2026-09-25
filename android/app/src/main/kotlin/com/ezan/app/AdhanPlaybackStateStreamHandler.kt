package com.ezan.app

import io.flutter.plugin.common.EventChannel

internal object AdhanPlaybackStateStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var isPlaying = false
    private var prayer: String? = null
    private var isMuted = false

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        events.success(snapshot())
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun update(isPlaying: Boolean, prayer: String?, isMuted: Boolean) {
        this.isPlaying = isPlaying
        this.prayer = prayer
        this.isMuted = isMuted
        eventSink?.success(snapshot())
    }

    fun reset() = update(isPlaying = false, prayer = null, isMuted = false)

    private fun snapshot(): Map<String, Any?> = mapOf(
        "isPlaying" to isPlaying,
        "prayer" to prayer,
        "isMuted" to isMuted,
    )
}
