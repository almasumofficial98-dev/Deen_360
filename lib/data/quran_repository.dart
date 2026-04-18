import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<String> _getSurahPath(int surahNumber, String language) async {
    final dir = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${dir.path}/quran_offline');
    if (!await quranDir.exists()) {
      await quranDir.create(recursive: true);
    }
    return '${quranDir.path}/surah_${surahNumber}_$language.json';
  }

  Future<bool> isSurahDownloaded(int surahNumber, {String language = 'en'}) async {
    final path = await _getSurahPath(surahNumber, language);
    return File(path).exists();
  }

  Future<List<Verse>> loadSurah(int surahNumber, {String language = 'en'}) async {
    // 1. Try to load from local file (Offline First)
    try {
      final path = await _getSurahPath(surahNumber, language);
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((e) => Verse.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading surah from file: $e');
    }

    // 2. Try to load from legacy SharedPreferences cache
    final cacheKey = 'quran_surah_v2_${surahNumber}_$language';
    final prefs = await SharedPreferences.getInstance();
    try {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        // Save to file for future use
        final path = await _getSurahPath(surahNumber, language);
        await File(path).writeAsString(cached);
        return jsonList.map((e) => Verse.fromJson(e)).toList();
      }
    } catch (e) {
      // Ignore cache error
    }

    // 3. Fetch from network
    return fetchAndSaveSurah(surahNumber, language: language);
  }

  Future<List<Verse>> fetchAndSaveSurah(int surahNumber, {String language = 'en'}) async {
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
        final jsonStr = jsonEncode(jsonList);
        
        // Save to file
        final path = await _getSurahPath(surahNumber, language);
        await File(path).writeAsString(jsonStr);
        
        // Also update legacy cache for safety
        final cacheKey = 'quran_surah_v2_${surahNumber}_$language';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonStr);
        
        return allVerses;
      }
    } catch (e) {
      debugPrint('Failed to fetch surah from network: $e');
    }

    return [];
  }

  Future<void> clearQuranCache() async {
    try {
      // Clear files
      final dir = await getApplicationDocumentsDirectory();
      final quranDir = Directory('${dir.path}/quran_offline');
      if (await quranDir.exists()) {
        await quranDir.delete(recursive: true);
      }

      // Clear prefs
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
