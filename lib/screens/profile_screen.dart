import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const ProfileScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 3),
                    ),
                    child: Icon(Icons.person_rounded, size: 50, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  const Text('Deen User', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  const Text('Bismillah - In the name of Allah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                ],
              ),
            ),

            // Settings List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildProfileItem(context, 'Settings', Icons.settings_rounded, () {}),
                  _buildProfileItem(context, 'Notifications', Icons.notifications_active_rounded, () {}),
                  _buildProfileItem(context, 'Location & Prayer Methods', Icons.location_on_rounded, () {}),
                  _buildProfileItem(context, 'Bookmarks', Icons.bookmark_rounded, () => onNavigate('bookmarks')),
                  _buildProfileItem(context, 'About Deen360', Icons.info_rounded, () {}),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.text, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.text)),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
