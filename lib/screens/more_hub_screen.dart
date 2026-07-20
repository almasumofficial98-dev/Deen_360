import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../widgets/animated_scale_button.dart';

class MoreHubScreen extends StatelessWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const MoreHubScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final worshipTools = [
      {
        'title': 'Salah Timings',
        'sub': 'Daily Schedules',
        'icon': Icons.access_time_filled_rounded,
        'route': 'salah',
      },
      {
        'title': 'Salah Guide',
        'sub': 'Step-by-Step & Wudu',
        'icon': Icons.menu_book_rounded,
        'route': 'salahGuide',
      },
      {
        'title': 'Qibla Finder',
        'sub': 'Kaaba Direction',
        'icon': Icons.explore_rounded,
        'route': 'qibla',
      },
      {
        'title': 'Dua Library',
        'sub': 'Hisnul Muslim',
        'icon': Icons.pan_tool_alt_rounded,
        'route': 'duaCategories',
      },
    ];

    final knowledgeTools = [
      {
        'title': 'Names of Allah',
        'sub': '99 Attributes',
        'icon': Icons.favorite_rounded,
        'route': 'asma',
      },
      {
        'title': 'Al-Quran',
        'sub': 'Holy Surahs & Juz',
        'icon': Icons.auto_stories_rounded,
        'route': 'quranHome',
      },
      {
        'title': 'Hadith Library',
        'sub': 'Prophetic Wisdom',
        'icon': Icons.collections_bookmark_rounded,
        'route': 'hadiths',
      },
      {
        'title': 'Bookmarks',
        'sub': 'Saved Ayahs & Duas',
        'icon': Icons.bookmark_rounded,
        'route': 'bookmarks',
      },
    ];

    final utilityTools = [
      {
        'title': 'Post Studio',
        'sub': 'Create Quote Cards',
        'icon': Icons.palette_rounded,
        'route': 'postStudio',
      },
      {
        'title': 'Zakat Calculator',
        'sub': 'Wealth & Charity',
        'icon': Icons.account_balance_wallet_rounded,
        'route': 'zakat',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'More Tools',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Additional spiritual utilities',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.inputBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Featured Tracker Card
                  _buildFeaturedCard(
                    context,
                    title: 'Salah Tracker',
                    subtitle: 'View records, history & daily log',
                    icon: Icons.show_chart_rounded,
                    onTap: () => onNavigate('salahCalendar'),
                  ),
                  const SizedBox(height: 28),

                  // Section 1: Worship & Guidance
                  _buildSectionHeader('WORSHIP & PRAYER'),
                  const SizedBox(height: 14),
                  _buildToolGrid(context, worshipTools),
                  const SizedBox(height: 28),

                  // Section 2: Knowledge & Faith
                  _buildSectionHeader('KNOWLEDGE & FAITH'),
                  const SizedBox(height: 14),
                  _buildToolGrid(context, knowledgeTools),
                  const SizedBox(height: 28),

                  // Section 3: Utilities & Creative
                  _buildSectionHeader('CREATIVE & UTILITIES'),
                  const SizedBox(height: 14),
                  _buildToolGrid(context, utilityTools),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildToolGrid(
      BuildContext context, List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 116,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return _buildGridItem(
          context,
          title: item['title'] as String,
          subtitle: item['sub'] as String,
          icon: item['icon'] as IconData,
          onTap: () => onNavigate(item['route'] as String),
        );
      },
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = context.watch<ThemeProvider>();
    return AnimatedScaleButton(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: theme.activeGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.dynamicFloating(theme.primaryColor),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final primaryColor = context.watch<ThemeProvider>().primaryColor;
    return AnimatedScaleButton(
      onPress: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppShadows.dynamicSoft(primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: AppTheme.textMuted.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


