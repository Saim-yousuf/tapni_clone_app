package com.example.tapni_app.callerid

import android.content.Context

object CallerIdStore {
    private const val PREFS = "barqody_caller_id"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_TOKEN = "token"
    private const val KEY_BASE_URL = "base_url"
    private const val KEY_LANG = "lang"

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(
        context: Context,
        enabled: Boolean,
        token: String,
        baseUrl: String,
        lang: String = "en",
    ) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putString(KEY_TOKEN, token)
            .putString(KEY_BASE_URL, baseUrl.trimEnd('/'))
            .putString(KEY_LANG, lang)
            .apply()
    }

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, true)

    fun token(context: Context): String = prefs(context).getString(KEY_TOKEN, "") ?: ""

    fun baseUrl(context: Context): String = prefs(context).getString(KEY_BASE_URL, "") ?: ""

    fun lang(context: Context): String = prefs(context).getString(KEY_LANG, "en") ?: "en"

    fun verifiedLabel(context: Context): String {
        return if (lang(context).startsWith("ur")) "تصدیق شدہ پروفائل" else "Verified profile"
    }
}
