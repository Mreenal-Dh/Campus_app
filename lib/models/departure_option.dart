// lib/models/departure_option.dart
class DepartureOption {
  final String routeId;
  final String routeName;
  final String fromStop;
  final String toStop;
  final DateTime departure; // departure time at fromStop (local)
  final DateTime arrival; // arrival time at toStop (local)

  DepartureOption({
    required this.routeId,
    required this.routeName,
    required this.fromStop,
    required this.toStop,
    required this.departure,
    required this.arrival,
  });
}
