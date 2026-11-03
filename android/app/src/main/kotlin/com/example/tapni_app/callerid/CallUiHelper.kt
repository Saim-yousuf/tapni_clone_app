package com.example.tapni_app.callerid

import android.app.Activity
import android.app.KeyguardManager
import android.os.Build
import android.view.View
import android.view.WindowManager

object CallUiHelper {
    @Suppress("DEPRECATION")
    fun prepareCallWindow(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            activity.setShowWhenLocked(true)
            activity.setTurnScreenOn(true)
            val keyguard = activity.getSystemService(KeyguardManager::class.java)
            keyguard?.requestDismissKeyguard(activity, null)
        }

        activity.window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON,
        )

        // Ensure the call UI can receive taps while screen was locked.
        val decor = activity.window.decorView
        decor.isFocusable = true
        decor.isFocusableInTouchMode = true
        decor.requestFocus()
    }

    fun wireButton(view: View, onClick: () -> Unit) {
        view.isClickable = true
        view.isFocusable = true
        view.isEnabled = true
        view.setOnClickListener {
            try {
                onClick()
            } catch (e: Exception) {
                android.util.Log.e("BarqodyCallerId", "button click error: ${e.message}", e)
            }
        }
    }
}
