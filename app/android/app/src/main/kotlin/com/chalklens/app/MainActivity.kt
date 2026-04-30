package com.chalklens.app

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "chalk_lens/storage"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "availableStorageBytes" -> {
                    val stat = StatFs(filesDir.absolutePath)
                    result.success(stat.availableBytes)
                }
                else -> result.notImplemented()
            }
        }
    }
}
