import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/hadith_repository.dart';

class HadithCollectionsScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const HadithCollectionsScreen({super.key, required this.onNavigate});

  @override
  State<HadithCollectionsScreen> createState() =>
      _HadithCollectionsScreenState();
}

class _HadithCollectionsScreenState extends State<HadithCollectionsScreen> {
  String _activeCategory = 'All';
  final _categories = ['All', 'Sahih', 'Sunan'];

  List<HadithCollection> get _filtered {
    if (_activeCategory == 'All') return HadithRepository.collections;
    return HadithRepository.collections
        .where((c) => c.title.contains(_activeCategory))
        .toList();
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: _filtered.length + 1,
          itemBuilder: (ctx, index) {
            if (index == 0) return _buildHeader();
            return _buildCollectionRow(_filtered[index - 1], index - 1);
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Nav
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => widget.onNavigate('home'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                    child: const Center(
                      child: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.text),
                    ),
                ),
              ),
              const Text(
                'Knowledge Hub',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.text,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.favorite_rounded, size: 20, color: Colors.black),
                ),
              ),
            ],
          ),
        ),

        // Hero
        Padding(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'WISDOM OF THE DAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '"The best among you are those who have the best manners and character."',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sahih Al-Bukhari',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.auto_awesome_rounded, size: 32, color: Colors.white),
              ],
            ),
          ),
        ),

        // Categories
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final active = _activeCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: active ? context.watch<ThemeProvider>().primaryColor : AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCollectionRow(HadithCollection col, int index) {
    final bgColor = _parseColor(col.color).withValues(alpha: 0.08);
    final darkColor = _parseColor(col.dark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          InkWell(
            onTap: () => widget.onNavigate('hadithChapters', {
              'id': col.id,
              'title': col.title,
              'author': col.author,
              'color': col.color,
              'dark': col.dark,
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:  Center(
                      child: Icon(Icons.collections_bookmark_rounded, size: 24, color: darkColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          col.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          col.author,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${col.title.split(" ")[0]} Verified',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: darkColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.inputBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1.5,
            margin: const EdgeInsets.only(left: 76),
            color: const Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }
}
