import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Verse {
  final String ayah;
  final String ar;
  final String en;

  Verse({
    required this.ayah,
    required this.ar,
    required this.en,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      ayah: json['ayah'] as String,
      ar: json['ar'] as String,
      en: json['en'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ayah': ayah,
      'ar': ar,
      'en': en,
    };
  }
}

class QuranRepository {
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  Future<List<Verse>> loadSurah(int surahNumber, {String language = 'en'}) async {
    final cacheKey = 'quran_surah_v2_${surahNumber}_$language';
    final prefs = await SharedPreferences.getInstance();

    // 1. Try to load from cache
    try {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        return jsonList.map((e) => Verse.fromJson(e)).toList();
      }
    } catch (e) {
      // Ignore cache error and proceed to network
    }

    // 2. Fetch from network
    try {
      List<Verse> allVerses = [];
      int currentPage = 1;
      int totalPages = 1;

      do {
        final url = Uri.parse(
            '$_baseUrl/verses/by_chapter/$surahNumber?language=$language&translations=20,131&fields=text_uthmani&per_page=100&page=$currentPage');
        
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final List<dynamic> versesJson = json['verses'] ?? [];

          final verses = versesJson.map((v) {
            String translationText = '';
            if (v['translations'] != null && (v['translations'] as List).isNotEmpty) {
              translationText = v['translations'][0]['text'] ?? '';
              // Remove HTML tags
              translationText = translationText.replaceAll(RegExp(r'<[^>]*>?'), '');
            }

            final arabic = v['text_uthmani'] ?? v['text_imlaei_simple'] ?? '';
            return Verse(
              ayah: v['verse_key'] ?? '$surahNumber:${v['verse_number']}',
              ar: arabic as String,
              en: translationText,
            );
          }).toList();

          allVerses.addAll(verses);
          totalPages = json['pagination']?['total_pages'] ?? 1;
          currentPage++;
        } else {
          throw Exception('Network error');
        }
      } while (currentPage <= totalPages);

      if (allVerses.isNotEmpty) {
        final jsonList = allVerses.map((v) => v.toJson()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
        return allVerses;
      }
    } catch (e) {
      debugPrint('Failed to fetch surah from network: $e');
      // Fall through to fallback
    }

    // 3. Offline fallback
    final fallback = {
      1: [
        Verse(
          ayah: '1:1',
          ar: 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ',
          en: 'In the name of Allah, the Most Gracious, the Most Merciful.',
        ),
        Verse(
          ayah: '1:2',
          ar: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
          en: 'All praise is due to Allah, Lord of all the worlds.',
        ),
      ],
    };

    final list = fallback[surahNumber] ?? [];
    try {
      final jsonList = list.map((v) => v.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
    } catch (e) {
      // Ignore
    }
    return list;
  }

  Future<void> clearQuranCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('quran_surah_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Ignore
    }
  }
}

