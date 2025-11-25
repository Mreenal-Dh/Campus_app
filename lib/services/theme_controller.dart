import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeChoice { system, light, dark }

class ThemeController extends ChangeNotifier {
  static const _kPrefKey = 'app_theme_choice';
  AppThemeChoice _choice = AppThemeChoice.system;

  ThemeController() {
    _load();
  }

  AppThemeChoice get choice => _choice;

  ThemeMode get effectiveMode {
    switch (_choice) {
      case AppThemeChoice.light:
      return ThemeMode.light;

      case AppThemeChoice.dark:
      return ThemeMode.dark;

      case AppThemeChoice.system:
      return ThemeMode.system;
      }

  }

  Future<void> setChoice(AppThemeChoice newChoice) async {
    _choice = newChoice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefKey, newChoice.index);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_kPrefKey);
    if (raw != null && raw >= 0 && raw < AppThemeChoice.values.length) {
      _choice = AppThemeChoice.values[raw];
      notifyListeners();
    }
  }
}
