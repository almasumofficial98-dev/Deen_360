import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class Verse {
  final String id;
  final String ar;
  final String translation;
  final int? juz;
  final int surahNumber;
  final int ayahNumber;

  Verse({
    required this.id,
    required this.ar,
    required this.translation,
    this.juz,
    required this.surahNumber,
    required this.ayahNumber,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] as String? ?? '${json['surahNumber']}:${json['ayahNumber']}',
      ar: json['ar'] as String,
      translation: json['translation'] as String? ?? json['en'] as String? ?? '',
      juz: json['juz'] as int?,
      surahNumber: json['surahNumber'] as int? ?? 1,
      ayahNumber: json['ayahNumber'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ar': ar,
      'translation': translation,
      'juz': juz,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
    };
  }
}

class QuranRepository {
  static const String _alQuranBase = 'https://api.alquran.cloud/v1';
  static const String _quranEncBase = 'https://quranenc.com/api/v1';

  final Map<String, String> _langMap = {
    'en': 'english_saheeh',
    'ur': 'urdu_junagarhi',
    'hi': 'hindi_omari',
    'bn': 'bengali_zakaria',
    'te': 'english_saheeh', // Fallback as requested
  };

  final Map<String, String> _attributions = {
    'english_saheeh': 'Translation: Sahih International (QuranEnc.com)',
    'urdu_junagarhi': 'Translator: Maulana Muhammad Junagarhi (QuranEnc.com)',
    'hindi_omari': 'Translator: Maulana Azizul Haq Al-Omari (QuranEnc.com)',
    'bengali_zakaria': 'Translator: Dr. Abu Bakr Muhammad Zakaria (QuranEnc.com)',
  };

  String getAttribution(String langCode) {
    final key = _langMap[langCode] ?? 'english_saheeh';
    return _attributions[key] ?? 'Translation: QuranEnc.com';
  }

  Future<List<Map<String, dynamic>>> getSurahList() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/quran_offline/surah_list_v2.json';
    final file = File(path);

