package com.ezan.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
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
    private var adhanPlaybackStateChannel: EventChannel? = null
    private var prayerAlarmChannel: MethodChannel? = null
    private var prayerWidgetChannel: MethodChannel? = null
    private var prayerStatusChannel: MethodChannel? = null
    private var prayerCalculationSettingsChannel: MethodChannel? = null
    private var uiPreferencesChannel: MethodChannel? = null
    private var privacyPolicyChannel: MethodChannel? = null
    private var playUpdateChannel: MethodChannel? = null
    private var pendingPrayerStatusResult: MethodChannel.Result? = null
    private lateinit var playUpdateManager: AppUpdateManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lock-screen status is paused; clear any opt-in saved by a prior build.
        PrayerStatusPreferences.setEnabled(this, false)
        PrayerStatusNotification.cancelStatus(this)
        playUpdateManager = AppUpdateManagerFactory.create(this)
        playUpdateChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/play_updates",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkForUpdate" -> playUpdateManager.appUpdateInfo
                        .addOnSuccessListener { info ->
                            val updateAvailable =
                                info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                                    info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE) ||
                                    info.updateAvailability() ==
                                    UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
                            result.success(updateAvailable)
                        }
                        .addOnFailureListener { result.success(false) }
                    "startImmediateUpdate" -> playUpdateManager.appUpdateInfo
                        .addOnSuccessListener { info ->
                            val canResume = info.updateAvailability() ==
                                UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
                            val canStart = info.updateAvailability() ==
                                UpdateAvailability.UPDATE_AVAILABLE &&
                                info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
                            if (!canResume && !canStart) {
                                result.success(false)
                            } else {
                                try {
                                    val started = playUpdateManager.startUpdateFlowForResult(
                                        info,
                                        this,
                                        AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE)
                                            .build(),
                                        PLAY_UPDATE_REQUEST_CODE,
                                    )
                                    result.success(started)
                                } catch (_: Exception) {
                                    result.success(false)
                                }
                            }
                        }
                        .addOnFailureListener { result.success(false) }
                    else -> result.notImplemented()
                }
            }
        }
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
        adhanPlaybackStateChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/adhan_playback_state",
        ).also { channel ->
            channel.setStreamHandler(AdhanPlaybackStateStreamHandler)
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
                            AdhanPlaybackService.updateActiveVolume(volume.toFloat())
                            result.success(null)
                        }
                    }
                    "setPlaybackMuted" -> {
                        val muted = call.argument<Boolean>("muted")
                        if (muted == null) {
                            result.error("INVALID_MUTE_STATE", "A mute state is required.", null)
                        } else {
                            val scheduledPlaybackMuted =
                                AdhanPlaybackService.setActivePlaybackMuted(muted)
                            val localPlaybackMuted =
                                localAdhanPlayer?.setPlaybackMuted(muted) ?: false
                            result.success(scheduledPlaybackMuted || localPlaybackMuted)
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
        prayerWidgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/prayer_widgets",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "shouldSync" -> result.success(PrayerWidgetSchedule.shouldSync(this))
                    "clearSchedule" -> {
                        PrayerWidgetSchedule.clear(this)
                        result.success(null)
                    }
                    "replaceSchedule" -> {
                        val rawEvents = call.argument<List<Map<String, Any>>>("events")
                        if (rawEvents == null) {
                            result.error(
                                "INVALID_WIDGET_SCHEDULE",
                                "Prayer events are required.",
                                null,
                            )
                        } else {
                            try {
                                val events = JSONArray()
                                rawEvents.forEach { event ->
                                    val timestamp = (event["timestamp"] as? Number)?.toLong()
                                    val prayer = (event["prayer"] as? String)
                                        ?.lowercase()
                                        ?.takeIf {
                                            it in setOf("fajr", "dhuhr", "asr", "maghrib", "isha")
                                        }
                                    require(
                                        timestamp != null &&
                                            timestamp > 0L &&
                                            prayer != null,
                                    )
                                    events.put(JSONObject().apply {
                                        put("timestamp", timestamp)
                                        put("prayer", prayer)
                                    })
                                }
                                PrayerWidgetSchedule.replace(this, events.toString())
                                result.success(null)
                            } catch (error: IllegalArgumentException) {
                                result.error(
                                    "INVALID_WIDGET_SCHEDULE",
                                    error.message,
                                    null,
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        prayerStatusChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ezan.app/prayer_status",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getEnabled" -> result.success(PrayerStatusPreferences.isEnabled(this))
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled")
                        if (enabled == null) {
                            result.error(
                                "INVALID_PRAYER_STATUS",
                                "A lock-screen status setting is required.",
                                null,
                            )
                        } else {
                            setPrayerStatusEnabled(enabled, result)
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
                            PrayerWidgetSchedule.refresh(this)
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
                            PrayerWidgetSchedule.refresh(this)
                            result.success(null)
                        }
                    }
                    "getQiblaNorthReference" ->
                        result.success(UiPreferences.getQiblaNorthReference(this))
                    "setQiblaNorthReference" -> {
                        val reference = call.argument<String>("reference")
                        if (reference !in setOf("true", "magnetic")) {
                            result.error(
                                "INVALID_QIBLA_NORTH_REFERENCE",
                                "Qibla north reference is invalid.",
                                null,
                            )
                        } else {
                            UiPreferences.setQiblaNorthReference(this, reference!!)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PRAYER_STATUS_PERMISSION_REQUEST) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED &&
            PrayerStatusPreferences.canPostNotifications(this)
        PrayerStatusPreferences.setEnabled(this, granted)
        PrayerWidgetSchedule.refresh(this)
        pendingPrayerStatusResult?.success(granted)
        pendingPrayerStatusResult = null
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        PrayerWidgetSchedule.refresh(this)
    }

    override fun onDestroy() {
        qiblaOrientationStream?.stop()
        qiblaOrientationStream = null
        localAdhanPlayer?.release()
        localAdhanPlayer = null
        adhanPlaybackStateChannel?.setStreamHandler(null)
        adhanPlaybackStateChannel = null
        adhanPlaybackChannel?.setMethodCallHandler(null)
        adhanPlaybackChannel = null
        prayerAlarmChannel?.setMethodCallHandler(null)
        prayerAlarmChannel = null
        prayerWidgetChannel?.setMethodCallHandler(null)
        prayerWidgetChannel = null
        prayerStatusChannel?.setMethodCallHandler(null)
        prayerStatusChannel = null
        prayerCalculationSettingsChannel?.setMethodCallHandler(null)
        prayerCalculationSettingsChannel = null
        uiPreferencesChannel?.setMethodCallHandler(null)
        uiPreferencesChannel = null
        privacyPolicyChannel?.setMethodCallHandler(null)
        privacyPolicyChannel = null
        playUpdateChannel?.setMethodCallHandler(null)
        playUpdateChannel = null
        pendingPrayerStatusResult?.success(false)
        pendingPrayerStatusResult = null
        super.onDestroy()
    }

    private fun setPrayerStatusEnabled(enabled: Boolean, result: MethodChannel.Result) {
        if (!enabled) {
            PrayerStatusPreferences.setEnabled(this, false)
            PrayerWidgetSchedule.refresh(this)
            result.success(false)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingPrayerStatusResult != null) {
                result.error(
                    "PERMISSION_REQUEST_IN_PROGRESS",
                    "A notification permission request is already active.",
                    null,
                )
                return
            }
            pendingPrayerStatusResult = result
            requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                PRAYER_STATUS_PERMISSION_REQUEST,
            )
            return
        }
        val enabledBySystem = PrayerStatusPreferences.canPostNotifications(this)
        PrayerStatusPreferences.setEnabled(this, enabledBySystem)
        PrayerWidgetSchedule.refresh(this)
        result.success(enabledBySystem)
    }

    private companion object {
        const val PRAYER_STATUS_PERMISSION_REQUEST = 5306
        const val PLAY_UPDATE_REQUEST_CODE = 5305
        const val PRIVACY_POLICY_URL =
            "https://erkanalcin-ai.github.io/Ezan/privacy-policy.html"
    }
}
