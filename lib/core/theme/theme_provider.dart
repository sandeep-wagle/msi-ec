import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:msi_controller/services/persistence_service.dart';

@lazySingleton
class ThemeProvider extends ChangeNotifier {
  final PersistenceService _storage;

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider(this._storage) {
    final saved = _storage.loadThemeMode();
    _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _storage.saveThemeMode(mode.name);
      notifyListeners();
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}
