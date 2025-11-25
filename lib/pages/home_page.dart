// lib/pages/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/bus_service.dart';
import '../models/departure_option.dart';

import '../services/reminder_service.dart';
import '../models/reminder.dart';

// ---------------------------------------------------------
// HOME PAGE (Hybrid Version)
// ---------------------------------------------------------
class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToExplore;
  const HomePage({super.key, this.onNavigateToExplore});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool showResults = false;
  bool _loading = false;
  late String _timeString;

  final fromController = TextEditingController();
  final toController = TextEditingController();
  final PageController _explore = PageController(viewportFraction: 0.88);

  List<DepartureOption> _results = [];

  final accent = const Color(0xFFF25C54);

  @override
  void initState() {
    super.initState();
    _timeString = _formatTime(DateTime.now());

    Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _timeString = _formatTime(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _explore.dispose();
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  void _swap() {
    final t = fromController.text;
    fromController.text = toController.text;
    toController.text = t;
  }

  void resetToExplore() {
    if (showResults) {
      setState(() => showResults = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------
  // GPS
  // ---------------------------------------------------------
  Future<void> _gps() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _snack("Enable location services.");
        return;
      }

      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) {
          _snack("Location permission denied.");
          return;
        }
      }

      if (p == LocationPermission.deniedForever) {
        _snack("Enable GPS from settings.");
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        final place = marks.first;

        final addr =
            "${place.street ?? ""}, ${place.locality ?? ""}, ${place.subLocality ?? ""}"
                .replaceAll(", ,", ",")
                .replaceAll(",,", ",")
                .trim();

        setState(() => fromController.text = addr.isNotEmpty ? addr : "${pos.latitude}, ${pos.longitude}");
      } catch (_) {
        setState(() => fromController.text = "${pos.latitude}, ${pos.longitude}");
      }
    } catch (_) {
      _snack("Failed to get location.");
    }
  }

  // ---------------------------------------------------------
  // BUS SEARCH
  // ---------------------------------------------------------
  Future<void> _searchBus() async {
    final from = fromController.text.trim();
    final to = toController.text.trim();

    if (from.isEmpty || to.isEmpty) {
      _snack("Enter both From and To");
      return;
    }

    setState(() => _loading = true);

    try {
      final svc = BusService();
      await svc.loadFromAsset("assets/bus_data/routes.json");

      final found = await svc.findDepartures(from, to, maxResults: 50);

      setState(() {
        _results = found;
        showResults = true;
        _loading = false;
      });

      if (found.isEmpty) {
        _snack("No buses found between '$from' and '$to'. Try: HNLU → Railway Station");
      }
    } catch (e) {
      setState(() => _loading = false);
      _snack("Error searching buses: $e");
    }
  }

  // ---------------------------------------------------------
  // REMINDER LOGIC (HYBRID)
  // ---------------------------------------------------------

  /// Schedules outbound reminder → then prompts return selection
  Future<void> _setOutboundReminder(DepartureOption opt) async {
    final id = "${opt.routeId}|OUT|${opt.departure.toIso8601String()}";

    final reminder = Reminder(
      id: id,
      fromStop: opt.fromStop,
      toStop: opt.toStop,
      departure: opt.departure,
      routeId: opt.routeId,
      type: ReminderType.outbound,
      minutesBefore: 10,
    );

    await ReminderService().scheduleReminder(reminder);
    _snack("Reminder set (10 minutes before)");

    // then show return prompt
    await _promptReturnReminder(opt);
  }

  /// Show a bottom sheet asking: “Do you also want a return reminder?”
  Future<void> _promptReturnReminder(DepartureOption outbound) async {
    final svc = BusService();
    final returns = await svc.findReturnOptions(outbound);

    if (returns.isEmpty) {
      _snack("No return buses available before 10:30 PM.");
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Set Return Reminder?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              ...returns.map((r) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: const Icon(Icons.directions_bus),
                  title: Text("${_formatTime(r.departure)} → ${_formatTime(r.arrival)}"),
                  subtitle: Text("Bus ${r.routeId}"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _setReturnReminder(r);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setReturnReminder(DepartureOption opt) async {
    final id = "${opt.routeId}|RET|${opt.departure.toIso8601String()}";

    final reminder = Reminder(
      id: id,
      fromStop: opt.fromStop,
      toStop: opt.toStop,
      departure: opt.departure,
      routeId: opt.routeId,
      type: ReminderType.returnTrip,
      minutesBefore: 10,
    );

    await ReminderService().scheduleReminder(reminder);
    _snack("Return reminder set.");
  }

  // ---------------------------------------------------------
  // UI WIDGETS
  // ---------------------------------------------------------
  Widget _searchField({
    required TextEditingController controller,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F6F9);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _gpsButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F6F9);

    return GestureDetector(
      onTap: _gps,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.my_location,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }

  Widget _swapButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F6F9);

    return GestureDetector(
      onTap: _swap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.swap_vert,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // EXPLORE MODE UI
  // ---------------------------------------------------------
  Widget _buildExploreMode(double height) {
    final primary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      key: const ValueKey("explore"),
      children: [
        const SizedBox(height: 4),

        Text(
          _timeString,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _searchField(
                controller: fromController,
                hint: "From (Pickup)",
              ),
            ),
            const SizedBox(width: 10),
            _gpsButton(),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _searchField(
                controller: toController,
                hint: "To (Destination)",
              ),
            ),
            const SizedBox(width: 10),
            _swapButton(),
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _searchBus,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Find Bus",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Explore",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            GestureDetector(
              onTap: widget.onNavigateToExplore,
              child: Text(
                "See all",
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: height * 0.45,
          child: PageView.builder(
            controller: _explore,
            itemCount: 6,
            itemBuilder: (_, i) {
              final img = "assets/explore/explore$i.jpg";
              final titles = ["Cafes", "Parks", "Malls", "Temples", "Street Food", "Night Life"];
              final subtitles = ["Best cafes", "Green parks", "Malls", "Temples", "Local food", "Nightlife"];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey[300]),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 18,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[i % 6],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitles[i % 6],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // RESULTS MODE UI
  // ---------------------------------------------------------
  Widget _buildResultsMode(double availHeight) {
    final primary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Column(
      key: const ValueKey("results"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 400),
          alignment: Alignment.topLeft,
          child: Text(
            _timeString,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _searchField(
                controller: fromController,
                hint: "From",
              ),
            ),
            const SizedBox(width: 10),
            _swapButton(),
            const SizedBox(width: 10),
            Expanded(
              child: _searchField(
                controller: toController,
                hint: "To",
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Text(
          "Buses",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const Center(child: Text("No buses found."))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final opt = _results[i];

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  size: 34,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${opt.routeId} • ${opt.routeName}",
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Departs ${_formatTime(opt.departure)} • Arrives ${_formatTime(opt.arrival)}",
                                      style: TextStyle(color: Theme.of(context).hintColor),
                                    ),
                                  ],
                                ),
                              ),

                              Column(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _setOutboundReminder(opt),
                                    icon: const Icon(Icons.alarm_add),
                                    label: const Text("Remind"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final h = mq.size.height - mq.padding.top - mq.padding.bottom;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            child: showResults
                ? _buildResultsMode(h)
                : _buildExploreMode(h),
          ),
        ),
      ),
    );
  }
}
