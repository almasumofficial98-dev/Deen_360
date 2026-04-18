import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/hadith_repository.dart';

class HadithChaptersScreen extends StatefulWidget {
  final Map<String, dynamic> collection;
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const HadithChaptersScreen({super.key, required this.collection, required this.onNavigate});

  @override
  State<HadithChaptersScreen> createState() => _HadithChaptersScreenState();
}

class _HadithChaptersScreenState extends State<HadithChaptersScreen> {
  List<HadithChapter> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    final repo = context.read<HadithRepository>();
    final chapters = await repo.loadHadithChapters(widget.collection['id']);
    if (mounted) setState(() { _chapters = chapters; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
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
                    onTap: () => widget.onNavigate('hadiths'),
                    child: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('←', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))),
                  ),
                  Expanded(child: Column(children: [
                    Text(widget.collection['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.text), textAlign: TextAlign.center),
                    Text('Chapters', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ])),
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
                    itemCount: _chapters.length,
                    itemBuilder: (ctx, i) {
                      final ch = _chapters[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => widget.onNavigate('hadithList', {'collection': widget.collection, 'chapter': {'id': ch.id, 'title': ch.title}}),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                                      child: Center(child: Text(ch.id, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 13))),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text(ch.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text))),
                                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                                  ],
                                ),
                              ),
                            ),
                            Container(height: 1, margin: const EdgeInsets.only(left: 60), color: const Color(0xFFF1F5F9)),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
