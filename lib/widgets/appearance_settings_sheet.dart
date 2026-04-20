import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class AppearanceSettingsSheet extends StatelessWidget {
  const AppearanceSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final primaryColor = theme.primaryColor;

    final List<Color> premiumColors = [
      AppTheme.primary, // Deen Emerald
      const Color(0xFF2563EB), // Royal Blue
      const Color(0xFF7C3AED), // Noble Purple
      const Color(0xFFDB2777), // Rose Gold
      const Color(0xFFD97706), // Amber Gold
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF0891B2), // Cyan Sea
      const Color(0xFF1E293B), // Slate Night
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          
          Text('App Appearance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Personalize your spiritual experience', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
          
          const SizedBox(height: 32),
          
          // Auto Mode Toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.inputBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Intelligent Themes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text)),
                      const SizedBox(height: 4),
                      Text('Match colors with prayer times', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: theme.isAutoMode,
                  activeColor: primaryColor,
                  onChanged: (val) => theme.setAutoMode(val),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Color Palette
          Text('Primary Palette', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.text, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: premiumColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final color = premiumColors[index];
                final isSelected = !theme.isAutoMode && theme.primaryColor.value == color.value;
                
                return GestureDetector(
                  onTap: () => theme.setManualColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.text : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                      : null,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
