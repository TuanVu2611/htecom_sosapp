package com.example.hcmu_sos

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hcmu_sos/google_maps")
            .setMethodCallHandler { call, result ->
                if (call.method != "getApiKey") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val appInfo = packageManager.getApplicationInfo(
                    packageName,
                    PackageManager.GET_META_DATA,
                )
                result.success(
                    appInfo.metaData?.getString("com.google.android.geo.API_KEY") ?: "",
                )
            }
    }
}
