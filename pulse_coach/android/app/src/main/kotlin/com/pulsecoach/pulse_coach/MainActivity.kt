package com.pulsecoach.pulse_coach

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not plain FlutterActivity) because the `health`
// plugin casts the host activity to androidx.activity.ComponentActivity for
// its ActivityResultLauncher-based permission flow — a plain FlutterActivity
// isn't a ComponentActivity and the cast throws ClassCastException.
class MainActivity : FlutterFragmentActivity() {
    private val healthSettingsChannel = "com.pulsecoach.pulse_coach/health_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, healthSettingsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "openHealthConnectSettings") {
                    openHealthConnectSettings()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    // Deep-links straight to this app's permission row inside Health Connect
    // (Android 14+: MANAGE_HEALTH_PERMISSIONS + EXTRA_PACKAGE_NAME). Falls back
    // to Health Connect's home settings screen when that specific action isn't
    // resolvable (ActivityNotFoundException) OR is guarded by a system-only
    // permission on this device's Health Connect controller build
    // (SecurityException — observed on a Samsung Android 16 device).
    private fun openHealthConnectSettings() {
        try {
            startActivity(
                Intent("android.health.connect.action.MANAGE_HEALTH_PERMISSIONS").apply {
                    putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
                }
            )
        } catch (_: Exception) {
            try {
                startActivity(Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"))
            } catch (_: Exception) {
                // Health Connect isn't installed / resolvable at all — nothing more we can do.
            }
        }
    }
}
