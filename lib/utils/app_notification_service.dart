import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'productivity_manager_channel';
  static const String _channelName = 'Productivity Manager';
  static const String _channelDescription =
      'Thông báo task, bình luận, deadline và duyệt yêu cầu';

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  static Future<void> init() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  static Future<bool> requestPermission() async {
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidGranted ?? iosGranted ?? true;
  }

  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
      payload: payload,
    );
  }

  static Future<void> showNotificationEnabledTest() async {
    await showNotification(
      id: 1001,
      title: 'Thông báo đã bật',
      body: 'Bạn sẽ nhận thông báo khi có task, bình luận hoặc deadline mới.',
      payload: 'notification_enabled',
    );
  }

  static Future<void> showTaskAssigned({
    required String taskTitle,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Bạn được giao task mới',
      body: 'Task "$taskTitle" đã được giao cho bạn.',
      payload: 'task_assigned',
    );
  }

  static Future<void> showDeadlineReminder({
    required String taskTitle,
    required String dueDate,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Deadline sắp đến',
      body: 'Task "$taskTitle" sắp đến hạn vào $dueDate.',
      payload: 'deadline_reminder',
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}