package com.example.tapni_app.callerid

import android.os.Build
import android.telecom.Call
import android.telecom.VideoProfile
import android.util.Log
import java.util.concurrent.CopyOnWriteArraySet

/**
 * Holds the active Telecom [Call] so incoming / in-call activities can control it.
 *
 * Identity is provisional first (number / "Unknown Number"), then upgraded when
 * directory lookup finishes — never block ringing on network.
 */
object CallController {
    interface Listener {
        fun onCallChanged(call: Call?)
        fun onStateChanged(state: Int)
    }

    private const val TAG = "BarqodyCallerId"

    @Volatile
    var currentCall: Call? = null
        private set

    /** Live title shown on call UI (number first, then resolved name). */
    @Volatile
    var displayName: String = ""
        private set

    @Volatile
    var displayPhone: String = ""
        private set

    /** True only after a successful directory hit. */
    @Volatile
    var isIdentified: Boolean = false
        private set

    private val listeners = CopyOnWriteArraySet<Listener>()

    private val callback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            Log.i(TAG, "CallController state=$state")
            listeners.forEach { it.onStateChanged(state) }
            if (state == Call.STATE_DISCONNECTED) {
                clear(call)
            }
        }
    }

    fun addListener(listener: Listener) = listeners.add(listener)

    fun removeListener(listener: Listener) = listeners.remove(listener)

    fun setCall(call: Call, phone: String) {
        currentCall?.unregisterCallback(callback)
        currentCall = call
        displayPhone = phone
        displayName = phone.ifBlank { "Unknown Number" }
        isIdentified = false
        call.registerCallback(callback)
        Log.i(TAG, "CallController.setCall phone=$phone state=${call.state}")
        listeners.forEach { it.onCallChanged(call) }
        listeners.forEach { it.onStateChanged(call.state) }
    }

    fun updateIdentity(name: String, phone: String) {
        if (phone.isNotBlank()) displayPhone = phone
        val resolved = name.trim()
        if (resolved.isNotEmpty()) {
            displayName = resolved
            isIdentified = true
        }
        listeners.forEach { it.onCallChanged(currentCall) }
    }

    fun answer(): Boolean {
        val call = currentCall
        if (call == null) {
            Log.w(TAG, "answer failed: no active call")
            return false
        }
        return try {
            Log.i(TAG, "answer() state=${call.state}")
            call.answer(VideoProfile.STATE_AUDIO_ONLY)
            true
        } catch (e: Exception) {
            Log.e(TAG, "answer error: ${e.message}")
            false
        }
    }

    fun reject(): Boolean {
        val call = currentCall
        if (call == null) {
            Log.w(TAG, "reject failed: no active call")
            return false
        }
        return try {
            Log.i(TAG, "reject() state=${call.state}")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                call.reject(Call.RejectReason.DECLINED)
            } else {
                @Suppress("DEPRECATION")
                call.reject(false, null)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "reject error: ${e.message}")
            try {
                call.disconnect()
                true
            } catch (e2: Exception) {
                Log.e(TAG, "disconnect fallback error: ${e2.message}")
                false
            }
        }
    }

    fun disconnect(): Boolean {
        val call = currentCall
        if (call == null) {
            Log.w(TAG, "disconnect failed: no active call")
            return false
        }
        return try {
            Log.i(TAG, "disconnect() state=${call.state}")
            call.disconnect()
            true
        } catch (e: Exception) {
            Log.e(TAG, "disconnect error: ${e.message}")
            false
        }
    }

    fun hold(on: Boolean): Boolean {
        val call = currentCall
        if (call == null) {
            Log.w(TAG, "hold failed: no active call")
            return false
        }
        return try {
            if (on) call.hold() else call.unhold()
            true
        } catch (e: Exception) {
            Log.e(TAG, "hold error: ${e.message}")
            false
        }
    }

    private fun clear(call: Call) {
        if (currentCall !== call) return
        call.unregisterCallback(callback)
        currentCall = null
        displayName = ""
        displayPhone = ""
        isIdentified = false
        listeners.forEach { it.onCallChanged(null) }
    }

    fun clearIfCurrent(call: Call) {
        if (currentCall === call) {
            call.unregisterCallback(callback)
            currentCall = null
            displayName = ""
            displayPhone = ""
            isIdentified = false
            listeners.forEach { it.onCallChanged(null) }
        }
    }
}
