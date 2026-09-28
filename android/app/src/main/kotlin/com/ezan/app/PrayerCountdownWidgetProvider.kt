package com.ezan.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews

class PrayerCountdownWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        PrayerWidgetSchedule.refresh(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        fun hasWidgets(context: Context): Boolean =
            AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, PrayerCountdownWidgetProvider::class.java))
                .isNotEmpty()

        fun updateWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, PrayerCountdownWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { id ->
                updateWidget(context, manager, id)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val localized = PrayerWidgetAppearance.localizedContext(context)
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_countdown)
            val root = R.id.widget_root
            PrayerWidgetAppearance.apply(views, root, context)
            views.setTextColor(R.id.widget_brand, PrayerWidgetAppearance.accent())
            views.setTextColor(R.id.widget_prayer, PrayerWidgetAppearance.primary(context))
            views.setTextColor(R.id.widget_countdown, PrayerWidgetAppearance.primary(context))
            views.setTextColor(R.id.widget_subtitle, PrayerWidgetAppearance.secondary(context))
            views.setTextViewText(R.id.widget_brand, localized.getString(R.string.widget_brand))

            val next = PrayerWidgetSchedule.nextPrayer(context)
            if (next == null) {
                views.setTextViewText(
                    R.id.widget_prayer,
                    localized.getString(R.string.widget_prayer_status_title),
                )
                views.setViewVisibility(R.id.widget_countdown, android.view.View.GONE)
                views.setTextViewText(
                    R.id.widget_subtitle,
                    localized.getString(
                        if (PrayerWidgetSchedule.isStale(context)) {
                            R.string.widget_refresh_required
                        } else {
                            R.string.widget_location_required
                        },
                    ),
                )
            } else {
                views.setTextViewText(
                    R.id.widget_prayer,
                    PrayerWidgetAppearance.prayerLabel(context, next.prayer)
                        .uppercase(localized.resources.configuration.locales[0]),
                )
                val remaining = next.timestamp - System.currentTimeMillis()
                val base = SystemClock.elapsedRealtime() + remaining
                views.setChronometer(R.id.widget_countdown, base, null, true)
                views.setChronometerCountDown(R.id.widget_countdown, true)
                views.setViewVisibility(R.id.widget_countdown, android.view.View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_subtitle,
                    localized.getString(R.string.widget_countdown_subtitle),
                )
            }

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(root, openPendingIntent)
            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
