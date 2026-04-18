import 'package:flutter/material.dart';
import '../core/theme.dart';

class FlatListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget? rightElement;
  final VoidCallback? onPress;
  final bool hideDivider;

  const FlatListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.rightElement,
    this.onPress,
    this.hideDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          border: hideDivider
              ? null
              : const Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(margin: const EdgeInsets.only(right: AppSpacing.md), child: icon!),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rightElement != null) rightElement!,
          ],
        ),
      ),
    );
  }
}
