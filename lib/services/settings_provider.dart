import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const _kThemeMode = 'settings_theme_mode';
  static const _kLanguage = 'settings_language';
  static const _kCurrency = 'settings_currency';

  ThemeMode _themeMode = ThemeMode.system; // Por defecto usa el del sistema
  String _language = 'Español';
  String _currency = 'Soles (S/)';

  SettingsProvider() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get currency => _currency;

  String get currencySymbol {
    switch (_currency) {
      case 'Dólares (\$)':
        return '\$';
      case 'Soles (S/)':
      default:
        return 'S/';
    }
  }

  String get themeName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return "Oscuro";
      case ThemeMode.light:
        return "Claro";
      case ThemeMode.system:
        return "Sistema";
    }
  }

  /// Formatea un monto con el símbolo de moneda seleccionado por el
  /// usuario en Ajustes, con separadores de miles.
  String formatAmount(double amount) {
    final formatted = NumberFormat("#,##0.00", "en_US").format(amount);
    return "$currencySymbol $formatted";
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_kThemeMode);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themeString,
        orElse: () => ThemeMode.system,
      );
    }
    _language = prefs.getString(_kLanguage) ?? _language;
    _currency = prefs.getString(_kCurrency) ?? _currency;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString(_kThemeMode, mode.name));
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString(_kLanguage, lang));
  }

  void setCurrency(String curr) {
    _currency = curr;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString(_kCurrency, curr));
  }
}
