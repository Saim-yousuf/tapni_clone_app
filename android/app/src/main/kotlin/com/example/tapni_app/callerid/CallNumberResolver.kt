package com.example.tapni_app.callerid

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CallLog
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * On many Android 10+ / OEM builds, PHONE_STATE omits EXTRA_INCOMING_NUMBER
 * unless the app holds the call-screening role. Call log is a practical fallback
 * when READ_CALL_LOG is granted.
 */
object CallNumberResolver {
    private const val TAG = "BarqodyCallerId"

    fun fromIntentExtra(raw: String?): String? {
        val value = raw?.trim().orEmpty()
        return value.ifBlank { null }
    }

    fun fromRecentCallLog(context: Context): String? {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.READ_CALL_LOG,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "call-log fallback skipped: no READ_CALL_LOG")
            return null
        }

        return try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DATE,
                ),
                null,
                null,
                "${CallLog.Calls.DATE} DESC",
            ) ?: return null

            cursor.use {
                val numberIdx = it.getColumnIndex(CallLog.Calls.NUMBER)
                val typeIdx = it.getColumnIndex(CallLog.Calls.TYPE)
                val dateIdx = it.getColumnIndex(CallLog.Calls.DATE)
                if (numberIdx < 0) return null

                val now = System.currentTimeMillis()
                while (it.moveToNext()) {
                    val number = it.getString(numberIdx)?.trim().orEmpty()
                    if (number.isBlank()) continue
                    val type = if (typeIdx >= 0) it.getInt(typeIdx) else CallLog.Calls.INCOMING_TYPE
                    val date = if (dateIdx >= 0) it.getLong(dateIdx) else now
                    // Prefer a very recent incoming/missed row (ringing / just answered).
                    val recent = now - date <= 60_000L
                    val incomingLike =
                        type == CallLog.Calls.INCOMING_TYPE ||
                            type == CallLog.Calls.MISSED_TYPE ||
                            type == CallLog.Calls.REJECTED_TYPE ||
                            type == CallLog.Calls.BLOCKED_TYPE
                    if (recent && incomingLike) {
                        Log.i(TAG, "call-log fallback number=$number type=$type ageMs=${now - date}")
                        return number
                    }
                }
            }
            Log.w(TAG, "call-log fallback: no recent incoming number")
            null
        } catch (e: Exception) {
            Log.w(TAG, "call-log fallback failed: ${e.message}")
            null
        }
    }
}
