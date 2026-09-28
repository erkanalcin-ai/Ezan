package com.ezan.app

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.widget.RemoteViews
import java.util.Locale

internal object PrayerWidgetAppearance {
    fun localizedContext(context: Context): Context {
        val language = UiPreferences.getLocale(context)
            ?: Locale.getDefault().language.takeIf { it == "tr" || it == "en" }
            ?: "en"
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale(language))
        return context.createConfigurationContext(configuration)
    }

    fun prayerLabel(context: Context, prayer: String): String {
        val localized = localizedContext(context)
        val resource = when (prayer.lowercase(Locale.ROOT)) {
            "fajr" -> R.string.prayer_fajr
            "dhuhr" -> R.string.prayer_dhuhr
            "asr" -> R.string.prayer_asr
            "maghrib" -> R.string.prayer_maghrib
            "isha" -> R.string.prayer_isha
            else -> return ""
        }
        return localized.getString(resource)
    }

    fun apply(remoteViews: RemoteViews, rootId: Int, context: Context) {
        val dark = when (UiPreferences.getThemeMode(context)) {
            "light" -> false
            "dark" -> true
            else -> (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
        }
        remoteViews.setInt(
            rootId,
            "setBackgroundResource",
            if (dark) R.drawable.widget_surface_dark else R.drawable.widget_surface_light,
        )
    }

    fun primary(context: Context): Int =
        if (isDark(context)) Color.rgb(244, 240, 225) else Color.rgb(37, 58, 46)

    fun secondary(context: Context): Int =
        if (isDark(context)) Color.rgb(197, 191, 173) else Color.rgb(86, 99, 88)

    fun accent(): Int = Color.rgb(210, 174, 91)

    fun isDark(context: Context): Boolean = when (UiPreferences.getThemeMode(context)) {
        "light" -> false
        "dark" -> true
        else -> (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES
    }
}
