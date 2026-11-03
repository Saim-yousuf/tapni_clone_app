package com.example.tapni_app.callerid

import android.content.Intent
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import android.telecom.PhoneAccount
import android.util.Log

/**
 * Default-dialer in-call UI host.
 *
 * Critical path: show ringing UI immediately with number / Unknown Number.
 * Directory lookup runs in background and only updates the name when ready —
 * never delays Telecom ringing.
 */
class BarqodyInCallService : InCallService() {
    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        super.onDestroy()
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        val raw = extractNumber(call) ?: ""
        val phone = CallerIdLookup.normalizePhone(raw) ?: raw
        Log.i(TAG, "onCallAdded state=${call.state} number=$phone")

        // 1) Bind call + provisional identity (instant).
        CallController.setCall(call, phone)

        // 2) Open UI immediately — do not wait for network.
        when (call.state) {
            Call.STATE_RINGING -> openIncoming()
            Call.STATE_DIALING,
            Call.STATE_CONNECTING,
            Call.STATE_ACTIVE,
            Call.STATE_HOLDING -> openInCall()
            else -> openInCall()
        }

        // 3) Lookup in background; UI listens via CallController.
        resolveNameAsync(phone)

        call.registerCallback(object : Call.Callback() {
            override fun onStateChanged(call: Call, state: Int) {
                Log.i(TAG, "call state -> $state")
                when (state) {
                    Call.STATE_RINGING -> openIncoming()
                    Call.STATE_ACTIVE,
                    Call.STATE_HOLDING,
                    Call.STATE_DIALING,
                    Call.STATE_CONNECTING -> openInCall()
                    Call.STATE_DISCONNECTED -> CallController.clearIfCurrent(call)
                }
            }
        })
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        Log.i(TAG, "onCallRemoved")
        CallController.clearIfCurrent(call)
    }

    fun setCallMuted(muted: Boolean): Boolean {
        return try {
            setMuted(muted)
            true
        } catch (e: Exception) {
            Log.e(TAG, "setMuted error: ${e.message}")
            false
        }
    }

    fun setSpeakerEnabled(enabled: Boolean): Boolean {
        return try {
            val route = if (enabled) {
                CallAudioState.ROUTE_SPEAKER
            } else {
                CallAudioState.ROUTE_EARPIECE
            }
            setAudioRoute(route)
            true
        } catch (e: Exception) {
            Log.e(TAG, "setAudioRoute error: ${e.message}")
            false
        }
    }

    private fun resolveNameAsync(phone: String) {
        if (phone.isBlank()) return
        Thread {
            when (val result = CallerIdLookup.lookup(applicationContext, phone)) {
                is CallerIdLookupResult.Hit -> {
                    Log.i(TAG, "in-call HIT ${result.match.displayName}")
                    CallController.updateIdentity(result.match.displayName, result.match.phone)
                }
                is CallerIdLookupResult.Miss -> {
                    Log.i(TAG, "in-call MISS $phone")
                }
                is CallerIdLookupResult.Error -> {
                    Log.w(TAG, "in-call lookup ERROR")
                }
            }
        }.start()
    }

    private fun openIncoming() {
        val intent = Intent(this, IncomingCallActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
            putExtra(IncomingCallActivity.EXTRA_PHONE, CallController.displayPhone)
        }
        startActivity(intent)
    }

    private fun openInCall() {
        val intent = Intent(this, InCallActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
        }
        startActivity(intent)
    }

    private fun extractNumber(call: Call): String? {
        val handle = call.details?.handle ?: return null
        if (handle.scheme != PhoneAccount.SCHEME_TEL && handle.scheme != "tel") return null
        return handle.schemeSpecificPart
    }

    companion object {
        private const val TAG = "BarqodyCallerId"

        @Volatile
        var instance: BarqodyInCallService? = null
            private set
    }
}
