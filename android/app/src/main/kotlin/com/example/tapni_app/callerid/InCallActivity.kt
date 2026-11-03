package com.example.tapni_app.callerid

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.telecom.Call
import android.util.Log
import android.view.Gravity
import android.view.View
import android.widget.GridLayout
import android.widget.TextView
import android.widget.Toast
import com.example.tapni_app.R

class InCallActivity : Activity(), CallController.Listener {
    private var muted = false
    private var speakerOn = false
    private var onHold = false
    private var callStartedAt = 0L
    private val timerHandler = Handler(Looper.getMainLooper())
    private val timerTick = object : Runnable {
        override fun run() {
            updateTimer()
            timerHandler.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CallUiHelper.prepareCallWindow(this)
        setContentView(R.layout.activity_in_call)

        bindUi()
        setupControls()
        setupKeypad()
        CallController.addListener(this)
        startTimerIfNeeded()
    }

    override fun onResume() {
        super.onResume()
        CallUiHelper.prepareCallWindow(this)
    }

    override fun onDestroy() {
        timerHandler.removeCallbacks(timerTick)
        if (muted) {
            BarqodyInCallService.instance?.setCallMuted(false)
        }
        CallController.removeListener(this)
        super.onDestroy()
    }

    override fun onCallChanged(call: Call?) {
        if (call == null) finish() else {
            bindUi()
            startTimerIfNeeded()
        }
    }

    override fun onStateChanged(state: Int) {
        if (state == Call.STATE_DISCONNECTED) {
            finish()
            return
        }
        if (state == Call.STATE_ACTIVE || state == Call.STATE_HOLDING) {
            startTimerIfNeeded()
        }
        onHold = state == Call.STATE_HOLDING
        refreshToggleStyles()
        bindUi(state)
    }

    private fun setupControls() {
        CallUiHelper.wireButton(findViewById(R.id.btn_end)) {
            Log.i(TAG, "End tapped call=${CallController.currentCall?.state}")
            if (!CallController.disconnect()) {
                toast("Could not end call")
            }
            finish()
        }
        CallUiHelper.wireButton(findViewById(R.id.btn_mute)) {
            val next = !muted
            val ok = BarqodyInCallService.instance?.setCallMuted(next) == true
            if (!ok) {
                toast("Mute not available")
                return@wireButton
            }
            muted = next
            refreshToggleStyles()
        }
        CallUiHelper.wireButton(findViewById(R.id.btn_speaker)) {
            val next = !speakerOn
            val ok = BarqodyInCallService.instance?.setSpeakerEnabled(next) == true
            if (!ok) {
                toast("Speaker not available")
                return@wireButton
            }
            speakerOn = next
            refreshToggleStyles()
        }
        CallUiHelper.wireButton(findViewById(R.id.btn_hold)) {
            val next = !onHold
            if (!CallController.hold(next)) {
                toast("Hold not available")
                return@wireButton
            }
            onHold = next
            refreshToggleStyles()
        }
        CallUiHelper.wireButton(findViewById(R.id.btn_keypad)) {
            findViewById<View>(R.id.keypad_panel).visibility = View.VISIBLE
        }
        CallUiHelper.wireButton(findViewById(R.id.btn_keypad_hide)) {
            findViewById<View>(R.id.keypad_panel).visibility = View.GONE
        }
        refreshToggleStyles()
    }

    private fun setupKeypad() {
        val grid = findViewById<GridLayout>(R.id.keypad_grid)
        val display = findViewById<TextView>(R.id.keypad_display)
        listOf('1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#').forEach { key ->
            val btn = TextView(this).apply {
                text = key.toString()
                textSize = 24f
                gravity = Gravity.CENTER
                setTextColor(0xFFFFFFFF.toInt())
                setBackgroundResource(R.drawable.call_keypad_key)
                isClickable = true
                isFocusable = true
                layoutParams = GridLayout.LayoutParams().apply {
                    width = 0
                    height = dp(64)
                    columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                    setMargins(dp(8), dp(8), dp(8), dp(8))
                }
                setOnClickListener {
                    display.append(key.toString())
                    val call = CallController.currentCall ?: return@setOnClickListener
                    try {
                        call.playDtmfTone(key)
                        Handler(Looper.getMainLooper()).postDelayed({
                            try {
                                call.stopDtmfTone()
                            } catch (_: Exception) {
                            }
                        }, 160)
                    } catch (_: Exception) {
                    }
                }
            }
            grid.addView(btn)
        }
    }

    private fun refreshToggleStyles() {
        styleToggle(R.id.btn_mute, R.id.label_mute, muted, if (muted) "Unmute" else "Mute")
        styleToggle(R.id.btn_speaker, R.id.label_speaker, speakerOn, "Speaker")
        styleToggle(R.id.btn_hold, R.id.label_hold, onHold, if (onHold) "Resume" else "Hold")
    }

    private fun styleToggle(btnId: Int, labelId: Int, on: Boolean, label: String) {
        val btn = findViewById<TextView>(btnId)
        val labelView = findViewById<TextView>(labelId)
        btn.setBackgroundResource(if (on) R.drawable.call_circle_dark_on else R.drawable.call_circle_dark)
        btn.setTextColor(if (on) 0xFF111B21.toInt() else 0xFFFFFFFF.toInt())
        labelView.text = label
    }

    private fun startTimerIfNeeded() {
        val state = CallController.currentCall?.state ?: return
        if (state != Call.STATE_ACTIVE && state != Call.STATE_HOLDING) return
        if (callStartedAt == 0L) {
            callStartedAt = SystemClock.elapsedRealtime()
            timerHandler.removeCallbacks(timerTick)
            timerHandler.post(timerTick)
        }
    }

    private fun updateTimer() {
        if (callStartedAt == 0L) return
        val elapsed = (SystemClock.elapsedRealtime() - callStartedAt) / 1000
        val mm = elapsed / 60
        val ss = elapsed % 60
        findViewById<TextView>(R.id.incall_timer).text = "%02d:%02d".format(mm, ss)
    }

    private fun bindUi(state: Int = CallController.currentCall?.state ?: Call.STATE_ACTIVE) {
        val phone = CallController.displayPhone
        val name = when {
            CallController.isIdentified -> CallController.displayName
            phone.isNotBlank() -> phone
            else -> "Unknown Number"
        }
        findViewById<TextView>(R.id.incall_name).text = name
        findViewById<TextView>(R.id.incall_phone).text =
            if (CallController.isIdentified && phone.isNotBlank()) phone else ""
        findViewById<TextView>(R.id.incall_avatar).text =
            name.trim().firstOrNull { it.isLetterOrDigit() }?.uppercaseChar()?.toString() ?: "?"
        findViewById<TextView>(R.id.incall_status).text = when (state) {
            Call.STATE_DIALING, Call.STATE_CONNECTING -> "Calling…"
            Call.STATE_HOLDING -> "On hold"
            Call.STATE_RINGING -> "Ringing…"
            else -> "Connected"
        }
    }

    private fun toast(msg: String) {
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    companion object {
        private const val TAG = "BarqodyCallerId"
    }
}
