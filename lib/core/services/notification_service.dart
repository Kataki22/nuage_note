import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

enum ReminderScheduleResult {
  scheduledExact,
  scheduledInexact,
  notificationDenied,
  failed,
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'note_reminders';
  static const String _channelName = 'Rappels de notes';
  static const String _channelDescription =
      'Notifications pour les rappels associés à vos notes';

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Fallback: garde UTC si la lookup échoue
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<bool> _ensureNotificationPermission() async {
    final android = _android;
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      if (enabled == true) return true;
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<bool> _ensureExactAlarmPermission() async {
    final android = _android;
    if (android == null) return true;
    try {
      final granted = await android.requestExactAlarmsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// À appeler quand l'utilisateur active un rappel.
  Future<bool> requestPermissions() async {
    await init();
    final notif = await _ensureNotificationPermission();
    if (!notif) return false;
    await _ensureExactAlarmPermission();
    return true;
  }

  int _idForNote(String noteId) =>
      noteId.hashCode & 0x7fffffff; // positive 31-bit int

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF7C5CBF),
      enableVibration: true,
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<ReminderScheduleResult> schedule({
    required String noteId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      return ReminderScheduleResult.failed;
    }

    final notifAllowed = await _ensureNotificationPermission();
    if (!notifAllowed) return ReminderScheduleResult.notificationDenied;

    final exactAllowed = await _ensureExactAlarmPermission();

    final mode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    Future<void> doSchedule(AndroidScheduleMode m) {
      return _plugin.zonedSchedule(
        _idForNote(noteId),
        title.isEmpty ? 'Rappel de note' : title,
        body.isEmpty ? 'Vous avez un rappel programmé.' : body,
        scheduled,
        _details,
        androidScheduleMode: m,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: noteId,
      );
    }

    try {
      await doSchedule(mode);
      return mode == AndroidScheduleMode.exactAllowWhileIdle
          ? ReminderScheduleResult.scheduledExact
          : ReminderScheduleResult.scheduledInexact;
    } catch (_) {
      try {
        await doSchedule(AndroidScheduleMode.inexactAllowWhileIdle);
        return ReminderScheduleResult.scheduledInexact;
      } catch (_) {
        return ReminderScheduleResult.failed;
      }
    }
  }

  Future<void> cancel(String noteId) async {
    await init();
    await _plugin.cancel(_idForNote(noteId));
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Affiche immédiatement une notification de test.
  Future<bool> showTestNow() async {
    await init();
    final allowed = await _ensureNotificationPermission();
    if (!allowed) return false;
    await _plugin.show(
      999999,
      'Test de notification',
      'Si tu vois ce message, les notifications fonctionnent ✓',
      _details,
    );
    return true;
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }
}
