package com.example.tapni_app.callerid

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.TelecomManager

class BarqodyCallScreeningService : CallScreeningService() {
    override fun onScreenCall(callDetails: Call.Details) {
        val response = CallResponse.Builder().build()
        respondToCall(callDetails, response)

        if (!CallerIdStore.isEnabled(this)) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            callDetails.callDirection != Call.Details.DIRECTION_INCOMING
        ) {
            return
        }

        val handle = callDetails.handle ?: return
        if (handle.scheme != TelecomManager.SCHEME_TEL && handle.scheme != "tel") return
        val number = handle.schemeSpecificPart ?: return
        if (number.isBlank()) return
        CallerIdOverlay.showIncoming(this, number)
    }
}
