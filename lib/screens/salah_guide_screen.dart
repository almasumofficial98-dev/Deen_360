import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class SalahGuideScreen extends StatelessWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const SalahGuideScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final primaryColor = theme.primaryColor;
    final gradient = theme.activeGradient;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildZenHeader(context, gradient, primaryColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildIntro(gradient),
                const SizedBox(height: 32),
                _buildSection(
                  '1. HIGHEST PRIORITY: FARD',
                  'Established in Qur’an (4:103). Obligatory and central to our daily structure.',
                  Icons.anchor_rounded,
                  const Color(0xFF10B981),
                ),
                _buildStructureCard(),
                const SizedBox(height: 32),
                _buildSection(
                  '2. CONFIRMED SUNNAH',
                  'Authentic narrations from Sahih Muslim establish a daily house in Paradise for those who observe these 12 regular Rak‘ahs.',
                  Icons.auto_awesome_rounded,
                  Colors.amber,
                ),
                _buildSunnahList(),
                const SizedBox(height: 32),
                _buildSection(
                  '3. WITR: HIGHLY EMPHASIZED',
                  '“Make Witr your last prayer at night” — Sahih al-Bukhari. Consistently practiced but distinct from Fard.',
                  Icons.nights_stay_rounded,
                  Colors.indigo,
                ),
                const SizedBox(height: 32),
                _buildSection(
                  '4. OPTIONAL & NAFL',
                  'Flexible and open-ended based on authentic practices like the 4 Rak‘ahs before Asr.',
                  Icons.add_circle_outline_rounded,
                  Colors.purple,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZenHeader(
    BuildContext context,
    LinearGradient gradient,
    Color primary,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onNavigate('pop'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EVIDENCE-BASED',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily Salah Guide',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authentic Compliance',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Conceptually aligned with Qur’an & Sahih Hadith.',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String desc, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStructureCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _buildPrayerRow('Fajr', '2 Rak‘ahs'),
          _divider(),
          _buildPrayerRow('Dhuhr', '4 Rak‘ahs'),
          _divider(),
          _buildPrayerRow('Asr', '4 Rak‘ahs'),
          _divider(),
          _buildPrayerRow('Maghrib', '3 Rak‘ahs'),
          _divider(),
          _buildPrayerRow('Isha', '4 Rak‘ahs'),
        ],
      ),
    );
  }

  Widget _buildSunnahList() {
    final sunnahs = [
      {'t': 'Before Fajr', 'c': '2 Rak‘ahs (Very Strong)'},
      {'t': 'Before Dhuhr', 'c': '4 or 2 Rak‘ahs (Variable)'},
      {'t': 'After Dhuhr', 'c': '2 Rak‘ahs'},
      {'t': 'After Maghrib', 'c': '2 Rak‘ahs'},
      {'t': 'After Isha', 'c': '2 Rak‘ahs'},
    ];
    return Column(
      children: sunnahs
          .map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s['t']!,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    s['c']!,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPrayerRow(String p, String r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            p,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            r,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: const Color(0xFFF1F5F9),
  );
}
