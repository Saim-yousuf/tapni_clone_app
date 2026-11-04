package com.example.tapni_app

import android.Manifest
import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.telephony.TelephonyManager
import android.telecom.TelecomManager
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import com.example.tapni_app.callerid.CallerIdStore
import com.example.tapni_app.callerid.DialerRoles
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** FlutterFragmentActivity required by flutter_stripe PaymentSheet. */
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "barqody/caller_id"
    private val deviceCountryChannel = "barqody/device_country"

    // RoleManager.createRequestRoleIntent MUST be launched for-result or the
    // system chooser often does nothing (plain startActivity is a no-op).
    private val callScreeningRoleLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
            // Flutter CallerIdSetupScreen refreshes on AppLifecycleState.resumed.
        }

    private val defaultDialerRoleLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
            // Flutter refreshes on resume.
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceCountryChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCountryIso" -> result.success(resolveDeviceCountryIso())
                    else -> result.notImplemented()
                }
            }
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
                        result.success(requestCallScreeningRole())
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(PowerManager::class.java)
                            result.success(
                                pm?.isIgnoringBatteryOptimizations(packageName) == true,
                            )
                        } else {
                            result.success(true)
                        }
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            try {
                                startActivity(
                                    Intent(
                                        Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                        "package:$packageName".toUri(),
                                    ),
                                )
                            } catch (_: Exception) {
                                startActivity(
                                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                                )
                            }
                        }
                        result.success(true)
                    }
                    "isDefaultDialer" -> {
                        result.success(DialerRoles.isDefaultDialer(this))
                    }
                    "requestDefaultDialerRole" -> {
                        result.success(requestDefaultDialerRole())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * SIM country first (most accurate for phone OTP), then network MCC country.
     * Emulators almost always fake "us" — skip so Flutter uses product fallback.
     * No runtime permission required for these TelephonyManager getters.
     */
    private fun resolveDeviceCountryIso(): String? {
        if (isProbablyEmulator()) return null
        return try {
            val tm = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
                ?: return null
            val sim = tm.simCountryIso?.trim().orEmpty()
            if (sim.length == 2) return sim.uppercase()
            val network = tm.networkCountryIso?.trim().orEmpty()
            if (network.length == 2) return network.uppercase()
            null
        } catch (_: Exception) {
            null
        }
    }

    private fun isProbablyEmulator(): Boolean {
        val fp = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val product = Build.PRODUCT.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        return fp.contains("generic") ||
            fp.contains("emulator") ||
            fp.contains("unknown") ||
            model.contains("google_sdk") ||
            model.contains("emulator") ||
            model.contains("android sdk built for") ||
            product.contains("sdk") ||
            product.contains("emulator") ||
            product.contains("google_sdk") ||
            manufacturer.contains("genymotion")
    }

    private fun requestDefaultDialerRole(): Map<String, Any?> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = getSystemService(RoleManager::class.java)
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_DIALER)) {
                    if (roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                        return mapOf("opened" to false, "held" to true, "reason" to "already_held")
                    }
                    defaultDialerRoleLauncher.launch(
                        roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER),
                    )
                    return mapOf("opened" to true, "held" to false, "reason" to "role_intent")
                }
            }
            // Pre-Q / fallback: legacy change-default-dialer intent.
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            }
            startActivity(intent)
            mapOf("opened" to true, "held" to false, "reason" to "legacy_intent")
        } catch (e: Exception) {
            mapOf("opened" to false, "held" to false, "reason" to (e.message ?: "unavailable"))
        }
    }

    /**
     * @return map with opened/held/reason so Flutter can show feedback.
     */
    private fun requestCallScreeningRole(): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return mapOf("opened" to false, "held" to true, "reason" to "pre_q")
        }

        val roleManager = getSystemService(RoleManager::class.java)
            ?: return mapOf("opened" to false, "held" to false, "reason" to "no_role_manager")

        if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
            return mapOf("opened" to false, "held" to true, "reason" to "already_held")
        }

        if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
            return try {
                val intent =
                    roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                callScreeningRoleLauncher.launch(intent)
                mapOf("opened" to true, "held" to false, "reason" to "role_intent")
            } catch (e: Exception) {
                openDefaultAppsFallback(e.message)
            }
        }

        return openDefaultAppsFallback("role_unavailable")
    }

    private fun openDefaultAppsFallback(reason: String?): Map<String, Any?> {
        return try {
            startActivity(Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS))
            mapOf(
                "opened" to true,
                "held" to false,
                "reason" to (reason ?: "fallback_settings"),
            )
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
                mapOf("opened" to true, "held" to false, "reason" to "fallback_settings_root")
            } catch (e: Exception) {
                mapOf(
                    "opened" to false,
                    "held" to false,
                    "reason" to (e.message ?: "unavailable"),
                )
            }
        }
    }
}
