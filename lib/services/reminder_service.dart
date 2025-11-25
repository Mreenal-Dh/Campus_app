// lib/services/reminder_service.dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import '../models/reminder.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const _prefsKey = 'campus_app_reminders';

  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tzData.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    // Initialize notification plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    _initialized = true;
  }

  Future<List<Reminder>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    
    try {
      final List<dynamic> decoded = json.decode(raw);
      return decoded.map((m) => Reminder.fromJson(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<Reminder> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> scheduleReminder(Reminder r) async {
    await init();

    final id = r.id.hashCode & 0x7fffffff;
    final scheduled = r.departure.subtract(Duration(minutes: r.minutesBefore));
    final tzDt = tz.TZDateTime.from(scheduled, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'campus_app_reminders',
      'Bus Reminders',
      channelDescription: 'Reminders for bus departures',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _notifications.zonedSchedule(
      id,
      'Bus Reminder — ${r.fromStop} → ${r.toStop}',
      '${r.routeId} departs at ${_formatTime(r.departure)} (in ${r.minutesBefore} min)',
      tzDt,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // Save to preferences
    final list = await getAll();
    final filtered = list.where((x) => x.id != r.id).toList();
    filtered.add(r);
    await _saveAll(filtered);
  }

  Future<void> cancelReminder(String id) async {
    final notifId = id.hashCode & 0x7fffffff;
    await _notifications.cancel(notifId);

    final list = await getAll();
    final filtered = list.where((r) => r.id != id).toList();
    await _saveAll(filtered);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
