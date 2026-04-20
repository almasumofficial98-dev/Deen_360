import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class ReadingHubScreen extends StatelessWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const ReadingHubScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

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
                        Text('Reading Hub', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -1)),
                        const SizedBox(height: 4),
                        Text('Nourish your soul with wisdom', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.auto_stories_rounded, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildHubCard(
                    context,
                    title: 'Al-Quran',
                    subtitle: 'The Noble Word of Allah',
                    icon: Icons.menu_book_rounded,
                    gradient: theme.activeGradient,
                    onTap: () => onNavigate('quranHome'),
                    isHero: true,
                  ),
                  const SizedBox(height: 20),
                  _buildHubCard(
                    context,
                    title: 'Hadith Library',
                    subtitle: 'Prophetic Traditions & Wisdom',
                    icon: Icons.collections_bookmark_rounded,
                    onTap: () => onNavigate('hadiths'),
                    isHero: false,
                  ),
                  const SizedBox(height: 100), // Space for nav bar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Gradient? gradient,
    bool isHero = false,
  }) {
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isHero ? 190 : 160,
        decoration: BoxDecoration(
          color: gradient == null ? Colors.white : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isHero 
              ? AppShadows.dynamicFloating(primaryColor)
              : AppShadows.dynamicSoft(primaryColor),
          border: gradient == null ? Border.all(color: const Color(0xFFF1F5F9)) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              if (isHero)
                Positioned(
                  right: -20, bottom: -20,
                  child: Icon(icon, size: 150, color: Colors.white.withValues(alpha: 0.1)),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: isHero ? Colors.white.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: isHero ? Colors.white : primaryColor, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(title, 
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isHero ? Colors.white : AppTheme.text, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(subtitle, 
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isHero ? Colors.white.withValues(alpha: 0.8) : AppTheme.textLight)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
