import 'dart:convert';
import 'package:http/http.dart' as http;

class HadithCollection {
  final String id;
  final String title;
  final String author;
  final String color;
  final String dark;

  const HadithCollection({
    required this.id,
    required this.title,
    required this.author,
    required this.color,
    required this.dark,
  });
}

class HadithChapter {
  final String id;
  final String title;

  HadithChapter({required this.id, required this.title});
}

class HadithItem {
  final int id;
  final String en;
  final String ar;
  final String book;
  final String chapterName;
  final List<dynamic> grades;

  HadithItem({
    required this.id,
    required this.en,
    required this.ar,
    required this.book,
    required this.chapterName,
    required this.grades,
  });
}

class HadithRepository {
  static const List<HadithCollection> collections = [
    HadithCollection(id: 'bukhari', title: 'Sahih al-Bukhari', author: 'Imam al-Bukhari', color: '#f0f9ff', dark: '#0284c7'),
    HadithCollection(id: 'muslim', title: 'Sahih Muslim', author: 'Imam Muslim', color: '#fdf4ff', dark: '#c026d3'),
    HadithCollection(id: 'abudawud', title: 'Sunan Abu Dawud', author: 'Abu Dawud', color: '#f0fdf4', dark: '#16a34a'),
    HadithCollection(id: 'tirmidhi', title: 'Jami at-Tirmidhi', author: 'Al-Tirmidhi', color: '#fffbeb', dark: '#d97706'),
    HadithCollection(id: 'nasai', title: 'Sunan an-Nasai', author: "Al-Nasa'i", color: '#fef2f2', dark: '#dc2626'),
    HadithCollection(id: 'ibnmajah', title: 'Sunan Ibn Majah', author: 'Ibn Majah', color: '#faf5ff', dark: '#9333ea'),
  ];

  Future<List<HadithChapter>> loadHadithChapters(String collectionId) async {
    try {
      final url = Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/info.json');
      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception('Failed fetch');
      
      final data = jsonDecode(response.body);
      final sections = data[collectionId]?['metadata']?['sections'] as Map<String, dynamic>? ?? {};
      
      final List<HadithChapter> chapters = [];
      sections.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          chapters.add(HadithChapter(id: key, title: value.toString()));
        }
      });
      
      chapters.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
      return chapters;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<HadithItem>> loadHadiths(String collectionId, String chapterId) async {
    try {
      final enUrl = Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-$collectionId/sections/$chapterId.json');
      final arUrl = Uri.parse('https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-$collectionId/sections/$chapterId.json');
      
      final responses = await Future.wait([
        http.get(enUrl),
        http.get(arUrl),
      ]);
      
      final enRes = responses[0];
      final arRes = responses[1];
      
      final enData = enRes.statusCode == 200 ? jsonDecode(enRes.body) : {'hadiths': []};
      final arData = arRes.statusCode == 200 ? jsonDecode(arRes.body) : {'hadiths': []};
      
      final List<dynamic> enHadithsList = enData['hadiths'] ?? [];
      final List<dynamic> arHadithsList = arData['hadiths'] ?? [];
      
      final Map<int, String> arMap = {};
      for (final h in arHadithsList) {
        if (h['hadithnumber'] != null) {
          arMap[h['hadithnumber'].toInt()] = h['text'] ?? '';
        }
      }
      
      final List<HadithItem> hadiths = [];
      
      for (int i = 0; i < enHadithsList.length; i++) {
        final h = enHadithsList[i];
        final text = h['text'];
        if (text == null || text.toString().trim().isEmpty) continue;
        
        final hadithNumber = h['hadithnumber']?.toInt() ?? i;
        
        List<dynamic> grds = [];
        if (h['grades'] != null && (h['grades'] as List).isNotEmpty) {
          grds = h['grades'];
        } else {
          if (collectionId == 'bukhari') {
             grds = [{'grade': 'Sahih', 'name': 'Al-Bukhari'}];
          } else if (collectionId == 'muslim') {
             grds = [{'grade': 'Sahih', 'name': 'Muslim'}];
          }
        }
        
        String bookName = enData['metadata']?['name'] ?? '';
        if (bookName.isEmpty) {
          final col = collections.where((c) => c.id == collectionId).toList();
          if (col.isNotEmpty) bookName = col.first.title;
        }
        
        final chapterName = enData['metadata']?['section']?[chapterId]?.toString() ?? '';
        
        hadiths.add(HadithItem(
          id: hadithNumber,
          en: text,
          ar: arMap[hadithNumber] ?? "",
          book: bookName,
          chapterName: chapterName,
          grades: grds,
        ));
      }
      
      return hadiths;
    } catch (e) {
      print(e);
      return [];
    }
  }
}
