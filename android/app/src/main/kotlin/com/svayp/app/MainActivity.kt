package com.svayp.app

import android.os.Bundle
import androidx.core.view.WindowCompat
import com.google.firebase.installations.FirebaseInstallations
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // True edge-to-edge: app draws behind status bar AND navigation bar.
        // This is the authoritative native call — SystemChrome alone is not enough.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }

    // TODO: Remove after getting Firebase Installation ID for in-app messaging test
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "firebase_installation_id")
            .setMethodCallHandler { call, result ->
                if (call.method == "getId") {
                    FirebaseInstallations.getInstance().id
                        .addOnSuccessListener { id -> result.success(id) }
                        .addOnFailureListener { e -> result.error("ERROR", e.message, null) }
                } else {
                    result.notImplemented()
                }
            }
    }
}
