package com.svayp.app

import android.content.Intent
import android.os.Bundle
import androidx.core.content.FileProvider
import androidx.core.view.WindowCompat
import com.google.firebase.installations.FirebaseInstallations
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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

        // Targeted sharing: the system sharesheet lists every handler on the
        // device, but the product wants a short row of social apps (Instagram,
        // Threads, TikTok, Telegram) shown ONLY when installed. That requires
        // native calls: package-visibility checks + ACTION_SEND with setPackage.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "svayp/targeted_share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalled" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        val installed = packages.filter { pkg ->
                            runCatching { packageManager.getPackageInfo(pkg, 0) }.isSuccess
                        }
                        result.success(installed)
                    }
                    "shareTo" -> {
                        val pkg = call.argument<String>("package")
                        val path = call.argument<String>("path")
                        val mimeType = call.argument<String>("mimeType") ?: "image/*"
                        if (pkg == null || path == null) {
                            result.error("BAD_ARGS", "package and path are required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = FileProvider.getUriForFile(
                                this, "$packageName.share.fileprovider", File(path)
                            )
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = mimeType
                                putExtra(Intent.EXTRA_STREAM, uri)
                                setPackage(pkg)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SHARE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
