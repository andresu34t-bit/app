import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación portrait y landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Inicializar notificaciones locales
  await NotificationService.initialize();

  // Solicitar permisos al arrancar
  await _requestPermissions();

  runApp(const WhatsAppWebViewApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.microphone,
    Permission.notification,
    Permission.storage,
    Permission.photos,
  ].request();
}

class WhatsAppWebViewApp extends StatelessWidget {
  const WhatsAppWebViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WA Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF25D366), // Verde WhatsApp
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF25D366),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
