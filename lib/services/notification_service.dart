import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones locales.
/// Recibe mensajes desde el bridge de JavaScript y los muestra
/// como notificaciones nativas del sistema operativo.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static int _notificationId = 0;

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        debugPrint('iOS notification received: $title');
      },
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Crear canal de notificaciones en Android
    const androidChannel = AndroidNotificationChannel(
      'wa_messages',
      'Mensajes de WhatsApp',
      description: 'Notificaciones de mensajes recibidos',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    // Limpiar caracteres problemáticos del cuerpo
    final cleanBody = body.length > 100 ? '${body.substring(0, 97)}...' : body;

    const androidDetails = AndroidNotificationDetails(
      'wa_messages',
      'Mensajes de WhatsApp',
      channelDescription: 'Notificaciones de mensajes recibidos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF25D366),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
      ticker: 'Nuevo mensaje',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      _notificationId++,
      title,
      cleanBody,
      details,
    );
  }
}
