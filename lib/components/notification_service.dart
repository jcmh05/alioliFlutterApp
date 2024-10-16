import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';

class NotificationService {
  final Log = logger(NotificationService);

  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  IOSFlutterLocalNotificationsPlugin iosLocalNotificationsPlugin = IOSFlutterLocalNotificationsPlugin();


  Future<void> init() async {
    Log.i('Iniciando NotificationService');
    final AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/notification_icon');
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
        onDidReceiveLocalNotification: (id, title, body, payload) => selectNotification(payload)
    );

    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: null,
        macOS: null);

    // Inicialización para Android.
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          selectNotification(response.payload);
        }
    );

    // Inicialización para iOS.
    // await iosLocalNotificationsPlugin.initialize(initializationSettingsIOS,
    //     onDidReceiveNotificationResponse: (NotificationResponse response) {
    //       selectNotification(response.payload);
    //     }
    // );
  }

  AndroidNotificationDetails get _androidNotificationDetails => AndroidNotificationDetails(
      'channelID', 'channelName', importance: Importance.max, priority: Priority.high, playSound: true);

  // DarwinNotificationDetails get _iosNotificationDetails => DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true);

  NotificationDetails get _notificationDetails => NotificationDetails(
      android: _androidNotificationDetails,
      //iOS: _iosNotificationDetails
  );

  Future<void> showNotification(String title, String body) async {
    await flutterLocalNotificationsPlugin.show(0, title, body, _notificationDetails);
  }

  Future<void> cancelNotifications(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future selectNotification(String? payload) async {
    //
  }
}
