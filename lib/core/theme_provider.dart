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
    ThemePeriod newPeriod;
    
    switch (prayerName.toUpperCase()) {
      case 'FAJR':
      case 'SUNRISE':
        newPeriod = ThemePeriod.dawn;
        break;
      case 'DHUHR':
      case 'ASR':
        newPeriod = ThemePeriod.day;
        break;
      case 'MAGHRIB':
        newPeriod = ThemePeriod.sunset;
        break;
      case 'ISHA':
      case 'MIDNIGHT':
      case 'TAHAJJUD':
        newPeriod = ThemePeriod.night;
        break;
      default:
        newPeriod = ThemePeriod.day;
    }

    if (_period != newPeriod) {
      _period = newPeriod;
      _applyPeriod();
      notifyListeners();
    }
  }

  void _applyPeriod() {
    switch (_period) {
      case ThemePeriod.dawn:
        _primaryColor = const Color(0xFF0EA5E9);
        _activeGradient = AppGradients.dawn;
        break;
      case ThemePeriod.day:
        _primaryColor = const Color(0xFF10B981);
        _activeGradient = AppGradients.primary;
        break;
      case ThemePeriod.sunset:
        _primaryColor = const Color(0xFFF59E0B);
        _activeGradient = AppGradients.sunset;
        break;
      case ThemePeriod.night:
        _primaryColor = const Color(0xFF312E81);
        _activeGradient = AppGradients.night;
        break;
    }
  }
}
