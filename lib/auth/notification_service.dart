import 'dart:convert';
import 'package:corehris/auth/socketnotification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _initializationFuture;

  // ✅ Cache to remember which notifications were already shown
  static final Set<int> _shownNotificationIds = {};

  static Future<void> initialize() async {
    _initializationFuture ??= _initializeInternal();
    await _initializationFuture;
  }

  static Future<void> _initializeInternal() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!);
            SocketNotificationService.handleNotificationTap(data);
          } catch (e) {
            print("⚠️ Invalid payload: $e");
          }
        }
      },
    );

    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// 🔔 Show native notification (skip duplicates)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // ✅ Prevent showing the same notification twice
    if (_shownNotificationIds.contains(id)) {
      print("⚪ Skipping duplicate notification (id: $id)");
      return;
    }

    _shownNotificationIds.add(id);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'corehris_channel',
      'CoreHRIS Notifications',
      channelDescription: 'HRIS alerts and updates',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'CoreHRIS Alert',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// 🧹 Optional: Clear cache if needed (e.g., on logout)
  static void clearShownCache() {
    _shownNotificationIds.clear();
    print("🧹 Notification cache cleared");
  }
}
