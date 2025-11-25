// lib/pages/reminder_page.dart
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});
  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Reminder> reminders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    reminders = await ReminderService().getAll();
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text("Your Reminders")),
      body: reminders.isEmpty
        ? const Center(child: Text("No active reminders"))
        : ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (_, i) {
              final r = reminders[i];
              return ListTile(
                title: Text("${r.fromStop} → ${r.toStop}"),
                subtitle: Text("${r.departure.toLocal()}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await ReminderService().cancelReminder(r.id);
                    await _load();
                  },
                ),
              );
            },
          ),
    );
  }
}
