import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

enum ThemePeriod { dawn, day, sunset, night }

class ThemeProvider extends ChangeNotifier {
  ThemePeriod _period = ThemePeriod.day;
  Color _primaryColor = AppTheme.primary;
  LinearGradient _activeGradient = AppGradients.primary;
  
  bool _isAutoMode = true;
  int? _manualColorValue;

  ThemeProvider() {
    _loadSettings();
  }

  ThemePeriod get period => _period;
  Color get primaryColor => _primaryColor;
  LinearGradient get activeGradient => _activeGradient;
  bool get isAutoMode => _isAutoMode;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isAutoMode = prefs.getBool('theme_auto_mode') ?? true;
    _manualColorValue = prefs.getInt('theme_manual_color');
    
    if (!_isAutoMode && _manualColorValue != null) {
      _applyManualColor(Color(_manualColorValue!));
    }
  }

  /// Update theme based on the current prayer block name from HomeScreen
  void updateFromPrayerBlock(String prayerName) {
    if (!_isAutoMode) return;
    _updateThemeData(prayerName.toUpperCase());
  }

  Future<void> setAutoMode(bool value) async {
    _isAutoMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_auto_mode', value);
    
    if (value) {
      notifyListeners();
    } else if (_manualColorValue != null) {
      _applyManualColor(Color(_manualColorValue!));
    } else {
      notifyListeners();
    }
  }

  Future<void> setManualColor(Color color) async {
    _isAutoMode = false;
    _manualColorValue = color.value;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_auto_mode', false);
    await prefs.setInt('theme_manual_color', color.value);
    
    _applyManualColor(color);
  }

  void _applyManualColor(Color color) {
    _primaryColor = color;
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
    
    _activeGradient = LinearGradient(
      colors: [color, darker],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    notifyListeners();
  }

  void _updateThemeData(String name) {
    LinearGradient newGradient;
    Color newPrimary;
    ThemePeriod newPeriod;

    switch (name) {
      case 'FAJR':
        newGradient = AppGradients.fajr;
        newPrimary = const Color(0xFF203A43);
        newPeriod = ThemePeriod.dawn;
        break;
      case 'SUNRISE':
        newGradient = AppGradients.sunrise;
        newPrimary = const Color(0xFFFF7E5F);
        newPeriod = ThemePeriod.dawn;
        break;
      case 'DHUHR':
        newGradient = AppGradients.dhuhr;
        newPrimary = const Color(0xFF2F80ED);
        newPeriod = ThemePeriod.day;
        break;
      case 'ASR':
        newGradient = AppGradients.asr;
        newPrimary = const Color(0xFFF2994A);
        newPeriod = ThemePeriod.day;
        break;
      case 'MAGHRIB':
        newGradient = AppGradients.maghrib;
        newPrimary = const Color(0xFFEE0979);
        newPeriod = ThemePeriod.sunset;
        break;
      case 'ISHA':
        newGradient = AppGradients.isha;
        newPrimary = const Color(0xFF243B55);
        newPeriod = ThemePeriod.night;
        break;
      case 'MIDNIGHT':
        newGradient = AppGradients.midnight;
        newPrimary = const Color(0xFF0F2027);
        newPeriod = ThemePeriod.night;
        break;
      case 'TAHAJJUD':
      case 'TAHAJJUD_VIGIL':
        newGradient = AppGradients.tahajjud;
        newPrimary = const Color(0xFF1A2980);
        newPeriod = ThemePeriod.night;
        break;
      default:
        newGradient = AppGradients.primary;
        newPrimary = AppTheme.primary;
        newPeriod = ThemePeriod.day;
    }

    if (_activeGradient != newGradient || _primaryColor != newPrimary) {
      _activeGradient = newGradient;
      _primaryColor = newPrimary;
      _period = newPeriod;
      notifyListeners();
    }
  }
}
