package com.medtracker.medtrackaiflutter

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Same channel name as the iOS AppDelegate; NativeWidgetService on the
        // Dart side talks to both.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.medtrackai.widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncSteps" -> {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.error("BAD_ARGS", "syncSteps expects a map", null)
                        } else {
                            StepsWidgetProvider.save(applicationContext, args)
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
