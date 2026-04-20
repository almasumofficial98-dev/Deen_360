import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class MoreHubScreen extends StatelessWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const MoreHubScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {

    final gridItems = [
      {'title': 'Names of Allah', 'sub': '99 Attributes', 'icon': Icons.favorite_rounded, 'route': 'asma'},
      {'title': 'Salah', 'sub': 'Daily Timings', 'icon': Icons.calendar_today_rounded, 'route': 'salah'},
      {'title': 'Dua Library', 'sub': 'Hisnul Muslim', 'icon': Icons.pan_tool_alt_rounded, 'route': 'duaCategories'},
      {'title': 'Qibla', 'sub': 'Kaaba Direction', 'icon': Icons.explore_rounded, 'route': 'qibla'},
      {'title': 'Zakat & Wealth', 'sub': 'Authentic Tracker', 'icon': Icons.account_balance_wallet_rounded, 'route': 'zakat'},
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
                      children: [
                        Text('More Tools', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -1)),
                        const SizedBox(height: 4),
                        Text('Additional spiritual utilities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.grid_view_rounded, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  // Featured Tracker Card
                  _buildFeaturedCard(
                    context,
                    title: 'Salah Tracker',
                    subtitle: 'View records, history & daily log',
                    icon: Icons.show_chart_rounded,
                    onTap: () => onNavigate('salahCalendar'),
                  ),
                  const SizedBox(height: 24),
                  
                  // Grid of other tools
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: gridItems.length,
                    itemBuilder: (ctx, i) {
                      final item = gridItems[i];
                      return _buildGridItem(
                        context,
                        title: item['title'] as String,
                        subtitle: item['sub'] as String,
                        icon: item['icon'] as IconData,
                        onTap: () => onNavigate(item['route'] as String),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    final theme = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: theme.activeGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppShadows.dynamicFloating(theme.primaryColor),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, 
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, 
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    final primaryColor = context.watch<ThemeProvider>().primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: AppShadows.dynamicSoft(primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const Spacer(),
            Text(title, 
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(subtitle, 
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}
