import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/animated_scale_button.dart';

// Screens
import 'home_screen.dart';
import 'surah_list_screen.dart';
import 'surah_screen.dart';
import 'hadith_collections_screen.dart';
import 'hadith_chapters_screen.dart';
import 'hadith_list_screen.dart';
import 'bookmarks_screen.dart';
import 'asma_screen.dart';
import 'dua_categories_screen.dart';
import 'dua_list_screen.dart';
import 'salah_screen.dart';
import 'qibla_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _activeTab = 'home';
  Map<String, dynamic> _params = {};

  void _navigate(String target, [Map<String, dynamic>? payload]) {
    setState(() {
      _params = payload ?? {};
      _activeTab = target;
    });
  }

  void _handleTabPress(String tabKey) {
    if (_activeTab == tabKey) return;
    setState(() {
      _activeTab = tabKey;
      _params = {};
    });
  }

  Widget _renderScreen() {
    switch (_activeTab) {
      case 'home':
        return HomeScreen(onNavigate: _navigate);
      case 'surahList':
        return SurahListScreen(onNavigate: _navigate);
      case 'surahContent':
        return SurahScreen(
          surahNumber: _params['number'] ?? 1,
          onNavigate: _navigate,
        );
      case 'hadiths':
        return HadithCollectionsScreen(onNavigate: _navigate);
      case 'hadithChapters':
        return HadithChaptersScreen(collection: _params, onNavigate: _navigate);
      case 'hadithList':
        return HadithListScreen(
          collection: _params['collection'] ?? {},
          chapter: _params['chapter'] ?? {},
          onNavigate: _navigate,
        );
      case 'bookmarks':
        return BookmarksScreen(onNavigate: _navigate);
      case 'asma':
        return AsmaScreen(onNavigate: _navigate);
      case 'duaCategories':
        return DuaCategoriesScreen(onNavigate: _navigate);
      case 'duaList':
        return DuaListScreen(subCatId: _params['subCatId'] ?? '', onNavigate: _navigate);
      case 'salah':
        return SalahScreen(onNavigate: _navigate);
      case 'qibla':
        return QiblaScreen(onNavigate: _navigate);
      default:
        return HomeScreen(onNavigate: _navigate);
    }
  }

  bool _isTabActive(String tabKey) {
    if (_activeTab == tabKey) return true;
    if (tabKey == 'surahList' && (_activeTab == 'surahContent')) return true;
    if (tabKey == 'hadiths' && (_activeTab == 'hadithChapters' || _activeTab == 'hadithList')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'key': 'home', 'label': 'Home', 'icon': Icons.home_rounded},
      {'key': 'surahList', 'label': 'Quran', 'icon': Icons.menu_book_rounded},
      {'key': 'hadiths', 'label': 'Hadith', 'icon': Icons.library_books_rounded},
      {'key': 'bookmarks', 'label': 'Saved', 'icon': Icons.bookmark_rounded},
    ];

    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Main Body
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: KeyedSubtree(
                key: ValueKey<String>(_activeTab),
                child: _renderScreen(),
              ),
            ),
          ),

          // Floating Bottom Navigation
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 72,
                width: screenWidth * 0.9,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AppTheme.border, width: 1),
                  boxShadow: AppShadows.floating,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: tabs.map((t) {
                    final isActive = _isTabActive(t['key'] as String);
                    return AnimatedScaleButton(
                      onPress: () => _handleTabPress(t['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: 48,
                        padding: EdgeInsets.symmetric(horizontal: isActive ? 20 : 12),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isActive ? AppShadows.soft : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              t['icon'] as IconData,
                              size: 20,
                              color: isActive ? Colors.white : Colors.black.withValues(alpha: 0.5),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 10),
                              Text(
                                t['label'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
