package com.ezan.app

import android.content.Context

internal object UiPreferences {
    private const val PREFS = "ui_preferences"
    private const val THEME_MODE = "theme_mode"
    private const val LOCALE = "locale"

    fun getThemeMode(context: Context): String =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(THEME_MODE, "system")
            ?.takeIf { it in setOf("system", "light", "dark") }
            ?: "system"

    fun setThemeMode(context: Context, mode: String) {
        require(mode in setOf("system", "light", "dark"))
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(THEME_MODE, mode)
            .apply()
    }

    fun getLocale(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(LOCALE, null)
            ?.takeIf { it == "tr" || it == "en" }

    fun setLocale(context: Context, languageCode: String?) {
        require(languageCode == null || languageCode == "tr" || languageCode == "en")
        val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val editor = preferences.edit()
        if (languageCode == null) {
            editor.remove(LOCALE)
        } else {
            editor.putString(LOCALE, languageCode)
        }
        editor.apply()
    }
}
