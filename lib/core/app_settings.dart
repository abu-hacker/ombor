import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings I = AppSettings._();

  ThemeMode themeMode = ThemeMode.system;

  Future<void> load() async {
    final v = await SettingsRepository.I.get('theme');
    themeMode = switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await SettingsRepository.I.set(
        'theme',
        switch (m) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        });
  }
}
