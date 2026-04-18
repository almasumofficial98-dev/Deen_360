import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SalahStatus { none, alone, jamaat, missed, qaza }

class SalahEntry {
  final SalahStatus status;
  final int sunnahBefore;
  final int sunnahAfter;
  final int nafl;
  final int witr;

  SalahEntry({
    this.status = SalahStatus.none,
    this.sunnahBefore = 0,
    this.sunnahAfter = 0,
    this.nafl = 0,
    this.witr = 0,
  });

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'sunnahBefore': sunnahBefore,
    'sunnahAfter': sunnahAfter,
    'nafl': nafl,
    'witr': witr,
  };

  factory SalahEntry.fromJson(Map<String, dynamic> json) {
    // Migration Logic: handle old boolean fields
    int sb = json['sunnahBefore'] ?? 0;
    int sa = json['sunnahAfter'] ?? 0;
    int n = json['naflCount'] ?? (json['nafl'] is bool ? (json['nafl'] == true ? 2 : 0) : (json['nafl'] ?? 0));
    int w = json['witr'] ?? (json['wajib'] is bool ? (json['wajib'] == true ? 3 : 0) : (json['wajib'] ?? 0));
    
    // If old 'sunnah' (bool) exists and new counts are 0, migrate to 'sunnahBefore'
    if (json.containsKey('sunnah') && json['sunnah'] is bool && json['sunnah'] == true && sb == 0 && sa == 0) {
      sb = 2; // Default starting migration
    }

    return SalahEntry(
      status: SalahStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SalahStatus.none,
      ),
      sunnahBefore: sb,
      sunnahAfter: sa,
      nafl: n,
      witr: w,
    );
  }
}

class SalahTrackerProvider with ChangeNotifier {
  static const String _historyKey = 'deen360_salah_history_v2';
  static const String _installDateKey = 'deen360_install_date';

  Map<String, Map<String, SalahEntry>> _history = {};
  DateTime? _installDate;

  Map<String, Map<String, SalahEntry>> get history => _history;
  DateTime get installDate => _installDate ?? DateTime.now();

  SalahTrackerProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Install Date
    final savedInstallDate = prefs.getString(_installDateKey);
    if (savedInstallDate == null) {
      _installDate = DateTime.now();
      await prefs.setString(_installDateKey, _installDate!.toIso8601String());
    } else {
      _installDate = DateTime.parse(savedInstallDate);
    }

    // History
    final savedHistory = prefs.getString(_historyKey);
    if (savedHistory != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedHistory);
        _history = decoded.map((date, dayData) {
          final Map<String, dynamic> prayers = dayData;
          return MapEntry(
            date,
            prayers.map((name, data) => MapEntry(name, SalahEntry.fromJson(data))),
          );
        });
      } catch (e) {
        debugPrint('Error loading Salah history: $e');
      }
    }
    notifyListeners();
  }

  SalahEntry getEntry(DateTime date, String prayerName) {
    final dateKey = _dateToKey(date);
    return _history[dateKey]?[prayerName] ?? SalahEntry();
  }

  int getCompletedCount(DateTime date) {
    final dateKey = _dateToKey(date);
    final dayData = _history[dateKey];
    if (dayData == null) return 0;
    
    final corePrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    return dayData.entries
        .where((e) => corePrayers.contains(e.key) && (e.value.status == SalahStatus.alone || e.value.status == SalahStatus.jamaat || e.value.status == SalahStatus.qaza))
        .length;
  }

  Future<void> updateEntry(DateTime date, String prayerName, SalahEntry entry) async {
    final dateKey = _dateToKey(date);
    if (!_history.containsKey(dateKey)) {
      _history[dateKey] = {};
    }
    _history[dateKey]![prayerName] = entry;
    
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final toSave = _history.map((date, dayData) {
      return MapEntry(date, dayData.map((name, entry) => MapEntry(name, entry.toJson())));
    });
    await prefs.setString(_historyKey, jsonEncode(toSave));
  }

  String _dateToKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
