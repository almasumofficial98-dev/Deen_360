import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
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
import 'reading_hub_screen.dart';
import 'more_hub_screen.dart';
import 'profile_screen.dart';
import 'salah_calendar_screen.dart';
import 'salah_guide_screen.dart';
import 'post_studio_screen.dart';

class _NavigationPoint {
  final String target;
  final Map<String, dynamic> params;
  _NavigationPoint(this.target, this.params);
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _activeTab = 'home';
  Map<String, dynamic> _params = {};
  final List<_NavigationPoint> _history = [];

  void _navigate(String target, [Map<String, dynamic>? payload]) {
    if (_activeTab == target &&
        _params.toString() == (payload ?? {}).toString())
      return;

    setState(() {
      // Save current to history
      _history.add(_NavigationPoint(_activeTab, _params));

      _params = payload ?? {};
      _activeTab = target;
    });
  }

  bool _pop() {
    // If we are in Post Studio, always go straight home as requested
    if (_activeTab == 'postStudio') {
      setState(() {
        _history.clear();
        _activeTab = 'home';
        _params = {};
      });
      return false;
    }

    if (_history.isNotEmpty) {
      setState(() {
        final prev = _history.removeLast();
        _activeTab = prev.target;
        _params = prev.params;
      });
      return false;
    }

    if (_activeTab != 'home') {
      setState(() {
        _activeTab = 'home';
        _params = {};
      });
      return false;
    }

    return true;
  }

  void _handleTabPress(String tabKey) {
    if (_activeTab == tabKey && _history.isEmpty) return;

    setState(() {
      // When clicking a tab, we clear history to treat it as a top-level jump
      _history.clear();
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
          initialAyah: _params['ayah'],
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
        return DuaListScreen(
          subCatId: _params['subCatId'] ?? '',
          onNavigate: _navigate,
        );
      case 'reading':
        return ReadingHubScreen(onNavigate: _navigate);
      case 'more':
        return MoreHubScreen(onNavigate: _navigate);
      case 'profile':
        return ProfileScreen(onNavigate: _navigate);
      case 'salah':
        return SalahScreen(onNavigate: _navigate);
      case 'qibla':
        return QiblaScreen(onNavigate: _navigate);
      case 'salahCalendar':
        return SalahCalendarScreen(onNavigate: _navigate);
      case 'salahGuide':
        return SalahGuideScreen(onNavigate: _navigate);
      case 'postStudio':
        return PostStudioScreen(
          onNavigate: _navigate,
          initialText: _params['text'],
          initialSource: _params['source'],
        );
      default:
        return HomeScreen(onNavigate: _navigate);
    }
  }

  bool _isTabActive(String tabKey) {
    if (_activeTab == tabKey) return true;
    if (tabKey == 'surahList' && (_activeTab == 'surahContent')) return true;
    if (tabKey == 'hadiths' &&
        (_activeTab == 'hadithChapters' || _activeTab == 'hadithList'))
      return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;

    final tabs = [
      {'key': 'home', 'label': 'Home', 'icon': Icons.home_rounded},
      {'key': 'more', 'label': 'More', 'icon': Icons.grid_view_rounded},
      {'key': 'duaCategories', 'label': 'Dua', 'icon': Icons.pan_tool_alt_rounded},
      {'key': 'reading', 'label': 'Reading', 'icon': Icons.auto_stories_rounded},
      {'key': 'profile', 'label': 'Profile', 'icon': Icons.person_rounded},
    ];

    double screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: _history.isEmpty && _activeTab == 'home',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _pop();
      },
      child: Scaffold(
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
                  key: ValueKey<String>(
                    _activeTab +
                        _params.entries.map((e) => e.value.toString()).join(),
                  ),
                  child: _renderScreen(),
                ),
              ),
            ),

            // Floating Bottom Navigation
            if (_activeTab.toLowerCase() != 'poststudio')
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
                    gradient: context.watch<ThemeProvider>().activeGradient,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppShadows.dynamicSoft(primaryColor),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isActive ? 14 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActive ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                t['icon'] as IconData,
                                size: 20,
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    t['label'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
