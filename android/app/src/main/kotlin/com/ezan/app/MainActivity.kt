package com.ezan.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var qiblaOrientationStream: QiblaOrientationStreamHandler? = null
    private var localAdhanPlayer: LocalAdhanPlayer? = null
    private var adhanPlaybackChannel: MethodChannel? = null
    private var prayerAlarmChannel: MethodChannel? = null
    private var prayerCalculationSettingsChannel: MethodChannel? = null
    private var uiPreferencesChannel: MethodChannel? = null
    private var privacyPolicyChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        privacyPolicyChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/privacy_policy",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "open") {
                    try {
                        startActivity(
                            Intent(
                                Intent.ACTION_VIEW,
                                Uri.parse(PRIVACY_POLICY_URL),
                            ),
                        )
                        result.success(null)
                    } catch (_: ActivityNotFoundException) {
                        result.error(
                            "NO_BROWSER",
                            "No application can open the privacy policy link.",
                            null,
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }
        }
        qiblaOrientationStream = QiblaOrientationStreamHandler(this).also { handler ->
            EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "com.ezan.app/qibla/orientation",
            ).setStreamHandler(handler)
        }
        adhanPlaybackChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/adhan_playback",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val assetId = call.argument<String>("assetId")
                        if (assetId == null) {
                            result.error("INVALID_AUDIO", "An adhan asset id is required.", null)
                        } else {
                            try {
                                (localAdhanPlayer ?: LocalAdhanPlayer(this).also {
                                    localAdhanPlayer = it
                                }).play(assetId) { playbackError ->
                                    if (playbackError == null) {
                                        result.success(null)
                                    } else {
                                        result.error(
                                            "PLAYBACK_FAILED",
                                            "Media3 could not play the local audio.",
                                            null,
                                        )
                                    }
                                }
                            } catch (error: IllegalArgumentException) {
                                result.error("INVALID_AUDIO", error.message, null)
                            } catch (error: IllegalStateException) {
                                result.error("AUDIO_UNAVAILABLE", error.message, null)
                            } catch (error: Exception) {
                                result.error("PLAYBACK_FAILED", "Local playback failed.", null)
                            }
                        }
                    }
                    "stop" -> {
                        localAdhanPlayer?.stop()
                        result.success(null)
                    }
                    "getVolume" -> result.success(AdhanAudioPreferences.getVolume(this))
                    "setVolume" -> {
                        val volume = call.argument<Double>("volume")
                        if (volume == null || volume !in 0.0..1.0) {
                            result.error("INVALID_VOLUME", "Volume must be between 0 and 1.", null)
                        } else {
                            AdhanAudioPreferences.setVolume(this, volume.toFloat())
                            localAdhanPlayer?.setVolume(volume.toFloat())
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        prayerAlarmChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/prayer_alarms",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(PrayerAlarmScheduler.status(this))
                    "requestAccess" -> {
                        PrayerAlarmScheduler.requestAccess(this)
                        result.success(null)
                    }
                    "disable" -> {
                        PrayerAlarmScheduler.disable(this)
                        result.success(null)
                    }
                    "schedule" -> {
                        val rawEvents = call.argument<List<Map<String, Any>>>("events")
                        if (rawEvents == null) {
                            result.error("INVALID_SCHEDULE", "Prayer alarm events are required.", null)
                        } else {
                            try {
                                val events = JSONArray()
                                rawEvents.forEach { event ->
                                    val assetId = event["assetId"] as? String
                                    val timestamp = (event["timestamp"] as? Number)?.toLong()
                                    val prayer = event["prayer"] as? String
                                    require(assetId != null && assetId in AdhanPlaybackService.assetIds && timestamp != null && prayer != null)
                                    events.put(JSONObject().apply {
                                        put("assetId", assetId)
                                        put("timestamp", timestamp)
                                        put("prayer", prayer)
                                    })
                                }
                                PrayerAlarmScheduler.replaceEvents(this, events.toString())
                                result.success(null)
                            } catch (error: IllegalArgumentException) {
                                result.error("INVALID_SCHEDULE", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        prayerCalculationSettingsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/prayer_calculation_settings",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAsrMethod" -> result.success(PrayerCalculationSettings.getAsrMethod(this))
                    "setAsrMethod" -> {
                        val method = call.argument<String>("method")
                        if (method != "standard" && method != "hanafi") {
                            result.error("INVALID_ASR_METHOD", "Asr method is invalid.", null)
                        } else {
                            PrayerCalculationSettings.setAsrMethod(this, method!!)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        uiPreferencesChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/ui_preferences",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getThemeMode" -> result.success(UiPreferences.getThemeMode(this))
                    "setThemeMode" -> {
                        val mode = call.argument<String>("mode")
                        if (mode !in setOf("system", "light", "dark")) {
                            result.error("INVALID_THEME_MODE", "Theme mode is invalid.", null)
                        } else {
                            UiPreferences.setThemeMode(this, mode!!)
                            result.success(null)
                        }
                    }
                    "getLocale" -> result.success(UiPreferences.getLocale(this))
                    "setLocale" -> {
                        val languageCode = call.argument<String>("languageCode")
                        if (languageCode != null && languageCode !in setOf("tr", "en")) {
                            result.error("INVALID_LOCALE", "Locale is not supported.", null)
                        } else {
                            UiPreferences.setLocale(this, languageCode)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        qiblaOrientationStream?.stop()
        qiblaOrientationStream = null
        localAdhanPlayer?.release()
        localAdhanPlayer = null
        adhanPlaybackChannel?.setMethodCallHandler(null)
        adhanPlaybackChannel = null
        prayerAlarmChannel?.setMethodCallHandler(null)
        prayerAlarmChannel = null
        prayerCalculationSettingsChannel?.setMethodCallHandler(null)
        prayerCalculationSettingsChannel = null
        uiPreferencesChannel?.setMethodCallHandler(null)
        uiPreferencesChannel = null
        privacyPolicyChannel?.setMethodCallHandler(null)
        privacyPolicyChannel = null
        super.onDestroy()
    }

    private companion object {
        const val PRIVACY_POLICY_URL =
            "https://erkanalcin-ai.github.io/Ezan/privacy-policy.html"
    }
}
