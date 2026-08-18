package com.example.tapni_app.callerid

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import com.example.tapni_app.R

object CallerIdOverlay {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null
    private var currentPhone: String? = null

    fun showIncoming(context: Context, rawPhone: String) {
        if (!CallerIdStore.isEnabled(context)) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) return

        val appContext = context.applicationContext
        val phone = CallerIdLookup.normalizePhone(rawPhone) ?: return
        val cached = CallerIdCache.get(appContext, phone)
        if (cached != null) {
            runOnMain { attach(appContext, cached) }
        }

        Thread {
            when (val result = CallerIdLookup.lookup(appContext, rawPhone)) {
                is CallerIdLookupResult.Hit -> {
                    CallerIdCache.put(appContext, result.match)
                    runOnMain { attach(appContext, result.match) }
                }
                is CallerIdLookupResult.Miss -> {
                    CallerIdCache.remove(appContext, result.phone)
                }
                is CallerIdLookupResult.Error -> {
                    // Keep showing the cached name if the network failed.
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
        } catch (_: Exception) {
        }
        overlayView = null
        currentPhone = null
    }

    private fun attach(context: Context, match: CallerIdMatch) {
        if (overlayView != null && currentPhone == match.phone) {
            bind(overlayView!!, context, match)
            return
        }
        detach(context)
        val inflater = LayoutInflater.from(context)
        val view = inflater.inflate(R.layout.overlay_caller_id, null)
        bind(view, context, match)
        view.findViewById<View>(R.id.caller_id_close).setOnClickListener { hide(context) }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            PixelFormat.TRANSLUCENT,
        )
        params.gravity = Gravity.TOP
        params.y = 48

        try {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.addView(view, params)
            overlayView = view
            currentPhone = match.phone
        } catch (_: Exception) {
            overlayView = null
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
        view.findViewById<TextView>(R.id.caller_id_meta).text = parts.joinToString("  ·  ")
    }
}
