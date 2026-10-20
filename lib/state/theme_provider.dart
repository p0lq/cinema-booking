import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService storage;
  bool _dark;

  ThemeProvider(this.storage) : _dark = storage.loadDarkTheme();

  bool get isDark => _dark;
  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _dark = !_dark;
    storage.saveDarkTheme(_dark);
    notifyListeners();
  }
}
