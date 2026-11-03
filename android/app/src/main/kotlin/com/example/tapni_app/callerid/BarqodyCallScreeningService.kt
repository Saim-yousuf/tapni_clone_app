package com.example.tapni_app.callerid

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.PhoneAccount
import android.util.Log

class BarqodyCallScreeningService : CallScreeningService() {
    override fun onScreenCall(callDetails: Call.Details) {
        val response = CallResponse.Builder().build()
        respondToCall(callDetails, response)

        Log.i(TAG, "onScreenCall enabled=${CallerIdStore.isEnabled(this)} handle=${callDetails.handle}")
        if (!CallerIdStore.isEnabled(this)) return
        // When Barqody is the default dialer, InCallService owns the UI.
        if (DialerRoles.canUseOwnCallUi(this)) {
            Log.i(TAG, "skip overlay — default dialer InCallService handles UI")
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            callDetails.callDirection != Call.Details.DIRECTION_INCOMING
        ) {
            Log.i(TAG, "skip non-incoming direction=${callDetails.callDirection}")
            return
        }

        val handle = callDetails.handle ?: return
        if (handle.scheme != PhoneAccount.SCHEME_TEL && handle.scheme != "tel") return
        val number = handle.schemeSpecificPart ?: return
        if (number.isBlank()) return
        Log.i(TAG, "incoming number=$number")
        CallerIdOverlay.showIncoming(this, number)
    }

    companion object {
        private const val TAG = "BarqodyCallerId"
    }
}
