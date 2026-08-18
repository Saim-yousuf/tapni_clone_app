package com.example.tapni_app.callerid

import android.content.Context
import org.json.JSONObject

object CallerIdCache {
    private const val PREFS = "barqody_caller_id_cache"
    private const val KEY_ENTRIES = "entries"
    private const val MAX_ENTRIES = 500

    private val memory = LinkedHashMap<String, CallerIdMatch>(64, 0.75f, true)

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun get(context: Context, phone: String): CallerIdMatch? {
        memory[phone]?.let { return it }
        val entries = readEntries(context)
        val item = entries.optJSONObject(phone) ?: return null
        val match = item.toMatch(phone) ?: return null
        memory[phone] = match
        return match
    }

    @Synchronized
    fun put(context: Context, match: CallerIdMatch) {
        if (match.phone.isBlank() || match.displayName.isBlank()) return
        memory[match.phone] = match
        val entries = readEntries(context)
        entries.put(match.phone, match.toJson())
        trim(entries)
        prefs(context).edit().putString(KEY_ENTRIES, entries.toString()).apply()
    }

    @Synchronized
    fun remove(context: Context, phone: String) {
        memory.remove(phone)
        val entries = readEntries(context)
        entries.remove(phone)
        prefs(context).edit().putString(KEY_ENTRIES, entries.toString()).apply()
    }

    private fun readEntries(context: Context): JSONObject {
        val raw = prefs(context).getString(KEY_ENTRIES, "") ?: ""
        return try {
            if (raw.isBlank()) JSONObject() else JSONObject(raw)
        } catch (_: Exception) {
            JSONObject()
        }
    }

    private fun trim(entries: JSONObject) {
        if (entries.length() <= MAX_ENTRIES) return
        val keys = entries.keys().asSequence().toList()
        val oldest = keys
            .map { key -> key to entries.optJSONObject(key)?.optLong("savedAt", 0L) }
            .sortedBy { it.second }
            .take(entries.length() - MAX_ENTRIES)
        for ((key, _) in oldest) {
            entries.remove(key)
            memory.remove(key)
        }
    }

    private fun CallerIdMatch.toJson(): JSONObject =
        JSONObject()
            .put("phone", phone)
            .put("displayName", displayName)
            .put("company", company)
            .put("isSelfVerified", isSelfVerified)
            .put("source", source)
            .put("matchCount", matchCount)
            .put("savedAt", System.currentTimeMillis())

    private fun JSONObject.toMatch(fallbackPhone: String): CallerIdMatch? {
        val name = optString("displayName", "").trim()
        if (name.isEmpty()) return null
        return CallerIdMatch(
            phone = optString("phone", fallbackPhone),
            displayName = name,
            company = optString("company", ""),
            isSelfVerified = optBoolean("isSelfVerified", false),
            source = optString("source", "crowd"),
            matchCount = optInt("matchCount", 0),
        )
    }
}
