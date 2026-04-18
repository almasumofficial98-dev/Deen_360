import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AsmaName {
  final String name;
  final String transliteration;
  final int number;
  final String meaning;

  AsmaName({
    required this.name,
    required this.transliteration,
    required this.number,
    required this.meaning,
  });

  factory AsmaName.fromJson(Map<String, dynamic> json) {
    return AsmaName(
      name: json['name'] ?? '',
      transliteration: json['transliteration'] ?? '',
      number: json['number'] ?? 0,
      meaning: json['en']?['meaning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'transliteration': transliteration,
      'number': number,
      'en': { 'meaning': meaning }
    };
  }
}

class AsmaRepository {
  static const String _cacheKey = 'deen360_asma_cache';

  Future<List<AsmaName>> loadAsmaUlHusna() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      
      if (cached != null) {
        // Fetch in background to update cache
        _fetchAsmaLive().catchError((_) => <AsmaName>[]);
        
        final List<dynamic> jsonList = jsonDecode(cached);
        return jsonList.map((e) => AsmaName.fromJson(e)).toList();
      }
      
      final liveData = await _fetchAsmaLive();
      if (liveData.isNotEmpty) return liveData;
      
    } catch (e) {
      print('Asma cache read error: $e');
    }
    
    // Fallback
    return _fallbackData.map((e) => AsmaName.fromJson(e)).toList();
  }

  Future<List<AsmaName>> _fetchAsmaLive() async {
    try {
      final url = Uri.parse('https://api.aladhan.com/v1/asmaAlHusna');
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['code'] == 200 && json['data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(json['data']));
          
          final List<dynamic> jsonList = json['data'];
          return jsonList.map((e) => AsmaName.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print('Aladhan fetch failed: $e');
    }
    return [];
  }

  static const List<Map<String, dynamic>> _fallbackData = [
    {
      "name": "الرَّحْمَنُ",
      "transliteration": "Ar Rahmaan",
      "number": 1,
      "en": { "meaning": "The Beneficent" }
    },
    {
      "name": "الرَّحِيمُ",
      "transliteration": "Ar Raheem",
      "number": 2,
      "en": { "meaning": "The Merciful" }
    }
    // Note: To keep file size manageable, rest are loaded via live fetch
  ];
}
