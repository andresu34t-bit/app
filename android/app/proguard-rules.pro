# Reglas ProGuard para WA Client

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WebView Flutter
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Notificaciones locales
-keep class com.dexterous.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Evitar ofuscación de clases de Activity
-keep class com.example.whatsapp_webview.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**
