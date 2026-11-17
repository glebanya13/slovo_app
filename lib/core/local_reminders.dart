import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/app_state.dart';
import 'push_service.dart';

/// Локальные напоминания утром и вечером (не путать с FCM-рассылками).
class LocalReminderService {
  LocalReminderService();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;
  void Function(String route)? onOpenRoute;

  static const _morningId = 1001;
  static const _eveningId = 1002;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) {
        final route = r.payload;
        if (route != null && route.startsWith('/')) onOpenRoute?.call(route);
      },
    );
    if (Platform.isAndroid) {
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
    _ready = true;
  }

  Future<void> sync(Session session) async {
    await init();
    await _plugin.cancel(id: _morningId);
    await _plugin.cancel(id: _eveningId);
    if (!session.pushEnabled) return;

    if (session.morningReminder) {
      await _scheduleDaily(
        id: _morningId,
        hour: session.morningHour,
        minute: session.morningMinute,
        title: 'Доброе утро',
        body: 'Начните день с молитвы и короткого чтения Писания',
        payload: '/pray/our_father',
      );
    }
    if (session.eveningReminder) {
      await _scheduleDaily(
        id: _eveningId,
        hour: session.eveningHour,
        minute: session.eveningMinute,
        title: 'Вечерний покой',
        body: 'Завершите день благодарностью и короткой молитвой',
        payload: '/review',
      );
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

    const android = AndroidNotificationDetails(
      'prayer_reminders',
      'Напоминания о молитве',
      channelDescription: 'Утренние и вечерние напоминания',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
    debugPrint('Reminder #$id scheduled at $hour:${minute.toString().padLeft(2, '0')}');
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancel(id: _morningId);
    await _plugin.cancel(id: _eveningId);
  }
}

final localReminderProvider = Provider<LocalReminderService>((ref) => LocalReminderService());

Future<void> rescheduleReminders({
  required Session session,
  required LocalReminderService reminders,
  required PushService push,
}) async {
  if (session.pushEnabled) {
    await reminders.sync(session);
    await push.init(session: session);
  } else {
    await reminders.cancelAll();
    await push.reset();
  }
}
