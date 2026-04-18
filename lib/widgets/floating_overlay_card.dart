import 'package:flutter/material.dart';
import '../core/theme.dart';

class FloatingOverlayCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const FloatingOverlayCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.floating,
      ),
      child: child,
    );
  }
}
