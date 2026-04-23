import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _supported = false;

  static bool get _isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!_isPlatformSupported) {
      _supported = false;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _plugin.initialize(settings);

      // записываем в переменную без дженерика в одной строке — чтобы парсер не споткнулся
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // в старых версиях пакета метод назывался requestPermission(),
        // в новых — requestNotificationsPermission(). Пробуем оба через try.
        try {
          await androidImpl.requestNotificationsPermission();
        } catch (_) {
          // fallback для старой версии пакета
          try {
            await (androidImpl as dynamic).requestPermission();
          } catch (_) {}
        }
      }

      _supported = true;
    } catch (_) {
      _supported = false;
    }
  }

  static Future<void> showNewGymNotification({
    required String gymName,
    required String gymType,
  }) async {
    await init();
    if (!_supported) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'new_gyms_channel',
        'Новые залы',
        channelDescription: 'Уведомления о новых залах в каталоге',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '🔥 Новый зал в каталоге!',
        '$gymName ($gymType) — загляни посмотреть',
        details,
      );
    } catch (_) {
      // игнорируем любые ошибки уведомлений
    }
  }
}