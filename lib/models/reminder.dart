// lib/models/reminder.dart
enum ReminderType { outbound, returnTrip }

class Reminder {
  final String id;
  final String fromStop;
  final String toStop;
  final DateTime departure;
  final String routeId;
  final ReminderType type;
  final int minutesBefore;

  Reminder({
    required this.id,
    required this.fromStop,
    required this.toStop,
    required this.departure,
    required this.routeId,
    required this.type,
    required this.minutesBefore,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromStop': fromStop,
      'toStop': toStop,
      'departure': departure.toIso8601String(),
      'routeId': routeId,
      'type': type.index,
      'minutesBefore': minutesBefore,
    };
  }

  static Reminder fromJson(Map<String, dynamic> j) {
    return Reminder(
      id: j['id'],
      fromStop: j['fromStop'],
      toStop: j['toStop'],
      departure: DateTime.parse(j['departure']).toLocal(),
      routeId: j['routeId'],
      type: ReminderType.values[j['type']],
      minutesBefore: j['minutesBefore'],
    );
  }
}
