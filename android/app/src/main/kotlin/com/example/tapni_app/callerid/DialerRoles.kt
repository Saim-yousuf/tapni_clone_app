package com.example.tapni_app.callerid

import android.content.Context
import android.os.Build
import android.telecom.TelecomManager

object DialerRoles {
    fun isDefaultDialer(context: Context): Boolean {
        val tm = context.getSystemService(TelecomManager::class.java) ?: return false
        return tm.defaultDialerPackage == context.packageName
    }

    fun canUseOwnCallUi(context: Context): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && isDefaultDialer(context)
    }
}
