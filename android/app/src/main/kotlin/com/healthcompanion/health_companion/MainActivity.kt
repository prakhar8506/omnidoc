package com.healthcompanion.health_companion

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cura/health_connect")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openPermissions" -> result.success(openHealthConnectPermissions())
                    "openPdf" -> {
                        val path = call.argument<String>("path")
                        result.success(if (path.isNullOrBlank()) false else openPdf(path))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openHealthConnectPermissions(): Boolean {
        val candidates = listOf(
            Intent("androidx.health.ACTION_MANAGE_HEALTH_PERMISSIONS").apply {
                putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
            },
            Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"),
            packageManager.getLaunchIntentForPackage("com.google.android.apps.healthdata"),
        )
        for (intent in candidates) {
            if (intent == null) continue
            try {
                startActivity(intent)
                return true
            } catch (_: Exception) {
            }
        }
        return false
    }

    private fun openPdf(path: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) return false
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val view = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(view, "Open your lab explanation"))
            true
        } catch (_: Exception) {
            false
        }
    }
}
