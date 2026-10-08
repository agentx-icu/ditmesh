package icu.agentx.ditmesh

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var networkPath: NetworkPathChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        networkPath?.dispose()
        networkPath = NetworkPathChannel(applicationContext).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        networkPath?.dispose()
        networkPath = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
