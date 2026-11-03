package com.example.tapni_app.callerid

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import com.example.tapni_app.R

/**
 * Truecaller-style caller card: WindowManager TYPE_APPLICATION_OVERLAY only.
 * Draw-over-apps + call-screening role required for reliable dialer coverage.
 */
object CallerIdOverlay {
    private const val TAG = "BarqodyCallerId"
    private val mainHandler = Handler(Looper.getMainLooper())

    private var overlayView: View? = null
    private var windowParams: WindowManager.LayoutParams? = null
    private var currentPhone: String? = null

    fun showIncoming(context: Context, rawPhone: String) {
        if (!CallerIdStore.isEnabled(context)) {
            Log.w(TAG, "showIncoming skipped: disabled")
            return
        }
        if (DialerRoles.canUseOwnCallUi(context)) {
            Log.i(TAG, "showIncoming skipped: default dialer owns call UI")
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            Log.w(TAG, "showIncoming skipped: no overlay permission")
            return
        }

        val appContext = context.applicationContext
        val phone = CallerIdLookup.normalizePhone(rawPhone)
        if (phone == null) {
            Log.w(TAG, "showIncoming skipped: bad phone raw=$rawPhone")
            return
        }
        Log.i(
            TAG,
            "showIncoming raw=$rawPhone normalized=$phone baseUrl=${CallerIdStore.baseUrl(appContext)} tokenLen=${CallerIdStore.token(appContext).length}",
        )

        val cached = CallerIdCache.get(appContext, phone)
        if (cached != null) {
            runOnMain { attach(appContext, cached) }
        }

        Thread {
            when (val result = CallerIdLookup.lookup(appContext, rawPhone)) {
                is CallerIdLookupResult.Hit -> {
                    Log.i(TAG, "lookup HIT name=${result.match.displayName} source=${result.match.source}")
                    CallerIdCache.put(appContext, result.match)
                    runOnMain { attach(appContext, result.match) }
                }
                is CallerIdLookupResult.Miss -> {
                    Log.i(TAG, "lookup MISS phone=${result.phone}")
                    CallerIdCache.remove(appContext, result.phone)
                }
                is CallerIdLookupResult.Error -> {
                    Log.w(TAG, "lookup ERROR (network/token/baseUrl)")
                }
            }
        }.start()
    }

    fun hide(context: Context) {
        val appContext = context.applicationContext
        runOnMain { detach(appContext) }
    }

    private fun runOnMain(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action()
        } else {
            mainHandler.post(action)
        }
    }

    private fun detach(context: Context) {
        val view = overlayView ?: return
        try {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.removeView(view)
            Log.i(TAG, "overlay removed")
        } catch (_: Exception) {
        }
        overlayView = null
        windowParams = null
        currentPhone = null
    }

    private fun attach(context: Context, match: CallerIdMatch) {
        if (overlayView != null && currentPhone == match.phone) {
            bind(overlayView!!, context, match)
            return
        }
        detach(context)

        val view = LayoutInflater.from(context).inflate(R.layout.overlay_caller_id, null)
        bind(view, context, match)
        view.findViewById<View>(R.id.caller_id_close).setOnClickListener { hide(context) }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }

        // NOT_FOCUSABLE: Answer/Reject on dialer keep working (Truecaller pattern).
        // NOT_TOUCH_MODAL: touches outside the card pass through to the phone UI.
        val flags =
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            flags,
            PixelFormat.TRANSLUCENT,
        )
        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.x = 0
        params.y = dp(context, 40)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        try {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.addView(view, params)
            overlayView = view
            windowParams = params
            currentPhone = match.phone
            Log.i(TAG, "overlay attached name=${match.displayName}")
        } catch (e: Exception) {
            Log.w(TAG, "overlay attach failed: ${e.message}")
            overlayView = null
            windowParams = null
            currentPhone = null
        }
    }

    private fun bind(view: View, context: Context, match: CallerIdMatch) {
        view.findViewById<TextView>(R.id.caller_id_name).text = match.displayName
        val parts = mutableListOf<String>()
        parts.add(match.phone)
        if (match.isSelfVerified) {
            parts.add(CallerIdStore.verifiedLabel(context))
        }
        if (match.company.isNotBlank()) parts.add(match.company)
        if (match.source == "crowd" && match.matchCount > 0) {
            parts.add("${match.matchCount} matches")
        }
        view.findViewById<TextView>(R.id.caller_id_meta).text = parts.joinToString("  ·  ")
        view.findViewById<TextView>(R.id.caller_id_brand).text = "Barqody Caller ID"
    }

    private fun dp(context: Context, value: Int): Int {
        return (value * context.resources.displayMetrics.density).toInt()
    }
}
