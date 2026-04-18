import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/hadith_repository.dart';

class HadithListScreen extends StatefulWidget {
  final Map<String, dynamic> collection;
  final Map<String, dynamic> chapter;
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const HadithListScreen({super.key, required this.collection, required this.chapter, required this.onNavigate});

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  List<HadithItem> _hadiths = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final repo = context.read<HadithRepository>();
    final data = await repo.loadHadiths(widget.collection['id'], widget.chapter['id']);
    if (mounted) setState(() { _hadiths = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final chapterTitle = widget.chapter['title'] ?? 'Hadiths';
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onNavigate('hadithChapters', widget.collection),
                    child: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('←', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))),
                  ),
                  Expanded(child: Text(chapterTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.text), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: _loading
                ? Center(child: CircularProgressIndicator(color: context.watch<ThemeProvider>().primaryColor))
                : _hadiths.isEmpty
                  ? const Center(child: Text('No Hadiths found', style: TextStyle(color: AppTheme.textLight, fontSize: 16)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: _hadiths.length,
                      itemBuilder: (ctx, i) => _buildHadithCard(_hadiths[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHadithCard(HadithItem h) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: context.watch<ThemeProvider>().primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text('#${h.id}', style: TextStyle(color: context.watch<ThemeProvider>().primaryColor, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              const Spacer(),
              if (h.grades.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: context.watch<ThemeProvider>().primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text(h.grades[0]['grade'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.watch<ThemeProvider>().primaryColor)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Arabic
          if (h.ar.isNotEmpty)
            Text(h.ar, style: const TextStyle(fontSize: 22, color: AppTheme.text, height: 2), textAlign: TextAlign.right),
          if (h.ar.isNotEmpty) const SizedBox(height: 16),

          // English
          Text(h.en, style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.7, fontWeight: FontWeight.w500)),

          const SizedBox(height: 24),
          Container(height: 1.5, color: const Color(0xFFF1F5F9)),
        ],
      ),
    );
  }
}
