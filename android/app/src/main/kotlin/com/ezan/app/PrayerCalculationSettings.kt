package com.ezan.app

import android.content.Context

internal object PrayerCalculationSettings {
    private const val PREFS = "prayer_calculation_settings"
    private const val ASR_METHOD = "asr_method"

    fun getAsrMethod(context: Context): String =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(ASR_METHOD, "standard")
            ?.takeIf { it == "standard" || it == "hanafi" }
            ?: "standard"

    fun setAsrMethod(context: Context, method: String) {
        require(method == "standard" || method == "hanafi")
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(ASR_METHOD, method)
            .apply()
    }
}