    // 1. Try local
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        return List<Map<String, dynamic>>.from(jsonDecode(content));
      } catch (_) {}
    }

    // 2. Fetch from network
    try {
      final res = await http.get(Uri.parse('https://api.quran.com/api/v4/chapters?language=en'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final chapters = data['chapters'] as List;
        final list = chapters.map((s) => {
          'number': s['id'],
          'englishName': s['name_simple'] ?? s['translated_name']?['name'] ?? 'Surah ${s["id"]}',
          'name': s['name_arabic'] ?? '',
          'revelationType': s['revelation_place'] ?? 'makkah',
          'versesCount': s['verses_count'] ?? 0,
        }).toList();
        
        // Save for offline
        final quranDir = Directory('${dir.path}/quran_offline');
        if (!await quranDir.exists()) await quranDir.create(recursive: true);
        await file.writeAsString(jsonEncode(list));
        
        return list;
      }
    } catch (_) {}

    return [];
  }

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

    // 2. Fetch from network
    return fetchAndSaveSurah(surahNumber, language: language);
  }

  Future<bool> isJuzDownloaded(int juzNumber, {String language = 'en'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/quran_offline/juz_${juzNumber}_$language.json';
    return File(path).exists();
  }

  Future<List<Verse>> loadJuz(int juzNumber, {String language = 'en'}) async {
    // 1. Try to load from local file
    try {
      final dir = await getApplicationDocumentsDirectory();
      final quranDir = Directory('${dir.path}/quran_offline');
      if (!await quranDir.exists()) {
        await quranDir.create(recursive: true);
      }
      final path = '${quranDir.path}/juz_${juzNumber}_$language.json';
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((e) => Verse.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading juz from file: $e');
    }

    // 2. Fetch from network
    return fetchAndSaveJuz(juzNumber, language: language);
  }

  Future<List<Verse>> fetchAndSaveJuz(int juzNumber, {String language = 'en'}) async {
    try {
      final transKey = _langMap[language] ?? 'english_saheeh';
      
      // 1. Fetch Arabic from AlQuran Cloud
      final arUrl = Uri.parse('$_alQuranBase/juz/$juzNumber/quran-uthmani');
      final arRes = await http.get(arUrl).timeout(const Duration(seconds: 25));
      if (arRes.statusCode != 200) return [];
      
      final arData = jsonDecode(arRes.body)['data'];
      final List arAyahs = arData['ayahs'];
      
      // 2. Identify unique surahs in this juz
      Set<int> surahSet = {};
      for (var a in arAyahs) {
        surahSet.add(a['surah']['number']);
      }
      
      // 3. Batch fetch translations for these surahs in parallel from QuranEnc
      Map<int, List<dynamic>> transBySurah = {};
      final List<Future<void>> transFutures = [];
      
      for (int sNum in surahSet) {
        transFutures.add(() async {
          try {
            final trUrl = Uri.parse('$_quranEncBase/translation/sura/$transKey/$sNum');
            final trRes = await http.get(trUrl).timeout(const Duration(seconds: 15));
            if (trRes.statusCode == 200) {
              transBySurah[sNum] = jsonDecode(trRes.body)['result'] as List;
            }
          } catch (e) {
            debugPrint('Failed to fetch translation for surah $sNum: $e');
          }
        }());
      }
      
      await Future.wait(transFutures);
      
      // 4. Merge
      List<Verse> results = [];
      for (var ar in arAyahs) {
        final sNum = ar['surah']['number'];
        final aNum = ar['numberInSurah'];
        
        String arText = ar['text'] ?? '';
        // Bismillah logic (preserved)
        if (aNum == 1 && sNum != 1 && sNum != 9) {
          arText = arText.replaceFirst(RegExp('^بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ?'), '');
          arText = arText.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ', '');
        }
        
        String translation = '';
        final surahTrans = transBySurah[sNum];
        if (surahTrans != null) {
          final match = surahTrans.firstWhere(
            (t) => (int.tryParse(t['aya']?.toString() ?? '') ?? -1) == aNum, 
            orElse: () => null
          );
          translation = match != null ? match['translation'] : '';
        }

        results.add(Verse(
          id: '$sNum:$aNum',
          ar: arText.trim(),
          translation: translation,
          juz: juzNumber,
          surahNumber: sNum,
          ayahNumber: aNum,
        ));
      }

      if (results.isNotEmpty) {
        final jsonStr = jsonEncode(results.map((v) => v.toJson()).toList());
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/quran_offline/juz_${juzNumber}_$language.json';
        await File(path).writeAsString(jsonStr);
        return results;
      }
    } catch (e) {
      debugPrint('Error fetchAndSaveJuz: $e');
    }
    return [];
  }

  Future<List<Verse>> fetchAndSaveSurah(int surahNumber, {String language = 'en'}) async {
    try {
      final transKey = _langMap[language] ?? 'english_saheeh';
      
      // 1. Fetch Arabic (AlQuran)
      final arUrl = Uri.parse('$_alQuranBase/surah/$surahNumber/quran-uthmani');
      final arRes = await http.get(arUrl).timeout(const Duration(seconds: 15));
      if (arRes.statusCode != 200) return [];
      final List arAyahs = jsonDecode(arRes.body)['data']['ayahs'];
      
      // 2. Fetch Translation (QuranEnc)
      final trUrl = Uri.parse('$_quranEncBase/translation/sura/$transKey/$surahNumber');
      final trRes = await http.get(trUrl).timeout(const Duration(seconds: 15));
      if (trRes.statusCode != 200) return [];
      final List trAyahs = jsonDecode(trRes.body)['result'];
      
      // 3. Merge
      List<Verse> results = [];
      for (int i = 0; i < arAyahs.length; i++) {
        final ar = arAyahs[i];
        final tr = i < trAyahs.length ? trAyahs[i] : null;
        
        String arText = ar['text'] ?? '';
        final aNum = ar['numberInSurah'];
        
        // Bismillah logic (preserved)
        if (surahNumber != 1 && surahNumber != 9 && i == 0) {
          arText = arText.replaceFirst(RegExp('^بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ?'), '');
          arText = arText.replaceFirst('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ', '');
          if (arText.startsWith('\ufeffبِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ')) {
            arText = arText.replaceFirst('\ufeffبِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ', '');
          } else if (arText.startsWith('\ufeff')) {
            arText = arText.replaceFirst('\ufeff', '');
          }
        }

        results.add(Verse(
          id: '$surahNumber:$aNum',
          ar: arText.trim(),
          translation: tr != null ? tr['translation'] : '',
          surahNumber: surahNumber,
          ayahNumber: aNum,
        ));
      }

      if (results.isNotEmpty) {
        final jsonStr = jsonEncode(results.map((v) => v.toJson()).toList());
        final path = await _getSurahPath(surahNumber, language);
        await File(path).writeAsString(jsonStr);
        return results;
      }
    } catch (e) {
      debugPrint('Error fetchAndSaveSurah: $e');
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
