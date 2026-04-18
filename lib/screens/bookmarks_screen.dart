import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class BookmarksScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const BookmarksScreen({super.key, required this.onNavigate});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _quranBookmarks = [];
  List<Map<String, dynamic>> _hadithBookmarks = [];
  String _activeTab = 'quran';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final q = prefs.getString('deen360_bookmarks');
      final h = prefs.getString('deen360_bookmarks_hadith');
      if (q != null) _quranBookmarks = (jsonDecode(q) as List).cast<Map<String, dynamic>>().reversed.toList();
      if (h != null) _hadithBookmarks = (jsonDecode(h) as List).cast<Map<String, dynamic>>().reversed.toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteBookmark(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeTab == 'quran') {
        _quranBookmarks.removeAt(index);
        await prefs.setString('deen360_bookmarks', jsonEncode(_quranBookmarks.reversed.toList()));
      } else {
        _hadithBookmarks.removeAt(index);
        await prefs.setString('deen360_bookmarks_hadith', jsonEncode(_hadithBookmarks.reversed.toList()));
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _currentData => _activeTab == 'quran' ? _quranBookmarks : _hadithBookmarks;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => widget.onNavigate('home'),
                    child: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.text))),
                  ),
                  const Text('Saved Vault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5)),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 56,
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      bottom: 0,
                      left: _activeTab == 'quran' ? 0 : (screenWidth - 40) / 2,
                      child: Container(width: (screenWidth - 40) / 2, height: 3, decoration: BoxDecoration(color: context.watch<ThemeProvider>().primaryColor, borderRadius: BorderRadius.circular(3))),
                    ),
                    Row(
                      children: [
                        Expanded(child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 'quran'),
                          child: Center(child: Text('Quran', style: TextStyle(fontSize: 15, fontWeight: _activeTab == 'quran' ? FontWeight.w900 : FontWeight.w700, color: _activeTab == 'quran' ? context.watch<ThemeProvider>().primaryColor : const Color(0xFF94A3B8)))),
                        )),
                        Expanded(child: GestureDetector(
                          onTap: () => setState(() => _activeTab = 'hadith'),
                          child: Center(child: Text('Hadith', style: TextStyle(fontSize: 15, fontWeight: _activeTab == 'hadith' ? FontWeight.w900 : FontWeight.w700, color: _activeTab == 'hadith' ? context.watch<ThemeProvider>().primaryColor : const Color(0xFF94A3B8)))),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: _loading
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text('Opening Vault...', style: TextStyle(fontWeight: FontWeight.w700, color: context.watch<ThemeProvider>().primaryColor)),
                  ]))
                : _currentData.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: _currentData.length,
                      itemBuilder: (ctx, i) => _buildBookmarkRow(_currentData[i], i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(50)),
              child: Center(child: Icon(_activeTab == 'quran' ? Icons.menu_book_rounded : Icons.collections_bookmark_rounded, size: 48, color: context.watch<ThemeProvider>().primaryColor.withValues(alpha: 0.5))),
            ),
            const SizedBox(height: 24),
            const Text('Nothing Here Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.text)),
            const SizedBox(height: 12),
            Text(
              _activeTab == 'quran' ? 'Start building your collection by favoriting Ayahs from the Quran reader.' : 'Your favorite Hadiths will appear here once you bookmark them.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => widget.onNavigate(_activeTab == 'quran' ? 'surahList' : 'hadiths'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(color: context.watch<ThemeProvider>().primaryColor, borderRadius: BorderRadius.circular(100), boxShadow: AppShadows.dynamicFloating(context.watch<ThemeProvider>().primaryColor)),
                child: const Text('Go Explore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkRow(Map<String, dynamic> item, int index) {
    final isQuran = _activeTab == 'quran';
    String dateStr = '';
    try {
      final d = DateTime.parse(item['date']);
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      dateStr = '${months[d.month - 1]} ${d.day}';
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (isQuran) widget.onNavigate('surahContent', {'number': item['surah']});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: context.watch<ThemeProvider>().primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Icon(isQuran ? Icons.menu_book_rounded : Icons.description_rounded, size: 22, color: context.watch<ThemeProvider>().primaryColor)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isQuran ? (item['surahName'] ?? 'Surah ${item["surah"]}') : (item['collectionName'] ?? ''),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(isQuran ? 'Ayah ${item["ayah"]}' : 'Hadith ${item["id"]}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.watch<ThemeProvider>().primaryColor)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _deleteBookmark(index),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                          child: const Center(child: Icon(Icons.close_rounded, color: AppTheme.error, size: 18)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1.5, margin: const EdgeInsets.only(left: 68), color: const Color(0xFFF1F5F9)),
        ],
      ),
    );
  }
}
