// lib/services/bus_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../models/departure_option.dart';

class _RawRun {
  final String routeId;
  final String routeName;
  final bool isWeekend;
  final List<Map<String, String>> stops; // {'name':..., 'time':...}
  _RawRun({required this.routeId, required this.routeName, required this.isWeekend, required this.stops});
}

class BusService {
  static final BusService _instance = BusService._internal();
  factory BusService() => _instance;
  BusService._internal();

  final List<_RawRun> _runs = [];
  bool _loaded = false;

  Future<void> loadFromAsset(String assetPath) async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(assetPath);
    final data = json.decode(raw) as List<dynamic>;
    for (final d in data) {
      final stopsRaw = (d['stops'] as List<dynamic>).map<Map<String,String>>((s) {
        final name = (s['name'] ?? '').toString();
        final time = (s['time'] ?? '').toString();
        return {'name': name, 'time': time};
      }).toList();
      _runs.add(_RawRun(
        routeId: d['routeId'] ?? '',
        routeName: d['routeName'] ?? (d['routeId'] ?? ''),
        isWeekend: (d['isWeekend'] == true),
        stops: stopsRaw,
      ));
    }
    _loaded = true;
  }

  DateTime? _parseTimeToToday(String timeStr) {
    if (timeStr.trim().isEmpty) return null;
    final now = DateTime.now();
    final s = timeStr.trim();
    try {
      final hm = RegExp(r'^(\d{1,2}):(\d{2})$');
      final ampm = RegExp(r'(\d{1,2}):(\d{2})\s*([aApP][mM])');
      if (hm.hasMatch(s) && !ampm.hasMatch(s)) {
        final m = hm.firstMatch(s)!;
        final hh = int.parse(m.group(1)!);
        final mm = int.parse(m.group(2)!);
        return DateTime(now.year, now.month, now.day, hh, mm);
      } else if (ampm.hasMatch(s)) {
        final m = ampm.firstMatch(s)!;
        var hh = int.parse(m.group(1)!);
        final mm = int.parse(m.group(2)!);
        final ampmStr = m.group(3)!.toLowerCase();
        if (ampmStr == 'pm' && hh < 12) hh += 12;
        if (ampmStr == 'am' && hh == 12) hh = 0;
        return DateTime(now.year, now.month, now.day, hh, mm);
      } else {
        final dt = DateFormat.jm().parseLoose(s);
        return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
      }
    } catch (e) {
      return null;
    }
  }

  int _findStopIndex(List<Map<String,String>> stops, String q) {
    final qlow = q.trim().toLowerCase();
    for (int i = 0; i < stops.length; i++) {
      final name = (stops[i]['name'] ?? '').toLowerCase();
      if (name.contains(qlow) || qlow.contains(name)) return i;
    }
    return -1;
  }

  Future<List<DepartureOption>> findDepartures(String fromStop, String toStop, {int maxResults = 50}) async {
    if (!_loaded) throw Exception("BusService not loaded. Call loadFromAsset first.");
    final now = DateTime.now();
    final isWeekendToday = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    List<DepartureOption> results = [];

    for (final run in _runs) {
      if (run.isWeekend != isWeekendToday) continue;
      final fromIdx = _findStopIndex(run.stops, fromStop);
      final toIdx = _findStopIndex(run.stops, toStop);
      if (fromIdx < 0 || toIdx < 0) continue;
      if (toIdx <= fromIdx) continue;

      final fromTimeStr = run.stops[fromIdx]['time'] ?? '';
      final toTimeStr   = run.stops[toIdx]['time'] ?? '';

      final dtFrom = _parseTimeToToday(fromTimeStr);
      final dtTo   = _parseTimeToToday(toTimeStr);
      if (dtFrom == null || dtTo == null) continue;
      
      // Allow showing past buses for demo/testing - comment out to filter only future buses
      // if (dtFrom.isBefore(now)) continue;

      results.add(DepartureOption(
        routeId: run.routeId,
        routeName: run.routeName,
        fromStop: run.stops[fromIdx]['name'] ?? fromStop,
        toStop: run.stops[toIdx]['name'] ?? toStop,
        departure: dtFrom,
        arrival: dtTo,
      ));
    }

    results.sort((a,b) => a.departure.compareTo(b.departure));
    if (results.length > maxResults) return results.sublist(0, maxResults);
    return results;
  }

  Future<List<DepartureOption>> findReturnOptions(DepartureOption outbound, {DateTime? cutoff}) async {
    if (!_loaded) throw Exception("BusService not loaded. Call loadFromAsset first.");
    final today = DateTime.now();
    final defaultCutoff = DateTime(today.year, today.month, today.day, 22, 30);
    cutoff ??= defaultCutoff;

    final candidates = await findDepartures(outbound.toStop, outbound.fromStop, maxResults: 200);
    final filtered = candidates.where((d) => d.arrival.isBefore(cutoff!) || d.arrival.isAtSameMomentAs(cutoff)).toList();
    filtered.sort((a,b) => a.departure.compareTo(b.departure));
    return filtered;
  }
}
