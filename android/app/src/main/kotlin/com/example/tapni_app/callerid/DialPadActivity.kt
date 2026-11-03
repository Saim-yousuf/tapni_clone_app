package com.example.tapni_app.callerid

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.telecom.TelecomManager
import android.view.Gravity
import android.widget.EditText
import android.widget.GridLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.tapni_app.R

/**
 * Minimal dialer required for ROLE_DIALER (ACTION_DIAL / tel:).
 */
class DialPadActivity : Activity() {
    private lateinit var input: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_dial_pad)
        input = findViewById(R.id.dial_input)

        val seed = intent?.data?.schemeSpecificPart
            ?: intent?.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
            ?: ""
        if (seed.isNotBlank()) input.setText(seed)

        val pad = findViewById<GridLayout>(R.id.dial_pad)
        listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#").forEach { key ->
            val btn = TextView(this).apply {
                text = key
                textSize = 24f
                gravity = Gravity.CENTER
                setPadding(0, 28, 0, 28)
                setTextColor(0xFF111B21.toInt())
                setOnClickListener { input.append(key) }
                layoutParams = GridLayout.LayoutParams().apply {
                    width = 0
                    height = GridLayout.LayoutParams.WRAP_CONTENT
                    columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                }
            }
            pad.addView(btn)
        }

        findViewById<TextView>(R.id.btn_call).setOnClickListener { placeCall() }
    }

    private fun placeCall() {
        val number = input.text?.toString()?.trim().orEmpty()
        if (number.isBlank()) {
            Toast.makeText(this, "Enter a number", Toast.LENGTH_SHORT).show()
            return
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), 44)
            return
        }
        val uri = Uri.fromParts("tel", number, null)
        val tm = getSystemService(TelecomManager::class.java)
        try {
            tm?.placeCall(uri, null)
        } catch (_: SecurityException) {
            startActivity(Intent(Intent.ACTION_CALL, uri))
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 44 && grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            placeCall()
        }
    }
}
