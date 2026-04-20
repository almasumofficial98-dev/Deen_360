import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class QuranHomeScreen extends StatelessWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const QuranHomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final primaryColor = theme.primaryColor;

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
                  GestureDetector(
                    onTap: () => onNavigate('pop'),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.text)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Al-Quran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5)),
                        Text('The Noble Revelation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildOptionCard(
                    context,
                    title: 'Read by Surah',
                    subtitle: '114 Deeply Moving Chapters',
                    description: 'Explore the Quran through its traditional chapter structure.',
                    icon: Icons.format_list_numbered,
                    gradient: theme.activeGradient,
                    onTap: () => onNavigate('surahList'),
                  ),
                  const SizedBox(height: 20),
                  _buildOptionCard(
                    context,
                    title: 'Read by Para',
                    subtitle: '30 Equal Jurisdictions (Juz)',
                    description: 'Structured for consistent daily reading and memorization.',
                    icon: Icons.grid_view_rounded,
                    onTap: () => onNavigate('juzList'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    final primaryColor = context.read<ThemeProvider>().primaryColor;
    final isHero = gradient != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isHero ? null : Colors.white,
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isHero 
            ? AppShadows.dynamicFloating(primaryColor)
            : AppShadows.dynamicSoft(primaryColor),
          border: !isHero ? Border.all(color: const Color(0xFFF1F5F9)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: isHero ? Colors.white.withOpacity(0.2) : primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: isHero ? Colors.white : primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isHero ? Colors.white : AppTheme.text)),
                      Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isHero ? Colors.white.withOpacity(0.7) : AppTheme.textLight, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isHero ? Colors.white.withOpacity(0.5) : AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 20),
            Text(description, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isHero ? Colors.white.withOpacity(0.9) : AppTheme.textLight, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
