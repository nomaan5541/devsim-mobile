import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Default to the mipmap launcher icon
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
      );
    } catch (_) {
      // Catch initialization errors gracefully on emulator systems or platforms without plugins
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'devsim_offline_channel',
      'Simulation Alerts',
      channelDescription: 'Alerts for DevSim session tracking and token expiry',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (_) {
      // Gracefully prevent crashes if notification permissions are denied
    }
  }

  Future<void> showProgressNotification({required String title, required String body}) async {
    await showNotification(id: 1, title: title, body: body);
  }

  Future<void> showExpiryWarning({required int daysLeft}) async {
    String body = daysLeft <= 0
        ? "Your GitHub personal access token has expired! Connect a new one to continue."
        : "Your GitHub personal access token expires in $daysLeft day(s). Make sure to renew it.";
    await showNotification(id: 2, title: "GitHub Token Expiration Warning", body: body);
  }
}
