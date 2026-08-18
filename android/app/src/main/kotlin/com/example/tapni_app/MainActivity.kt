package com.example.tapni_app

import android.Manifest
import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.tapni_app.callerid.CallerIdStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "barqody/caller_id"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncConfig" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val token = call.argument<String>("token") ?: ""
                        val baseUrl = call.argument<String>("baseUrl") ?: ""
                        val lang = call.argument<String>("lang") ?: "en"
                        CallerIdStore.save(this, enabled, token, baseUrl, lang)
                        result.success(true)
                    }
                    "hasOverlayPermission" -> {
                        result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                                Settings.canDrawOverlays(this),
                        )
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName"),
                            )
                            startActivity(intent)
                        }
                        result.success(true)
                    }
                    "hasPhonePermissions" -> {
                        val phoneGranted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.READ_PHONE_STATE,
                        ) == PackageManager.PERMISSION_GRANTED
                        val logGranted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.READ_CALL_LOG,
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(phoneGranted && logGranted)
                    }
                    "requestPhonePermissions" -> {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.READ_PHONE_STATE,
                                Manifest.permission.READ_CALL_LOG,
                            ),
                            9922,
                        )
                        result.success(true)
                    }
                    "hasCallScreeningRole" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(RoleManager::class.java)
                            result.success(
                                roleManager?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true,
                            )
                        } else {
                            result.success(true)
                        }
                    }
                    "requestCallScreeningRole" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(RoleManager::class.java)
                            if (roleManager != null &&
                                roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)
                            ) {
                                startActivity(
                                    roleManager.createRequestRoleIntent(
                                        RoleManager.ROLE_CALL_SCREENING,
                                    ),
                                )
                            }
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
