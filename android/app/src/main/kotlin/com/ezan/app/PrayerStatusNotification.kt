package com.ezan.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews

internal object PrayerStatusNotification {
    const val ACTION_MUTE_ADHAN = "com.ezan.app.action.MUTE_ADHAN_FROM_STATUS"
    private const val CHANNEL_ID = "prayer_status_v2"
    private const val NOTIFICATION_ID = 702
    private const val OPEN_REQUEST_CODE = 702
    private const val MUTE_REQUEST_CODE = 703

    fun refresh(context: Context) {
        if (AdhanPlaybackService.refreshActiveNotification()) {
            cancelStatus(context)
            return
        }
        if (!PrayerStatusPreferences.isEnabled(context) ||
            !PrayerStatusPreferences.canPostNotifications(context)
        ) {
            cancelStatus(context)
            return
        }
        ensureChannel(context)
        try {
            context.getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, buildCountdown(context, CHANNEL_ID))
        } catch (_: SecurityException) {
            // The OS can revoke notification access while this status is active.
        }
    }

    fun cancelStatus(context: Context) {
        context.getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
    }

    fun buildForeground(
        context: Context,
        prayer: String?,
        isMuted: Boolean,
    ): Notification {
        ensureChannel(context, AdhanPlaybackService.PLAYBACK_CHANNEL_ID)
        val isPlaying = prayer != null && !isMuted
        val views = createViews(context, prayer, isPlaying, isMuted)
        val localized = PrayerWidgetAppearance.localizedContext(context)
        val text = if (isPlaying) {
            localized.getString(R.string.notification_adhan_playing)
        } else {
            PrayerWidgetSchedule.nextPrayer(context)?.let {
                localized.getString(
                    R.string.notification_next_prayer,
                    PrayerWidgetAppearance.prayerLabel(context, it.prayer),
                )
            } ?: localized.getString(R.string.widget_refresh_required)
        }
        return notificationBuilder(context, AdhanPlaybackService.PLAYBACK_CHANNEL_ID)
            .setContentTitle(localized.getString(R.string.widget_brand))
            .setContentText(text)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setOngoing(true)
            .setCustomContentView(views)
            .setCustomBigContentView(views)
            .build()
    }

    private fun buildCountdown(context: Context, channelId: String): Notification {
        val localized = PrayerWidgetAppearance.localizedContext(context)
        val next = PrayerWidgetSchedule.nextPrayer(context)
        val title = next?.let {
            "${localized.getString(R.string.widget_brand)} · " +
                PrayerWidgetAppearance.prayerLabel(context, it.prayer)
                    .uppercase(localized.resources.configuration.locales[0])
        } ?: localized.getString(R.string.widget_brand)
        val text = if (next != null) {
            localized.getString(R.string.widget_countdown_subtitle)
        } else {
            localized.getString(
                if (PrayerWidgetSchedule.isStale(context)) {
                    R.string.widget_refresh_required
                } else {
                    R.string.widget_location_required
                },
            )
        }
        return notificationBuilder(context, channelId)
            .setContentTitle(title)
            .setContentText(text)
            .setCategory(Notification.CATEGORY_STATUS)
            .setOngoing(true)
            .setShowWhen(next != null)
            .apply {
                if (next != null) {
                    setWhen(next.timestamp)
                    setUsesChronometer(true)
                    setChronometerCountDown(true)
                }
            }
            .build()
    }

    private fun createViews(
        context: Context,
        prayer: String?,
        isPlaying: Boolean,
        isMuted: Boolean,
    ): RemoteViews {
        val localized = PrayerWidgetAppearance.localizedContext(context)
        val views = RemoteViews(context.packageName, R.layout.notification_prayer_status)
        PrayerWidgetAppearance.apply(views, R.id.notification_root, context)
        views.setInt(
            R.id.notification_speaker_button,
            "setBackgroundResource",
            if (PrayerWidgetAppearance.isDark(context)) {
                R.drawable.notification_action_dark
            } else {
                R.drawable.notification_action_light
            },
        )
        views.setTextColor(R.id.notification_brand, PrayerWidgetAppearance.accent())
        views.setTextColor(R.id.notification_prayer, PrayerWidgetAppearance.primary(context))
        views.setTextColor(R.id.notification_countdown, PrayerWidgetAppearance.primary(context))
        views.setTextColor(R.id.notification_subtitle, PrayerWidgetAppearance.secondary(context))
        views.setTextViewText(R.id.notification_brand, localized.getString(R.string.widget_brand))

        val next = if (!isPlaying) PrayerWidgetSchedule.nextPrayer(context) else null
        when {
            isPlaying && prayer != null -> {
                views.setTextViewText(
                    R.id.notification_prayer,
                    PrayerWidgetAppearance.prayerLabel(context, prayer)
                        .uppercase(localized.resources.configuration.locales[0]),
                )
                views.setViewVisibility(R.id.notification_countdown, View.GONE)
                views.setTextViewText(
                    R.id.notification_subtitle,
                    localized.getString(R.string.notification_adhan_playing),
                )
            }
            next != null -> {
                views.setTextViewText(
                    R.id.notification_prayer,
                    PrayerWidgetAppearance.prayerLabel(context, next.prayer)
                        .uppercase(localized.resources.configuration.locales[0]),
                )
                val remaining = next.timestamp - System.currentTimeMillis()
                val base = android.os.SystemClock.elapsedRealtime() + remaining
                views.setChronometer(R.id.notification_countdown, base, null, true)
                views.setChronometerCountDown(R.id.notification_countdown, true)
                views.setViewVisibility(R.id.notification_countdown, View.VISIBLE)
                views.setTextViewText(
                    R.id.notification_subtitle,
                    localized.getString(R.string.widget_countdown_subtitle),
                )
            }
            else -> {
                views.setTextViewText(
                    R.id.notification_prayer,
                    localized.getString(R.string.widget_prayer_status_title),
                )
                views.setViewVisibility(R.id.notification_countdown, View.GONE)
                views.setTextViewText(
                    R.id.notification_subtitle,
                    localized.getString(
                        if (PrayerWidgetSchedule.isStale(context)) {
                            R.string.widget_refresh_required
                        } else {
                            R.string.widget_location_required
                        },
                    ),
                )
            }
        }

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            OPEN_REQUEST_CODE,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.notification_root, openPendingIntent)

        val muteButtonVisibility = if (isPlaying && !isMuted) View.VISIBLE else View.GONE
        views.setViewVisibility(R.id.notification_speaker_button, muteButtonVisibility)
        if (muteButtonVisibility == View.VISIBLE) {
            views.setImageViewResource(
                R.id.notification_speaker_button,
                R.drawable.ic_speaker_mute,
            )
            views.setContentDescription(
                R.id.notification_speaker_button,
                localized.getString(R.string.notification_mute_adhan),
            )
            val muteIntent = Intent(context, PrayerStatusActionReceiver::class.java).apply {
                action = ACTION_MUTE_ADHAN
            }
            val mutePendingIntent = PendingIntent.getBroadcast(
                context,
                MUTE_REQUEST_CODE,
                muteIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.notification_speaker_button, mutePendingIntent)
        }
        return views
    }

    private fun notificationBuilder(context: Context, channelId: String): Notification.Builder {
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            OPEN_REQUEST_CODE,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            Notification.Builder(context)
        }.setSmallIcon(R.drawable.ic_notification_ezan)
            .setColor(PrayerWidgetAppearance.accent())
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setContentIntent(contentIntent)
            .setPublicVersion(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Notification.Builder(context, channelId)
                } else {
                    Notification.Builder(context)
                }
                    .setSmallIcon(R.drawable.ic_notification_ezan)
                    .setContentTitle(PrayerWidgetAppearance.localizedContext(context).getString(R.string.widget_brand))
                    .setContentText(PrayerWidgetAppearance.localizedContext(context).getString(R.string.notification_lock_screen_status))
                    .setVisibility(Notification.VISIBILITY_PUBLIC)
                    .build(),
            )
    }

    private fun ensureChannel(context: Context, channelId: String = CHANNEL_ID) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val (nameId, descriptionId) = if (channelId == CHANNEL_ID) {
            R.string.prayer_status_channel_name to R.string.prayer_status_channel_description
        } else {
            R.string.playback_notification_channel_name to
                R.string.playback_notification_channel_description
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(channelId) == null) {
            val localized = PrayerWidgetAppearance.localizedContext(context)
            manager.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    localized.getString(nameId),
                    // The lock-screen countdown must remain visible. Keep it silent
                    // explicitly while giving it the default visual importance.
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = localized.getString(descriptionId)
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                },
            )
        }
    }
}
