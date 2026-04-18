import 'package:flutter/material.dart';
import 'theme.dart';

enum ThemePeriod { dawn, day, sunset, night }

class ThemeProvider extends ChangeNotifier {
  ThemePeriod _period = ThemePeriod.day;
  Color _primaryColor = AppTheme.primary;
  LinearGradient _activeGradient = AppGradients.primary;

  ThemePeriod get period => _period;
  Color get primaryColor => _primaryColor;
  LinearGradient get activeGradient => _activeGradient;

  /// Update theme based on the current prayer block name from HomeScreen
  void updateFromPrayerBlock(String prayerName) {
    _updateThemeData(prayerName.toUpperCase());
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
