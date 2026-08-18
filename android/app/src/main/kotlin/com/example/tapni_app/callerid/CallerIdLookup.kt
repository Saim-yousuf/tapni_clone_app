package com.example.tapni_app.callerid

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

data class CallerIdMatch(
    val phone: String,
    val displayName: String,
    val company: String,
    val isSelfVerified: Boolean,
    val source: String,
    val matchCount: Int,
)

sealed class CallerIdLookupResult {
    data class Hit(val match: CallerIdMatch) : CallerIdLookupResult()
    data class Miss(val phone: String) : CallerIdLookupResult()
    object Error : CallerIdLookupResult()
}

object CallerIdLookup {
    fun normalizePhone(raw: String, defaultCc: String = "+92"): String? {
        var value = raw.trim().replace(Regex("[\\s\\-()]"), "")
        if (value.isEmpty()) return null
        if (value.startsWith("00")) value = "+${value.substring(2)}"
        if (value.startsWith("+")) {
            val digits = value.substring(1).replace(Regex("\\D"), "")
            return if (digits.isEmpty()) null else "+$digits"
        }
        var digits = value.replace(Regex("\\D"), "")
        if (digits.isEmpty()) return null
        if (digits.startsWith("0")) digits = digits.substring(1)
        val cc = defaultCc.replace(Regex("\\D"), "")
        if (digits.startsWith(cc)) return "+$digits"
        return "+$cc$digits"
    }

    fun lookup(context: android.content.Context, rawPhone: String): CallerIdLookupResult {
        val phone = normalizePhone(rawPhone) ?: return CallerIdLookupResult.Error
        val token = CallerIdStore.token(context)
        val baseUrl = CallerIdStore.baseUrl(context)
        if (token.isBlank() || baseUrl.isBlank()) return CallerIdLookupResult.Error

        val encoded = URLEncoder.encode(phone, "UTF-8")
        val url = URL("$baseUrl/api/user/directory/lookup?phone=$encoded")
        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 8000
            readTimeout = 8000
            setRequestProperty("Authorization", "Bearer $token")
            setRequestProperty("Accept", "application/json")
        }

        return try {
            val code = connection.responseCode
            if (code !in 200..299) return CallerIdLookupResult.Error
            val body = connection.inputStream.bufferedReader().use { it.readText() }
            val json = JSONObject(body)
            if (!json.optBoolean("found", false)) return CallerIdLookupResult.Miss(phone)
            val data = json.optJSONObject("data") ?: return CallerIdLookupResult.Miss(phone)
            val name = data.optString("displayName", "").trim()
            if (name.isEmpty()) return CallerIdLookupResult.Miss(phone)
            CallerIdLookupResult.Hit(
                CallerIdMatch(
                    phone = data.optString("phone", phone),
                    displayName = name,
                    company = data.optString("company", ""),
                    isSelfVerified = data.optBoolean("isSelfVerified", false),
                    source = data.optString("source", "crowd"),
                    matchCount = data.optInt("matchCount", 0),
                ),
            )
        } catch (_: Exception) {
            CallerIdLookupResult.Error
        } finally {
            connection.disconnect()
        }
    }
}
