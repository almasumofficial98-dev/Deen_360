import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/quran_download_provider.dart';
import 'package:provider/provider.dart';


class SurahInfo {
  final int number;
  final String englishName;
  final String name;
  final String revelationType;
  final int versesCount;

  SurahInfo({required this.number, required this.englishName, required this.name, required this.revelationType, required this.versesCount});
}

class SurahListScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const SurahListScreen({super.key, required this.onNavigate});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  List<SurahInfo> _list = [];
  List<SurahInfo> _filteredList = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadLastRead();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('https://api.quran.com/api/v4/chapters?language=en');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final chapters = (json['chapters'] as List?) ?? [];
        final surahs = chapters.map((s) => SurahInfo(
          number: s['id'],
          englishName: s['name_simple'] ?? s['translated_name']?['name'] ?? 'Surah ${s["id"]}',
          name: s['name_arabic'] ?? '',
          revelationType: s['revelation_place'] ?? 'makkah',
          versesCount: s['verses_count'] ?? 0,
        )).toList();
        if (mounted) setState(() { _list = surahs; _filteredList = surahs; _loading = false; });
      } else {
        _useFallback();
      }
    } catch (_) {
      _useFallback();
    }
  }

  void _useFallback() {
    final fallback = List.generate(114, (i) => SurahInfo(number: i + 1, englishName: 'Surah ${i + 1}', name: 'سورة ${i + 1}', versesCount: 0, revelationType: 'makkah'));
    if (mounted) setState(() { _list = fallback; _filteredList = fallback; _loading = false; });
  }

  Future<void> _loadLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('deen360_bookmarks');
      if (raw != null) {
        final bookmarks = jsonDecode(raw) as List;
        if (bookmarks.isNotEmpty) {
          if (mounted) setState(() => _lastRead = bookmarks.last as Map<String, dynamic>);
        }
      }
    } catch (_) {}
  }

  void _handleSearch(String text) {
    setState(() {
      _searchQuery = text;
      if (text.trim().isEmpty) {
        _filteredList = _list;
      } else {
        final lower = text.toLowerCase();
        _filteredList = _list.where((s) =>
          s.englishName.toLowerCase().contains(lower) ||
          s.name.toLowerCase().contains(lower) ||
          s.number.toString() == text
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavButton(icon: Icons.arrow_back_rounded, onTap: () => widget.onNavigate('home')),
                  const Text('Noble Quran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5)),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: _filteredList.length + 3, // +3 for hero, download card, and search
                    itemBuilder: (ctx, index) {
                      if (index == 0) return _buildHero();
                      if (index == 1) return _buildDownloadManager(context);
                      if (index == 2) return _buildSearchAndCount();
                      final surah = _filteredList[index - 3];
                      return _buildSurahRow(surah);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadManager(BuildContext context) {
    final downloader = context.watch<QuranDownloadProvider>();
    final theme = context.watch<ThemeProvider>();
    
    if (downloader.downloadedCount == 114 && !downloader.isDownloading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.cloud_download_rounded, color: theme.primaryColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        downloader.isDownloading ? 'Downloading Quran...' : 'Go Offline',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        downloader.isDownloading ? downloader.currentStatus : '${downloader.downloadedCount}/114 Surahs offline',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (!downloader.isDownloading)
                  GestureDetector(
                    onTap: () => downloader.downloadAll(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Download All', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                  )
                else
                  SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, value: downloader.progress, color: theme.primaryColor, backgroundColor: theme.primaryColor.withValues(alpha: 0.2)),
                  ),
              ],
            ),
            if (downloader.isDownloading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: downloader.progress,
                  minHeight: 6,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  color: theme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: context.watch<ThemeProvider>().activeGradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppShadows.dynamicFloating(context.watch<ThemeProvider>().primaryColor),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('LAST READ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  Text(_lastRead?['surahName'] ?? 'Al-Fatihah', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Ayah No: ${_lastRead?["ayah"] ?? 1}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => widget.onNavigate('surahContent', {'number': _lastRead?['surah'] ?? 1, 'ayah': _lastRead?['ayah'] ?? 1}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Text('Resume Reading', style: TextStyle(color: context.watch<ThemeProvider>().primaryColor, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 36)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndCount() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Text('⌕', style: TextStyle(fontSize: 20, color: Color(0xFF94A3B8))),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _handleSearch,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text),
                    decoration: const InputDecoration(
                      hintText: 'Search Surah name or number...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchController.clear(); _handleSearch(''); },
                    child: const Text('×', style: TextStyle(fontSize: 22, color: Color(0xFF94A3B8))),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('All Surahs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5)),
              Text('${_filteredList.length} Found', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.watch<ThemeProvider>().primaryColor, letterSpacing: 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurahRow(SurahInfo surah) {
    final downloader = context.watch<QuranDownloadProvider>();
    final isOffline = downloader.offlineSurahs.contains(surah.number);
    final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          InkWell(
            onTap: () => widget.onNavigate('surahContent', {'number': surah.number}),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text('${surah.number}', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 14))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(surah.englishName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.text, letterSpacing: -0.3)),
                            if (isOffline) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check_circle_rounded, size: 14, color: theme.primaryColor),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${surah.revelationType.toUpperCase()} • ${surah.versesCount} VERSES ${isOffline ? "• OFFLINE" : ""}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Text(surah.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: theme.primaryColor)),
                ],
              ),
            ),
          ),
          Container(height: 1.5, margin: const EdgeInsets.only(left: 60), color: const Color(0xFFF1F5F9)),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(22)),
        child: Center(child: Icon(icon, size: 22, color: context.watch<ThemeProvider>().primaryColor)),
      ),
    );
  }
}
