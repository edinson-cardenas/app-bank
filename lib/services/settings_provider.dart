import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Por defecto usa el del sistema
  String _language = 'Español';
  String _currency = 'Soles (S/)';

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get currency => _currency;

  String get themeName {
    switch (_themeMode) {
      case ThemeMode.dark: return "Oscuro";
      case ThemeMode.light: return "Claro";
      case ThemeMode.system: return "Sistema";
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setCurrency(String curr) {
    _currency = curr;
    notifyListeners();
  }
}
