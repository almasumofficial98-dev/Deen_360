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
      final editionMap = {
        'en': 'en.sahih',
        'hi': 'hi.hindi',
        'bn': 'bn.bengali',
        'ur': 'ur.jalandhry'
      };
      final edition = editionMap[language] ?? 'en.sahih';
      
      final url = Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,$edition');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List?;
        
        if (data != null && data.length >= 2) {
          final arabicAyahs = data[0]['ayahs'] as List?;
          final translatedAyahs = data[1]['ayahs'] as List?;

          if (arabicAyahs != null && translatedAyahs != null) {
            List<Verse> allVerses = [];
            for (int i = 0; i < arabicAyahs.length; i++) {
              final arAyah = arabicAyahs[i];
              String arText = arAyah['text'] ?? '';
              
              // Remove the Bismillah from beginning of verse 1 for non-Fatiha, as we render Bismillah globally
              if (surahNumber != 1 && surahNumber != 9 && i == 0) {
                 arText = arText.replaceFirst(RegExp('^بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ?'), '');
                 // some variants use the special characters
                 arText = arText.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ', '');
                 // also replacing zero width no break space just in case
                 if (arText.startsWith('\ufeffبِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ')) {
                    arText = arText.replaceFirst('\ufeffبِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ', '');
                 } else if (arText.startsWith('\ufeff')) {
                    arText = arText.replaceFirst('\ufeff', '');
                 }
              }

              final trAyah = (i < translatedAyahs.length) ? translatedAyahs[i] : {};
              String enText = trAyah['text'] ?? '';
              
              allVerses.add(Verse(
                ayah: '$surahNumber:${arAyah['numberInSurah'] ?? (i + 1)}',
                ar: arText.trim(),
                en: enText,
              ));
            }

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
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch surah from network: $e');
    }

    // Fallback: If network fails or language fetch fails and language wasn't 'en', try fetching 'en' locally or via network
    if (language != 'en') {
        debugPrint('Falling back to English for $surahNumber');
        return loadSurah(surahNumber, language: 'en');
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
