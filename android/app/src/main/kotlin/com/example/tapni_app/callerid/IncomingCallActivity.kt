package com.example.tapni_app.callerid

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telecom.Call
import android.util.Log
import android.widget.TextView
import android.widget.Toast
import com.example.tapni_app.R

class IncomingCallActivity : Activity(), CallController.Listener {
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CallUiHelper.prepareCallWindow(this)
        setContentView(R.layout.activity_incoming_call)

        bindUi()
        CallUiHelper.wireButton(findViewById(R.id.btn_answer)) {
            Log.i(TAG, "Answer tapped, call=${CallController.currentCall?.state}")
            val ok = CallController.answer()
            if (!ok) {
                Toast.makeText(this, "Could not answer call", Toast.LENGTH_SHORT).show()
                return@wireButton
            }
            startActivity(
                Intent(this, InCallActivity::class.java).apply {
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
                    )
                },
            )
            finish()
        }
        CallUiHelper.wireButton(findViewById(R.id.btn_reject)) {
            Log.i(TAG, "Decline tapped, call=${CallController.currentCall?.state}")
            val ok = CallController.reject()
            if (!ok) {
                Toast.makeText(this, "Could not decline call", Toast.LENGTH_SHORT).show()
            }
            finish()
        }
        CallController.addListener(this)
    }

    override fun onResume() {
        super.onResume()
        CallUiHelper.prepareCallWindow(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        bindUi()
    }

    override fun onDestroy() {
        CallController.removeListener(this)
        super.onDestroy()
    }

    override fun onCallChanged(call: Call?) {
        if (call == null) {
            finish()
            return
        }
        mainHandler.post { bindUi() }
    }

    override fun onStateChanged(state: Int) {
        when (state) {
            Call.STATE_DISCONNECTED -> finish()
            Call.STATE_ACTIVE -> {
                startActivity(
                    Intent(this, InCallActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    },
                )
                finish()
            }
            else -> mainHandler.post { bindUi() }
        }
    }

    private fun bindUi() {
        val phone = CallController.displayPhone
            .ifBlank { intent.getStringExtra(EXTRA_PHONE).orEmpty() }
        val title = when {
            CallController.isIdentified -> CallController.displayName
            phone.isNotBlank() -> phone
            else -> "Unknown Number"
        }
        findViewById<TextView>(R.id.incoming_name).text = title
        findViewById<TextView>(R.id.incoming_phone).text =
            if (CallController.isIdentified && phone.isNotBlank()) phone else ""
        findViewById<TextView>(R.id.incoming_avatar).text =
            title.trim().firstOrNull { it.isLetterOrDigit() }?.uppercaseChar()?.toString() ?: "?"
        val meta = findViewById<TextView>(R.id.incoming_meta)
        meta.text = if (CallController.isIdentified) {
            "Identified by Barqody"
        } else {
            "Looking up caller…"
        }
        meta.visibility = android.view.View.VISIBLE
    }

    companion object {
        const val EXTRA_PHONE = "phone"
        private const val TAG = "BarqodyCallerId"
    }
}
