package com.example.tapni_app.callerid

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.util.Log

class IncomingCallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        if (!CallerIdStore.isEnabled(context)) return
        if (DialerRoles.canUseOwnCallUi(context)) return

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        Log.i(TAG, "PHONE_STATE state=$state number=$number")
        val pending = goAsync()
        val appContext = context.applicationContext

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                ringing = true
                val direct = CallNumberResolver.fromIntentExtra(number)
                if (direct != null) {
                    CallerIdOverlay.showIncoming(appContext, direct)
                    pending.finish()
                    return
                }

                // OEM / Android 10+: number often redacted until screening role is held.
                // Retry call-log a few times while the phone is still ringing.
                Log.w(TAG, "RINGING without EXTRA_INCOMING_NUMBER — trying call-log fallback")
                tryShowFromCallLog(appContext)
                mainHandler.postDelayed({ if (ringing) tryShowFromCallLog(appContext) }, 400)
                mainHandler.postDelayed({ if (ringing) tryShowFromCallLog(appContext) }, 1200)
                mainHandler.postDelayed({ if (ringing) tryShowFromCallLog(appContext) }, 2500)
                pending.finish()
            }
            TelephonyManager.EXTRA_STATE_IDLE,
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                ringing = false
                CallerIdOverlay.hide(appContext)
                pending.finish()
            }
            else -> pending.finish()
        }
    }

    private fun tryShowFromCallLog(context: Context) {
        val fallback = CallNumberResolver.fromRecentCallLog(context) ?: return
        CallerIdOverlay.showIncoming(context, fallback)
    }

    companion object {
        private const val TAG = "BarqodyCallerId"
        private val mainHandler = Handler(Looper.getMainLooper())
        @Volatile
        private var ringing = false
    }
}
