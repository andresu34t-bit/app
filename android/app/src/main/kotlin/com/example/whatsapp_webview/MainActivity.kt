package com.example.whatsapp_webview

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.webkit.WebView
import android.os.Build

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Habilitar debugging del WebView en builds de debug
        if (BuildConfig.DEBUG) {
            WebView.setWebContentsDebuggingEnabled(true)
        }

        // En Android 9+ asegurar que WebView usa el renderizador multiprocess
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            WebView.setDataDirectorySuffix("wa_client")
        }
    }
}
